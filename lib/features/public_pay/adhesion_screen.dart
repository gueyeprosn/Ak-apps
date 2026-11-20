import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/format.dart';
import '../../core/phone.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_phone_field.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../payment/pay_widgets.dart';
import 'amount_choice.dart';
import 'public_pay_controller.dart';
import 'public_pay_repository.dart';
import 'public_pay_shell.dart';

/// Adhésion (formulaire « allégé » du site) : identité, pays, montant, puis
/// paiement. Le membre n'est créé par le serveur qu'après la confirmation.
class AdhesionScreen extends ConsumerWidget {
  const AdhesionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return PublicPayShell(
      provider: adhesionPayProvider,
      copy: PublicPayCopy(
        title: l.joinTitle,
        notYetPaidBody: l.joinNotYetPaidBody,
        editLabel: l.joinEditInfo,
        doneTitle: l.joinDoneTitle,
        doneBody: (amount) => l.joinDoneBody(amount),
        loginAfterDone: true,
      ),
      form: const _AdhesionForm(),
    );
  }
}

class _AdhesionForm extends ConsumerStatefulWidget {
  const _AdhesionForm();

  @override
  ConsumerState<_AdhesionForm> createState() => _AdhesionFormState();
}

class _AdhesionFormState extends ConsumerState<_AdhesionForm> {
  final _prenoms = TextEditingController();
  final _nom = TextEditingController();
  final _tel = TextEditingController();
  final _region = TextEditingController();
  final _other = TextEditingController();
  PhoneCountry _country = defaultPhoneCountry;
  String _montant = adhesionAmounts.first;
  Map<String, String> _errors = const {};
  final _keys = <String, GlobalKey>{
    'prenoms': GlobalKey(),
    'nom': GlobalKey(),
    'tel': GlobalKey(),
    'region': GlobalKey(),
    'other': GlobalKey(),
  };

  @override
  void dispose() {
    for (final c in [_prenoms, _nom, _tel, _region, _other]) {
      c.dispose();
    }
    super.dispose();
  }

  int? get _amount => _montant == 'autre' ? parseOtherAmount(_other.text) : int.tryParse(_montant);

  void _submit() {
    final l = AppLocalizations.of(context);
    final errors = <String, String>{};
    if (_prenoms.text.trim().length < 2) {
      errors['prenoms'] = _prenoms.text.trim().isEmpty ? l.errRequired : l.errTooShort;
    }
    if (_nom.text.trim().length < 2) {
      errors['nom'] = _nom.text.trim().isEmpty ? l.errRequired : l.errTooShort;
    }
    final phone = validatePhone(_country, _tel.text);
    if (!phone.isOk) errors['tel'] = phoneProblemMessage(l, phone.problem!);
    if (_region.text.trim().length < 2) {
      errors['region'] = _region.text.trim().isEmpty ? l.errRequired : l.errTooShort;
    }
    if (_montant == 'autre') {
      final n = parseOtherAmount(_other.text);
      if (n == null) {
        errors['other'] = l.errAmountMissing;
      } else if (n < adhesionOtherMin) {
        final lang = Localizations.localeOf(context).languageCode;
        errors['other'] = l.errAmountMin(formatAmount(adhesionOtherMin, lang));
      }
    }
    setState(() => _errors = errors);
    if (errors.isNotEmpty) {
      _revealFirstError(const ['prenoms', 'nom', 'tel', 'region', 'other']);
      return;
    }
    ref.read(adhesionPayProvider.notifier).submit(
          AdhesionDraft(
            nom: _nom.text,
            prenoms: _prenoms.text,
            tel: phone.e164!,
            paysRegion: _region.text,
            montant: _montant,
            montantAutre: _montant == 'autre' ? otherAmountDigits(_other.text) : '',
          ),
        );
  }

  /// Les erreurs peuvent se trouver sous le pli : on amène la première à l'écran.
  void _revealFirstError(List<String> order) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final k in order) {
        if (!_errors.containsKey(k)) continue;
        final ctx = _keys[k]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.1,
            duration: const Duration(milliseconds: 250),
          );
        }
        break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final s = ref.watch(adhesionPayProvider);
    final amount = _amount;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AkSpace.space4,
              AkSpace.space2,
              AkSpace.space4,
              AkSpace.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.joinIntro, style: AkText.body),
                const SizedBox(height: AkSpace.space5),
                AkHeading(title: l.joinIdentityTitle, section: true),
                const SizedBox(height: AkSpace.space3),
                AkTextField(
                  key: _keys['prenoms'],
                  fieldKey: const Key('join-prenoms'),
                  label: l.fieldFirstNames,
                  controller: _prenoms,
                  textCapitalization: TextCapitalization.words,
                  textDirection: Directionality.of(context),
                  textInputAction: TextInputAction.next,
                  errorText: _errors['prenoms'],
                  maxLength: 120,
                ),
                const SizedBox(height: AkSpace.space3),
                AkTextField(
                  key: _keys['nom'],
                  fieldKey: const Key('join-nom'),
                  label: l.fieldLastName,
                  controller: _nom,
                  textCapitalization: TextCapitalization.words,
                  textDirection: Directionality.of(context),
                  textInputAction: TextInputAction.next,
                  errorText: _errors['nom'],
                  maxLength: 80,
                ),
                const SizedBox(height: AkSpace.space3),
                AkPhoneField(
                  key: _keys['tel'],
                  fieldKey: const Key('join-tel'),
                  label: l.fieldPhoneWhatsapp,
                  controller: _tel,
                  country: _country,
                  onCountryChanged: (c) => setState(() => _country = c),
                  errorText: _errors['tel'],
                ),
                const SizedBox(height: AkSpace.space3),
                AkTextField(
                  key: _keys['region'],
                  fieldKey: const Key('join-region'),
                  label: l.fieldCountryRegion,
                  hint: l.fieldCountryRegionHint,
                  controller: _region,
                  textDirection: Directionality.of(context),
                  errorText: _errors['region'],
                  maxLength: 120,
                ),
                const SizedBox(height: AkSpace.space6),
                AkHeading(title: l.joinAmountTitle, section: true),
                Text(l.joinAmountSubtitle, style: AkText.bodySm),
                const SizedBox(height: AkSpace.space3),
                AmountChoice(
                  key: _keys['other'],
                  values: adhesionAmounts,
                  perMonth: true,
                  selected: _montant,
                  onSelected: (v) => setState(() => _montant = v),
                  otherController: _other,
                  errorText: _errors['other'],
                ),
                const SizedBox(height: AkSpace.space5),
                AkBanner(
                  tone: AkTone.info,
                  icon: Icons.info_outline,
                  text: l.joinNotMemberYet,
                ),
              ],
            ),
          ),
        ),
        // Erreur du serveur : toujours visible, jamais cachée sous le pli.
        if (s.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AkSpace.space4,
              AkSpace.space2,
              AkSpace.space4,
              AkSpace.space2,
            ),
            child: PublicFormError(error: s.error!),
          ),
        PayFooter(
          total: amount == null ? '—' : formatAmount(amount, lang),
          button: AkButton(
            key: const Key('join-submit'),
            label: l.joinSubmit,
            loading: s.busy,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

/// Message de validation d'un numéro (jamais le texte du serveur).
String phoneProblemMessage(AppLocalizations l, PhoneProblem p) => switch (p) {
      PhoneProblem.empty => l.errRequired,
      PhoneProblem.tooShort => l.errPhoneShort,
      PhoneProblem.tooLong => l.errPhoneLong,
      PhoneProblem.invalidSenegal => l.errPhoneSenegal,
    };
