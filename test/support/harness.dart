import 'package:ahloulkhidmah_mobile/core/api/api_client.dart';
import 'package:ahloulkhidmah_mobile/core/auth/token_store.dart';
import 'package:ahloulkhidmah_mobile/core/config/env.dart';

import 'fake_adapter.dart';

const testEnv = AppEnv(name: 'test', apiBaseUrl: 'http://fake.test', allowInsecureHttp: true);
const testInfo = ClientInfo(platform: 'android', appVersion: '1.0.0');

({ApiClients clients, MemoryTokenStore store, SessionEvents events, FakeAdapter adapter}) buildClients(
  Map<String, FakeHandler> routes, {
  AuthTokens? tokens,
}) {
  final store = MemoryTokenStore(tokens);
  final events = SessionEvents();
  final adapter = FakeAdapter(routes);
  final clients = createApiClients(
    env: testEnv,
    store: store,
    events: events,
    info: testInfo,
    adapter: adapter,
  );
  return (clients: clients, store: store, events: events, adapter: adapter);
}
