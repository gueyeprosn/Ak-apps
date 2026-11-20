import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepository(ref.watch(apiClientsProvider), ref.watch(clientInfoProvider)),
);

class DeviceRepository {
  const DeviceRepository(this._clients, this._info);

  static const _path = '/api/mobile/v1/devices';
  final ApiClients _clients;
  final ClientInfo _info;

  Future<void> register(String token, String locale) => _clients.authed.post<void>(
        _path,
        data: {
          'token': token,
          'platform': _info.platform,
          'locale': locale,
          'appVersion': _info.appVersion,
        },
      );

  Future<void> remove(String token) => _clients.plain.delete<void>(_path, data: {'token': token});
}
