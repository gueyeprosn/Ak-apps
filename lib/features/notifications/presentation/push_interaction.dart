import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../app/router/app_router.dart';
import '../../../core/animations/ak_motion.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import 'push_controller.dart';
import '../domain/push_models.dart';

/// Clé du `ScaffoldMessenger` racine : sert à afficher une bannière quand une
/// notification arrive application ouverte (Android n'affiche alors rien).
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Réagit aux notifications : tap application fermée (`getInitialMessage`),
/// en arrière-plan (`onMessageOpenedApp`), et bannière au premier plan.
class PushInteraction extends ConsumerStatefulWidget {
  const PushInteraction({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<PushInteraction> createState() => _PushInteractionState();
}

class _PushInteractionState extends ConsumerState<PushInteraction>
    with WidgetsBindingObserver {
  final _subs = <StreamSubscription<PushMessage>>[];
  String? _pendingRoute;

  @override
  void initState() {
    super.initState();
    final platform = ref.read(pushPlatformProvider);
    if (!platform.isAvailable) return;
    WidgetsBinding.instance.addObserver(this);
    _subs
      ..add(platform.onOpened.listen((m) => _open(m.route)))
      ..add(platform.onForeground.listen(_banner));
    unawaited(_start());
  }

  Future<void> _start() async {
    final platform = ref.read(pushPlatformProvider);
    try {
      final initial = await platform.initialMessage();
      if (mounted) _open(initial?.route);
    } catch (_) {
      // Une panne du plugin ne bloque pas le démarrage.
    }
  }

  /// Le routeur n'est pas prêt avant la fin du démarrage (`/splash`) : une
  /// destination demandée trop tôt serait écrasée. On la garde en attente.
  void _open(String? route) {
    final safe = safePushRoute(route);
    if (safe == null) return;
    _pendingRoute = safe;
    _flush();
  }

  void _flush() {
    final route = _pendingRoute;
    if (route == null || !ref.read(bootstrapProvider).hasValue) return;
    _pendingRoute = null;
    if (ref.read(authControllerProvider) is! AuthLoggedIn ||
        !ref.read(pushControllerProvider.notifier).optedIn) return;
    final tabs = ref.read(configProvider).value?.config.visibleTabs;
    if (route.startsWith('/t/') &&
        !(tabs?.any((tab) => '/t/${tab.id}' == route) ?? false)) return;
    ref.read(routerProvider).go(route);
  }

  void _banner(PushMessage m) {
    if (ref.read(pushControllerProvider) != PushStatus.on ||
        ref.read(authControllerProvider) is! AuthLoggedIn) return;
    final messenger = rootMessengerKey.currentState;
    if (messenger == null || (m.title == null && m.body == null)) return;
    final l = AppLocalizations.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        snackBarAnimationStyle: AnimationStyle(
          duration: AKMotion.duration(context, AKMotion.pageIn),
          reverseDuration: AKMotion.duration(context, AKMotion.pageOut),
        ),
        SnackBar(
          content: Text([m.title, m.body].whereType<String>().join(' — ')),
          action: m.route == null
              ? null
              : SnackBarAction(
                  label: l.pushOpen, onPressed: () => _open(m.route)),
        ),
      );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(pushControllerProvider.notifier).resume());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(pushPlatformProvider).isAvailable) {
      ref.listen(bootstrapProvider, (previous, next) {
        if (!next.hasValue || previous?.hasValue == true) return;
        _flush();
        unawaited(ref.read(pushControllerProvider.notifier).resume());
      });
    }
    return widget.child;
  }
}
