import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Image de la carte membre et ce qu'il faut pour la revalider auprès du serveur.
class CardImage {
  const CardImage({required this.bytes, required this.savedAt, this.etag});
  final Uint8List bytes;
  final DateTime savedAt;
  final String? etag;
}

/// Copie locale de la carte, pour l'afficher **sans réseau** (présentation à un
/// événement). Elle contient des données personnelles : elle reste dans le
/// stockage privé de l'application et est **effacée à la déconnexion** et à
/// l'expiration de la session.
abstract class CardCache {
  Future<CardImage?> read(String memberId);
  Future<void> write(String memberId, CardImage image);
  Future<void> clear();
}

/// Fichier dans le dossier privé de l'application (`getApplicationSupportDirectory`).
class FileCardCache implements CardCache {
  FileCardCache({Directory? directory}) : _override = directory;
  final Directory? _override;

  /// Dossier du cache, **sans le créer** (la lecture et l'effacement ne doivent
  /// rien laisser derrière eux).
  Future<Directory> _dir() async =>
      _override ?? Directory('${(await getApplicationSupportDirectory()).path}/card');

  @override
  Future<CardImage?> read(String memberId) async {
    try {
      final dir = await _dir();
      final meta = File('${dir.path}/card.json');
      final img = File('${dir.path}/card.img');
      if (!await meta.exists() || !await img.exists()) return null;
      final m = jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
      // Jamais la carte d'un autre membre (changement de compte sur l'appareil).
      if (m['memberId'] != memberId) return null;
      return CardImage(
        bytes: await img.readAsBytes(),
        savedAt: DateTime.tryParse((m['savedAt'] ?? '') as String) ?? DateTime.fromMillisecondsSinceEpoch(0),
        etag: m['etag'] as String?,
      );
    } on Object {
      return null; // cache illisible : on l'ignore
    }
  }

  @override
  Future<void> write(String memberId, CardImage image) async {
    final dir = await _dir();
    if (!await dir.exists()) await dir.create(recursive: true);
    await File('${dir.path}/card.img').writeAsBytes(image.bytes, flush: true);
    await File('${dir.path}/card.json').writeAsString(
      jsonEncode({'memberId': memberId, 'etag': image.etag, 'savedAt': image.savedAt.toIso8601String()}),
      flush: true,
    );
  }

  @override
  Future<void> clear() async {
    try {
      final dir = await _dir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } on Object {
      // rien à effacer
    }
  }
}

/// Pour les tests.
class MemoryCardCache implements CardCache {
  String? memberId;
  CardImage? image;

  @override
  Future<CardImage?> read(String id) async => id == memberId ? image : null;

  @override
  Future<void> write(String id, CardImage value) async {
    memberId = id;
    image = value;
  }

  @override
  Future<void> clear() async {
    memberId = null;
    image = null;
  }
}

final cardCacheProvider = Provider<CardCache>((ref) => FileCardCache());
