import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/errors/error_messages.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_widgets.dart';
import 'access_scaffold.dart';

/// Création du premier PIN. Le jeton à usage unique reste en mémoire ; s'il
/// manque (application relancée), on revient à la connexion.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final token = ref.read(pinSetupSessionProvider);
    if (token == null) {
      context.go('/login');
      return;
    }
    if (_pin.text.length != 4 || _pin.text != _confirm.text) {
      setState(() => _error = l.pinMismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).completePinSetup(
            setupToken: token,
            pin: _pin.text,
            pinConfirm: _confirm.text,
          );
      ref.read(pinSetupSessionProvider.notifier).clear();
      if (mounted) context.go('/t/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageForError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.ak;
    final ready = _pin.text.length == 4 && _confirm.text.length == 4;
    return AccessScaffold(
      title: l.pinSetupTitle,
      subtitle: l.pinSetupBody,
      children: [
        PinField(
          fieldKey: const Key('setup-pin'),
          label: l.newPinLabel,
          controller: _pin,
          autofocus: true,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: AkSpace.space5),
        PinField(
          fieldKey: const Key('setup-confirm'),
          label: l.confirmPinLabel,
          controller: _confirm,
          hasError: _error != null,
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) ...[
          const SizedBox(height: AkSpace.space2),
          Semantics(
            liveRegion: true,
            child: Text(_error!,
                key: const Key('setup-error'),
                style: AkText.bodySm.copyWith(color: p.danger)),
          ),
        ],
        const SizedBox(height: AkSpace.space6),
        AkButton(
            label: l.pinSave,
            onPressed: ready ? _submit : null,
            loading: _busy),
      ],
    );
  }
}
