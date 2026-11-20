import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_error.dart';
import '../../core/providers.dart';
import '../../core/storage/card_cache.dart';

/// Résultat d'une récupération de la carte.
class CardFetch {
  const CardFetch({this.image, this.notModified = false});
  final CardImage? image;
  final bool notModified;
}

/// `GET /api/mobile/v1/me/card` : la carte du membre connecté, générée par le
/// serveur. L'application l'affiche telle quelle (jamais recomposée).
class CardRepository {
  CardRepository(this._clients);
  final ApiClients _clients;

  /// [full] : PNG 1024×1536 d'origine (partage) ; sinon WebP 680×1020 (≈ 80 Ko).
  Future<CardFetch> fetch({String? etag, bool full = false}) => guardApi(() async {
        final res = await _clients.authed.get<List<int>>(
          '/api/mobile/v1/me/card',
          queryParameters: {'size': full ? 'full' : 'display'},
          options: Options(
            responseType: ResponseType.bytes,
            headers: {if (etag != null) 'If-None-Match': etag},
            validateStatus: (s) => s == 200 || s == 304,
          ),
        );
        if (res.statusCode == 304) return const CardFetch(notModified: true);
        final bytes = Uint8List.fromList(res.data ?? const <int>[]);
        if (bytes.isEmpty) {
          throw const ApiException(code: 'bad_response', message: 'Image vide');
        }
        return CardFetch(
          image: CardImage(bytes: bytes, savedAt: DateTime.now(), etag: res.headers.value('etag')),
        );
      });
}

/// Partage système de l'image (feuille de partage : WhatsApp, Enregistrer…).
abstract class CardSharer {
  Future<void> share(Uint8List png);
}

class SharePlusCardSharer implements CardSharer {
  const SharePlusCardSharer();

  @override
  Future<void> share(Uint8List png) async {
    // Fichier temporaire, effacé juste après : la carte contient des données personnelles.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/carte-membre.png');
    await file.writeAsBytes(png, flush: true);
    try {
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')]);
    } finally {
      if (await file.exists()) await file.delete();
    }
  }
}

final cardRepositoryProvider =
    Provider<CardRepository>((ref) => CardRepository(ref.watch(apiClientsProvider)));
final cardSharerProvider = Provider<CardSharer>((ref) => const SharePlusCardSharer());

enum CardStatus { loading, ready, unavailable, error }

class CardState {
  const CardState({
    this.status = CardStatus.loading,
    this.image,
    this.stale = false,
    this.refreshing = false,
    this.error,
    this.sharing = false,
    this.shareFailed = false,
  });

  final CardStatus status;
  final CardImage? image;

  /// `true` : affichée depuis la copie locale parce que le serveur est injoignable.
  final bool stale;
  final bool refreshing;
  final Object? error;
  final bool sharing;
  final bool shareFailed;

  CardState copyWith({
    CardStatus? status,
    CardImage? image,
    bool? stale,
    bool? refreshing,
    Object? error,
    bool clearError = false,
    bool? sharing,
    bool? shareFailed,
  }) =>
      CardState(
        status: status ?? this.status,
        image: image ?? this.image,
        stale: stale ?? this.stale,
        refreshing: refreshing ?? this.refreshing,
        error: clearError ? null : (error ?? this.error),
        sharing: sharing ?? this.sharing,
        shareFailed: shareFailed ?? this.shareFailed,
      );
}

class CardController extends AutoDisposeNotifier<CardState> {
  bool _disposed = false;

  @override
  CardState build() {
    ref.onDispose(() => _disposed = true);
    return const CardState();
  }

  void _set(CardState s) {
    if (!_disposed) state = s;
  }

  String? get _memberId {
    final auth = ref.read(authControllerProvider);
    return auth is AuthLoggedIn ? auth.member.id : null;
  }

  /// Affiche tout de suite la copie locale si elle existe, puis la revalide
  /// auprès du serveur (ETag : un 304 ne retélécharge rien).
  Future<void> load() async {
    final id = _memberId;
    if (id == null) return;
    final cache = ref.read(cardCacheProvider);
    final repo = ref.read(cardRepositoryProvider);

    final cached = await cache.read(id);
    if (cached != null) {
      _set(CardState(status: CardStatus.ready, image: cached, refreshing: true));
    } else {
      _set(const CardState());
    }

    try {
      final res = await repo.fetch(etag: cached?.etag);
      if (res.notModified && cached != null) {
        _set(CardState(status: CardStatus.ready, image: cached));
        return;
      }
      final fresh = res.image;
      if (fresh == null) {
        _set(const CardState(status: CardStatus.error));
        return;
      }
      await cache.write(id, fresh);
      _set(CardState(status: CardStatus.ready, image: fresh));
    } on ApiException catch (e) {
      if (e.code == 'card_unavailable') {
        // Plus de carte pour ce compte : on n'en garde pas de copie locale.
        await cache.clear();
        _set(CardState(status: CardStatus.unavailable, error: e));
      } else if (cached != null && (e.isNetwork || (e.status ?? 0) >= 500)) {
        _set(CardState(status: CardStatus.ready, image: cached, stale: true));
      } else {
        _set(CardState(status: CardStatus.error, error: e));
      }
    }
  }

  /// Partage la carte en pleine résolution (PNG d'origine).
  Future<void> share() async {
    if (state.sharing) return;
    _set(state.copyWith(sharing: true, shareFailed: false));
    try {
      final res = await ref.read(cardRepositoryProvider).fetch(full: true);
      final png = res.image?.bytes;
      if (png == null) throw const ApiException(code: 'bad_response', message: 'Image vide');
      await ref.read(cardSharerProvider).share(png);
      _set(state.copyWith(sharing: false));
    } on Object {
      _set(state.copyWith(sharing: false, shareFailed: true));
    }
  }
}

final cardControllerProvider =
    NotifierProvider.autoDispose<CardController, CardState>(CardController.new);
