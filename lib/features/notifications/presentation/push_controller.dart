import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app.dart' show effectiveLocale;
import '../../../core/providers.dart';
import '../data/device_repository.dart';
import '../domain/push_platform.dart';

enum PushStatus { unavailable, off, on, denied, working }

final pushPlatformProvider = Provider<PushPlatform>((ref) => const NoopPushPlatform());

final pushControllerProvider = NotifierProvider<PushController, PushStatus>(PushController.new);

class PushController extends Notifier<PushStatus> {
  static const _preference = 'pref.push';
  String? _token;
  StreamSubscription<String>? _refresh;
  Future<void> _queue = Future.value();
  bool _disposed = false;

  PushPlatform get _platform => ref.read(pushPlatformProvider);
  bool get _hasMember => ref.read(authControllerProvider) is AuthLoggedIn;
  String? get deviceToken => _token;
  bool get optedIn => ref.read(sharedPrefsProvider).getBool(_preference) == true;

  @override
  PushStatus build() {
    final platform = ref.read(pushPlatformProvider);
    if (!platform.isAvailable) return PushStatus.unavailable;
    ref.onDispose(() {
      _disposed = true;
      unawaited(_refresh?.cancel());
    });
    ref.listen(authControllerProvider, (previous, next) {
      if (next is AuthLoggedOut && (previous is AuthLoggedIn || optedIn)) {
        unawaited(disable());
      }
    });
    ref.listen(languagePrefProvider, (_, __) => unawaited(resume()));
    return PushStatus.off;
  }

  /// Les opérations réseau d'un appareil se terminent dans l'ordre des demandes.
  Future<bool> _run(Future<bool> Function() action) {
    final result = _queue.then((_) async => !_disposed && await action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<bool> enable() => _register(askPermission: true);
  Future<bool> resume() => ref.read(authControllerProvider) is AuthLoggedOut && optedIn
      ? disable()
      : _register(askPermission: false);

  Future<bool> _register({required bool askPermission}) => _run(() async {
        if (!_platform.isAvailable || !_hasMember || (!askPermission && !optedIn)) return false;
        state = PushStatus.working;
        try {
          final granted = await (askPermission ? _platform.requestPermission() : _platform.hasPermission());
          if (!granted) {
            state = PushStatus.denied;
            return false;
          }
          await _platform.setAutoInitEnabled(true);
          final token = await _platform.getToken();
          if (token == null || !_hasMember || _disposed) return false;
          _token = token;
          await _registerToken(token);
          if (!_hasMember || _disposed) return false;
          await ref.read(sharedPrefsProvider).setBool(_preference, true);
          _refresh ??= _platform.onTokenRefresh.listen(_refreshToken);
          state = PushStatus.on;
          return true;
        } catch (_) {
          return false;
        } finally {
          if (!_disposed && state == PushStatus.working) {
            if (!optedIn) {
              try {
                await _revoke();
              } catch (_) {}
            }
            if (!_disposed) state = PushStatus.off;
          }
        }
      });

  Future<void> _registerToken(String token) {
    final locale =
        effectiveLocale(ref.read(languagePrefProvider), PlatformDispatcher.instance.locale).languageCode;
    return ref.read(deviceRepositoryProvider).register(token, locale);
  }

  void _refreshToken(String token) {
    unawaited(_run(() async {
      if (!_hasMember || !optedIn) return false;
      final previous = _token;
      _token = token;
      try {
        await _registerToken(token);
        if (previous != null && previous != token) {
          await ref.read(deviceRepositoryProvider).remove(previous);
        }
        return true;
      } catch (_) {
        return false;
      }
    }));
  }

  Future<bool> disable() => _run(() async {
        if (!_platform.isAvailable) return true;
        state = PushStatus.working;
        try {
          final hadToken = optedIn || _token != null;
          await ref.read(sharedPrefsProvider).remove(_preference);
          if (!hadToken) return true;
          return await _revoke();
        } catch (_) {
          return false;
        } finally {
          if (!_disposed) state = PushStatus.off;
        }
      });

  Future<bool> _revoke() async {
    await _refresh?.cancel();
    _refresh = null;
    final platform = _platform;
    final repo = ref.read(deviceRepositoryProvider);
    final token = _token ?? await platform.getToken();
    var removed = false;
    try {
      if (token != null) {
        await repo.remove(token);
        removed = true;
      }
    } catch (_) {
      // La révocation auprès de Firebase reste possible si l'API est indisponible.
    }
    try {
      await platform.setAutoInitEnabled(false);
      await platform.deleteToken();
      removed = true;
    } catch (_) {
      // Garder le jeton en mémoire si les deux fournisseurs sont injoignables.
    }
    if (removed) _token = null;
    return removed;
  }
}
