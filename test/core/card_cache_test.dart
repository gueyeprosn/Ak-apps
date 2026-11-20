import 'dart:io';
import 'dart:typed_data';

import 'package:ahloulkhidmah_mobile/core/storage/card_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late FileCardCache cache;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('card-cache-test');
    cache = FileCardCache(directory: Directory('${dir.path}/card'));
  });
  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  final image = CardImage(
    bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
    savedAt: DateTime.utc(2026, 11, 19, 10),
    etag: '"card-abc"',
  );

  test('aller-retour : octets, ETag et date conservés', () async {
    await cache.write('AK-1', image);
    final back = await cache.read('AK-1');
    expect(back!.bytes, image.bytes);
    expect(back.etag, '"card-abc"');
    expect(back.savedAt.toUtc(), image.savedAt);
  });

  test('jamais la carte d\'un autre membre (changement de compte sur l\'appareil)', () async {
    await cache.write('AK-1', image);
    expect(await cache.read('AK-2'), isNull);
  });

  test('rien d\'enregistré : null', () async {
    expect(await cache.read('AK-1'), isNull);
  });

  test('effacement complet : le dossier disparaît', () async {
    await cache.write('AK-1', image);
    await cache.clear();
    expect(await cache.read('AK-1'), isNull);
    expect(await Directory('${dir.path}/card').exists(), isFalse);
  });

  test('effacer quand il n\'y a rien ne plante pas', () async {
    await cache.clear();
    await cache.clear();
  });

  test('métadonnées corrompues : ignorées sans planter', () async {
    await cache.write('AK-1', image);
    await File('${dir.path}/card/card.json').writeAsString('{pas du json');
    expect(await cache.read('AK-1'), isNull);
  });

  test('image absente mais métadonnées présentes : ignoré', () async {
    await cache.write('AK-1', image);
    await File('${dir.path}/card/card.img').delete();
    expect(await cache.read('AK-1'), isNull);
  });

  test('un nouvel enregistrement remplace le précédent', () async {
    await cache.write('AK-1', image);
    await cache.write('AK-1', CardImage(bytes: Uint8List.fromList([9]), savedAt: DateTime.utc(2026, 11, 20), etag: '"card-new"'));
    expect((await cache.read('AK-1'))!.etag, '"card-new"');
  });
}
