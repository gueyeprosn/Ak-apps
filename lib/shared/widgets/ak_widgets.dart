import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';

const akPagePadding = EdgeInsets.fromLTRB(
  AkSpace.space4,
  AkSpace.space4,
  AkSpace.space4,
  AkSpace.space6,
);

/// Hiérarchie commune aux en-têtes de page et aux étapes de formulaire.
class AkHeading extends StatelessWidget {
  const AkHeading(
      {super.key,
      required this.title,
      this.subtitle,
      this.icon,
      this.section = false});

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool section;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: p.surfaceTint,
                borderRadius: BorderRadius.circular(AkRadius.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AkSpace.space3),
                child: Icon(icon, color: p.primary),
              ),
            ),
          ),
          const SizedBox(height: AkSpace.space3),
        ],
        Semantics(
            header: true,
            child:
                Text(title, style: section ? AkText.title : AkText.headline)),
        if (subtitle != null) ...[
          const SizedBox(height: AkSpace.space2),
          Text(subtitle!, style: AkText.body.copyWith(color: p.inkSoft)),
        ],
      ],
    );
  }
}

enum AkButtonKind { primary, gold, outline, text }

/// Bouton de la charte : 48 dp minimum, une seule variante `primary` par écran.
class AkButton extends StatelessWidget {
  const AkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AkButtonKind.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AkButtonKind kind;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    final enabled = onPressed != null && !loading;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        kind == AkButtonKind.gold ? AkRadius.radiusPill : AkRadius.radiusMd,
      ),
    );
    final size = Size(expand ? double.infinity : 0, AkSize.sizeTouch);

    Color bg, fg;
    BorderSide side = BorderSide.none;
    switch (kind) {
      case AkButtonKind.primary:
        bg = p.primary;
        fg = p.onPrimary;
      case AkButtonKind.gold:
        bg = p.gold;
        fg = p.onGold;
      case AkButtonKind.outline:
        bg = Colors.transparent;
        fg = p.primary;
        side = BorderSide(color: p.borderControl, width: 2);
      case AkButtonKind.text:
        bg = Colors.transparent;
        fg = p.link;
    }
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(size),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(
        horizontal: AkSpace.space4,
        vertical: AkSpace.space2,
      )),
      shape: WidgetStatePropertyAll(shape),
      textStyle: WidgetStatePropertyAll(AkText.button),
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.disabled) && !loading ? p.surfaceSunken : bg,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) && !loading ? p.inkSoft : fg,
      ),
      side: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) && !loading
            ? BorderSide(color: p.border)
            : side,
      ),
      elevation: const WidgetStatePropertyAll(0),
      animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : kThemeAnimationDuration,
      overlayColor: WidgetStatePropertyAll(fg.withValues(alpha: 0.12)),
    );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 3, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: AkSize.sizeIcon),
        if (loading || icon != null) const SizedBox(width: AkSpace.space2),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    return Semantics(
      liveRegion: loading,
      child: AkAnimatedButton(
        builder: (controller) => TextButton(
          statesController: controller,
          onPressed: enabled ? onPressed : null,
          style: style,
          child: child,
        ),
      ),
    );
  }
}

class AkPrimaryButton extends AkButton {
  const AkPrimaryButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.loading,
    super.expand,
  });
}

class AkSecondaryButton extends AkButton {
  const AkSecondaryButton({
    super.key,
    required super.label,
    required super.onPressed,
    super.icon,
    super.loading,
    super.expand,
  }) : super(kind: AkButtonKind.outline);
}

class AkIconButton extends StatelessWidget {
  const AkIconButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => AkAnimatedButton(
        builder: (controller) => IconButton(
          statesController: controller,
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon),
          constraints: const BoxConstraints(
              minWidth: AkSize.sizeTouch, minHeight: AkSize.sizeTouch),
        ),
      );
}

/// Champ de saisie : libellé au-dessus, bordure `border-control` (≥ 3:1),
/// erreur = bordure + icône + texte (jamais la couleur seule).
class AkTextField extends StatelessWidget {
  const AkTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.prefixText,
    this.keyboardType,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.textDirection = TextDirection.ltr,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.fieldKey,
    this.maxLength,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? prefixText;
  final TextInputType? keyboardType;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final Key? fieldKey;
  final int? maxLength;

  /// Plusieurs lignes (message libre) : 1 par défaut.
  final int maxLines;

  /// Un numéro de téléphone reste en chiffres latins, de gauche à droite.
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AkRadius.radiusMd),
          borderSide: BorderSide(color: c, width: w),
        );
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AkText.label),
        const SizedBox(height: AkSpace.space1),
        // Le champ entier suit [textDirection] : le préfixe « +221 » reste collé aux chiffres.
        Semantics(
          label: label,
          child: Directionality(
            textDirection: textDirection,
            child: TextField(
              key: fieldKey,
              controller: controller,
              maxLength: maxLength,
              maxLines: maxLines,
              minLines: maxLines > 1 ? 3 : 1,
              inputFormatters: inputFormatters,
              textCapitalization: textCapitalization,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              autofillHints: autofillHints,
              textDirection: textDirection,
              style: AkText.body,
              decoration: InputDecoration(
                counterText: '',
                hintText: hint,
                hintStyle: AkText.body.copyWith(color: p.inkSoft),
                // prefixIcon (et non prefixText) : toujours affiché, même champ vide.
                prefixIcon: prefixText == null
                    ? null
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: AkSpace.space4, end: AkSpace.space2),
                        child: Text(prefixText!,
                            style: AkText.body.copyWith(color: p.inkSoft)),
                      ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                filled: true,
                fillColor: p.surfaceRaised,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AkSpace.space4,
                  vertical: AkSpace.space3,
                ),
                enabledBorder: border(
                    hasError ? p.danger : p.borderControl, hasError ? 2 : 1.5),
                focusedBorder: border(hasError ? p.danger : p.focusRing, 2),
                border: border(p.borderControl, 1.5),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AkSpace.space1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 18, color: p.danger),
              const SizedBox(width: AkSpace.space1),
              Expanded(
                child: Semantics(
                    liveRegion: true,
                    child: Text(errorText!,
                        style: AkText.bodySm.copyWith(color: p.danger))),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Code PIN à 4 chiffres : 4 cases pilotées par un champ caché (clavier
/// numérique, collage accepté). Les cases restent de gauche à droite, même en
/// arabe : ce sont des chiffres.
class PinField extends StatefulWidget {
  const PinField({
    super.key,
    required this.label,
    required this.controller,
    this.hasError = false,
    this.onCompleted,
    this.onChanged,
    this.autofocus = false,
    this.fieldKey,
  });

  final String label;
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final Key? fieldKey;

  @override
  State<PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<PinField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    widget.controller.addListener(_onChange);
  }

  String _lastValue = '';

  void _onChange() {
    final v = widget.controller.text;
    if (v == _lastValue) return;
    _lastValue = v;
    setState(() {});
    widget.onChanged?.call(v);
    if (v.length == 4) widget.onCompleted?.call(v);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    final value = widget.controller.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AkText.label),
        const SizedBox(height: AkSpace.space1),
        Semantics(
          label: widget.label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focus.requestFocus,
            child: Stack(
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(width: AkSpace.space3),
                        Flexible(
                            child: _Box(
                          filled: i < value.length,
                          current:
                              _focus.hasFocus && i == value.length.clamp(0, 3),
                          error: widget.hasError,
                          palette: p,
                        )),
                      ],
                    ],
                  ),
                ),
                // Champ réel, invisible mais focalisable (clavier numérique).
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.01,
                    child: TextField(
                      key: widget.fieldKey,
                      controller: widget.controller,
                      focusNode: _focus,
                      autofocus: widget.autofocus,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      showCursor: false,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                          counterText: '', border: InputBorder.none),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box(
      {required this.filled,
      required this.current,
      required this.error,
      required this.palette});
  final bool filled;
  final bool current;
  final bool error;
  final AkPalette palette;

  @override
  Widget build(BuildContext context) {
    final border = error
        ? palette.danger
        : current
            ? palette.focusRing
            : palette.borderControl;
    return Container(
      width: AkSize.sizePin,
      height: AkSize.sizePin,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(AkRadius.radiusMd),
        border: Border.all(color: border, width: current || error ? 2 : 1.5),
      ),
      child: filled
          ? Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: palette.ink, shape: BoxShape.circle),
            )
          : null,
    );
  }
}

enum AkTone { success, warning, danger, info }

({Color fg, Color bg}) _toneColors(AkPalette p, AkTone t) => switch (t) {
      AkTone.success => (fg: p.success, bg: p.successBg),
      AkTone.warning => (fg: p.warning, bg: p.warningBg),
      AkTone.danger => (fg: p.danger, bg: p.dangerBg),
      AkTone.info => (fg: p.info, bg: p.infoBg),
    };

/// Pastille de statut : toujours une icône **et** un mot.
class AkStatusBadge extends StatelessWidget {
  const AkStatusBadge(
      {super.key, required this.label, required this.tone, required this.icon});
  final String label;
  final AkTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = _toneColors(context.ak, tone);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
          AkSpace.space2, 2, AkSpace.space3, 2),
      decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(AkRadius.radiusPill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.fg),
          const SizedBox(width: AkSpace.space1),
          Flexible(
              child: Text(label, style: AkText.label.copyWith(color: c.fg))),
        ],
      ),
    );
  }
}

typedef StatusChip = AkStatusBadge;

/// Bandeau intégré à l'écran : icône + titre en gras + une phrase.
class AkBanner extends StatelessWidget {
  const AkBanner(
      {super.key,
      required this.tone,
      required this.icon,
      required this.text,
      this.title});
  final AkTone tone;
  final IconData icon;
  final String text;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final c = _toneColors(context.ak, tone);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AkSpace.space4, vertical: AkSpace.space3),
      decoration: BoxDecoration(
          color: c.bg, borderRadius: BorderRadius.circular(AkRadius.radiusMd)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 22, color: c.fg)),
          const SizedBox(width: AkSpace.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title!,
                      style: AkText.bodySm
                          .copyWith(color: c.fg, fontWeight: FontWeight.w700)),
                Text(text, style: AkText.bodySm.copyWith(color: c.fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Surface de regroupement avec un filet discret.
class AkCard extends StatelessWidget {
  const AkCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(AkSpace.space4)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    return Material(
      color: p.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AkRadius.radiusLg),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// État plein écran : chargement impossible, vide, hors ligne, maintenance…
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.tone,
    this.actionLabel,
    this.onAction,
    this.secondaryAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final AkTone? tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final p = context.ak;
    final colors = tone == null
        ? (fg: p.primary, bg: p.surfaceTint)
        : _toneColors(p, tone!);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AkSpace.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(color: colors.bg, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: colors.fg),
            ),
            const SizedBox(height: AkSpace.space4),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(title,
                  style: AkText.titleLg, textAlign: TextAlign.center),
            ),
            const SizedBox(height: AkSpace.space2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(body,
                  style: AkText.body.copyWith(color: p.inkSoft),
                  textAlign: TextAlign.center),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AkSpace.space5),
              AkButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  kind: AkButtonKind.outline,
                  expand: false),
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: AkSpace.space3),
              secondaryAction!,
            ],
          ],
        ),
      ),
    );
  }
}

class AkEmptyState extends StateView {
  const AkEmptyState({
    super.key,
    required super.title,
    required super.body,
    super.icon = Icons.inbox_outlined,
    super.actionLabel,
    super.onAction,
  });
}

class AkErrorState extends StateView {
  const AkErrorState({
    super.key,
    required super.title,
    required super.body,
    super.icon = Icons.error_outline,
    super.actionLabel,
    super.onAction,
    super.secondaryAction,
  }) : super(tone: AkTone.warning);
}
