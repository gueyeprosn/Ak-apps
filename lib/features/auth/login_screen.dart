import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/animations/ak_motion.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/errors/error_messages.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../../shared/widgets/official_page_button.dart';
import 'access_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _tel = TextEditingController();
  final _pin = TextEditingController();
  final _suffix = TextEditingController();

  /// Premier accès : le membre n'a pas encore de PIN et saisit les 4 derniers
  /// caractères (lettres et chiffres) de son numéro de badge.
  bool _first = false;
  bool _busy = false;
  String? _error;
  bool _phoneInvalid = false;
  bool _codeInvalid = false;

  @override
  void dispose() {
    _tel.dispose();
    _pin.dispose();
    _suffix.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final tel = _tel.text.trim();
    // Le suffixe du badge est comparé en majuscules (collage, clavier sans majuscules).
    final code = _first ? _suffix.text.trim().toUpperCase() : _pin.text.trim();
    if (tel.length < 8 || code.length != 4) {
      setState(() {
        _phoneInvalid = tel.length < 8;
        _codeInvalid = code.length != 4;
        _error = l.invalidCredentials;
      });
      return;
    }
    setState(() {
      _busy = true;
      _phoneInvalid = false;
      _codeInvalid = false;
      _error = null;
    });
    try {
      // Numéro saisi sans indicatif : on ajoute +221 (Sénégal) par défaut.
      final full = tel.startsWith('+') ? tel : '+221$tel';
      final result = await ref
          .read(authControllerProvider.notifier)
          .login(tel: full, code: code);
      if (!mounted) return;
      if (result is PinSetupRequired) {
        ref.read(pinSetupSessionProvider.notifier).start(result.setupToken);
        context.go('/pin-setup');
      } else {
        context.go('/t/home');
      }
    } catch (e) {
      if (!mounted) return;
      final message = messageForError(l, e);
      setState(() {
        _error = message;
        _codeInvalid = message == l.invalidCredentials;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAccessHelp() {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    showAkBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: akPagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AkHeading(
                  title: l.accountAccessHeading,
                  subtitle: l.accountRecoveryHint),
              const SizedBox(height: AkSpace.space4),
              OfficialPageButton(
                  page: OfficialPage.support,
                  label: l.accountContactSupport,
                  kind: AkButtonKind.primary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AccessScaffold(
      title: l.loginTitle,
      subtitle: l.loginSubtitle,
      footer: [
        AkButton(
          key: const Key('toggle-first'),
          kind: AkButtonKind.text,
          label: _first ? l.havePinLink : l.firstLoginLink,
          onPressed: () => setState(() {
            _first = !_first;
            _error = null;
            _phoneInvalid = false;
            _codeInvalid = false;
            _pin.clear();
            _suffix.clear();
          }),
        ),
        AkButton(
          kind: AkButtonKind.text,
          label: l.accountForgotPin,
          onPressed: _showAccessHelp,
        ),
        AkButton(
          key: const Key('login-join'),
          kind: AkButtonKind.text,
          label: l.joinLink,
          onPressed: () => context.push('/join'),
        ),
      ],
      children: [
        AkTextField(
          label: l.phoneLabel,
          controller: _tel,
          hint: l.phoneHint,
          prefixText: '+221',
          errorText: _phoneInvalid ? _error : null,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumberNational],
        ),
        const SizedBox(height: AkSpace.space5),
        if (_first) ...[
          AkTextField(
            fieldKey: const Key('login-suffix'),
            label: l.firstLoginLabel,
            controller: _suffix,
            maxLength: 4,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]'))
            ],
            errorText: _codeInvalid && !_phoneInvalid ? _error : null,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AkSpace.space1),
          Text(l.firstLoginHelp,
              style: AkText.bodySm.copyWith(color: context.ak.inkSoft)),
        ] else
          PinField(
            fieldKey: const Key('login-pin'),
            label: l.pinLabel,
            controller: _pin,
            hasError: _codeInvalid,
            onCompleted: (_) => _submit(),
          ),
        if (_error != null && !_phoneInvalid && !(_first && _codeInvalid)) ...[
          const SizedBox(height: AkSpace.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 18, color: context.ak.danger),
              const SizedBox(width: AkSpace.space1),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    key: const Key('login-error'),
                    style: AkText.bodySm.copyWith(color: context.ak.danger),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AkSpace.space6),
        AkButton(
          label: _first ? l.firstLoginContinue : l.loginButton,
          onPressed: _submit,
          loading: _busy,
        ),
        const SizedBox(height: AkSpace.space2),
      ],
    );
  }
}
