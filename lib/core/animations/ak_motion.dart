import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

abstract final class AKMotion {
  static const press = Duration(milliseconds: 120);
  static const pageIn = Duration(milliseconds: 260);
  static const pageOut = Duration(milliseconds: 180);
  static const reveal = Duration(milliseconds: 330);
  static const pressedScale = .97;
  static const ease = Curves.easeOutCubic;

  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

/// Animation finie. L'enfant reste accessible et conserve sa taille.
class AkReveal extends StatelessWidget {
  const AkReveal(
      {super.key,
      required this.child,
      this.stage = 0,
      this.slide = true,
      this.stagger = false});

  final Widget child;
  final int stage;
  final bool slide;
  final bool stagger;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = 65 * stage;
    final duration = AKMotion.reveal + Duration(milliseconds: delay);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: stagger
          ? Interval(delay / duration.inMilliseconds, 1, curve: AKMotion.ease)
          : AKMotion.ease,
      child: child,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, slide ? 12 * (1 - progress) : 0),
          child: child,
        ),
      ),
    );
  }
}

/// L'état de pression vient du bouton Material, avec clavier et focus natifs.
class AkAnimatedButton extends StatefulWidget {
  const AkAnimatedButton({super.key, required this.builder});

  final Widget Function(WidgetStatesController controller) builder;

  @override
  State<AkAnimatedButton> createState() => _AkAnimatedButtonState();
}

class _AkAnimatedButtonState extends State<AkAnimatedButton> {
  final _states = WidgetStatesController();

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(_syncPressed);
  }

  void _syncPressed() {
    void update() {
      if (!mounted) return;
      final pressed = _states.value.contains(WidgetState.pressed);
      if (pressed != _pressed) setState(() => _pressed = pressed);
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => update());
    } else {
      update();
    }
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = AKMotion.duration(context, AKMotion.press);
    return AnimatedScale(
      scale: duration != Duration.zero && _pressed ? AKMotion.pressedScale : 1,
      duration: duration,
      curve: AKMotion.ease,
      child: widget.builder(_states),
    );
  }
}

/// Transition des routes secondaires. Le mouvement est vertical en FR et AR.
class AkPageTransition<T> extends CustomTransitionPage<T> {
  AkPageTransition({
    required BuildContext context,
    required LocalKey pageKey,
    required Widget child,
  }) : super(
          key: pageKey,
          child: child,
          transitionDuration: AKMotion.duration(context, AKMotion.pageIn),
          reverseTransitionDuration:
              AKMotion.duration(context, AKMotion.pageOut),
          transitionsBuilder: _build,
        );

  static Widget _build(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final progress = animation.drive(CurveTween(curve: AKMotion.ease));
    return FadeTransition(
      opacity: progress,
      child: SlideTransition(
        position: progress
            .drive(Tween(begin: const Offset(0, .025), end: Offset.zero)),
        child: child,
      ),
    );
  }
}

Future<T?> showAkBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) =>
    showModalBottomSheet<T>(
      context: context,
      builder: builder,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: AnimationStyle(
        duration: AKMotion.duration(context, AKMotion.pageIn),
        reverseDuration: AKMotion.duration(context, AKMotion.pageOut),
      ),
    );
