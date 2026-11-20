import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/format.dart';
import '../../core/phone.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_choice.dart';
import '../../shared/widgets/ak_phone_field.dart';
import '../../shared/widgets/ak_widgets.dart';
import '../payment/pay_widgets.dart';
import 'adhesion_screen.dart' show phoneProblemMessage;
import 'amount_choice.dart';
import 'public_pay_controller.dart';
import 'public_pay_repository.dart';
import 'public_pay_shell.dart';

/// Don / contribution : montant, destination, identité facultative, puis
/// paiement. Un don anonyme n'envoie aucune donnée d'identité.
class DonationScreen extends ConsumerWidget {
  const DonationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return PublicPayShell(
      provider: donationPayProvider,
      copy: PublicPayCopy(
        title: l.actionContribute,
        notYetPaidBody: l.donateNotYetPaidBody,
        editLabel: l.donateEditInfo,
        doneTitle: l.donateDoneTitle,
        doneBody: (amount) => l.donateDoneBody(amount),
      ),
      form: const _DonationForm(),
    );
  }
}

String _campaignLabel(AppLocalizations l, String c) => switch (c) {
      'general' => l.campaignGeneral,
      'touba' => l.campaignTouba,
      'magal' => l.campaignMagal,
      'education' => l.campaignEducation,
      _ => l.campaignOther,
    };

class _DonationForm extends ConsumerStatefulWidget {
  const _DonationForm();

  @override
  ConsumerState<_DonationForm> createState() => _DonationFormState();
}

class _DonationFormState extends ConsumerState<_DonationForm> {
  final _prenoms = TextEditingController();
  final _nom = TextEditingController();
  final _tel = TextEditingController();
  final _email = TextEditingController();
  final _other = TextEditingController();
  final _message = TextEditingController();
  PhoneCountry _country = defaultPhoneCountry;
  String _montant = donationAmounts[1];
  String _campagne = donationCampaigns.first;
  bool _anonymous = false;
  Map<String, String> _errors = const {};
  final _keys = <String, GlobalKey>{
    'other': GlobalKey(),
    'prenoms': GlobalKey(),
    'tel': GlobalKey(),
    'email': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    // Membre connecté : identité pré-remplie (modifiable, ou anonymat possible).
    final auth = ref.read(authControllerProvider);
    if (auth is AuthLoggedIn) {
      _prenoms.text = auth.member.prenoms;
      _nom.text = auth.member.nom;
      final raw = auth.member.whatsapp.isNotEmpty ? auth.member.whatsapp : auth.member.tel;
      if (raw.isNotEmpty) {
        final split = splitE164(raw);
        _country = split.country;
        _tel.text = split.national;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_prenoms, _nom, _tel, _email, _other, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  int? get _amount => _montant == 'autre' ? parseOtherAmount(_other.text) : int.tryParse(_montant);

  void _submit() {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final errors = <String, String>{};
    String tel = '';
    if (!_anonymous) {
      if (_prenoms.text.trim().length < 2) {
        errors['prenoms'] = _prenoms.text.trim().isEmpty ? l.errRequired : l.errTooShort;
      }
      final phone = validatePhone(_country, _tel.text);
      if (phone.isOk) {
        tel = phone.e164!;
      } else {
        errors['tel'] = phoneProblemMessage(l, phone.problem!);
      }
      final email = _email.text.trim();
      if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        errors['email'] = l.errEmail;
      }
    }
    if (_montant == 'autre') {
      final n = parseOtherAmount(_other.text);
      if (n == null) {
        errors['other'] = l.errAmountMissing;
      } else if (n < donationOtherMin) {
        errors['other'] = l.errAmountMin(formatAmount(donationOtherMin, lang));
      }
    }
    setState(() => _errors = errors);
    if (errors.isNotEmpty) {
      _revealFirstError(const ['other', 'prenoms', 'tel', 'email']);
      return;
    }
    ref.read(donationPayProvider.notifier).submit(
          DonationDraft(
            anonymous: _anonymous,
            montant: _montant,
            montantAutre: _montant == 'autre' ? otherAmountDigits(_other.text) : '',
            campagne: _campagne,
            prenoms: _anonymous ? '' : _prenoms.text,
            nom: _anonymous ? '' : _nom.text,
            tel: tel,
            email: _anonymous ? '' : _email.text,
            message: _message.text,
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
    final p = context.ak;
    final s = ref.watch(donationPayProvider);
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
                AkHeading(title: l.donateAmountTitle, section: true),
                const SizedBox(height: AkSpace.space3),
                AmountChoice(
                  key: _keys['other'],
                  values: donationAmounts,
                  selected: _montant,
                  onSelected: (v) => setState(() => _montant = v),
                  otherController: _other,
                  errorText: _errors['other'],
                ),
                const SizedBox(height: AkSpace.space6),
                AkHeading(title: l.donateCampaign, section: true),
                const SizedBox(height: AkSpace.space3),
                for (final c in donationCampaigns) ...[
                  AkChoiceTile(
                    key: Key('campaign-$c'),
                    title: _campaignLabel(l, c),
                    selected: _campagne == c,
                    onTap: () => setState(() => _campagne = c),
                  ),
                  const SizedBox(height: AkSpace.space2),
                ],
                const SizedBox(height: AkSpace.space4),
                AkHeading(title: l.donateIdentityTitle, section: true),
                Text(
                  l.donateIdentitySubtitle,
                  style: AkText.bodySm.copyWith(color: p.inkSoft),
                ),
                SwitchListTile(
                  key: const Key('donate-anonymous'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.donateAnonymous, style: AkText.body),
                  value: _anonymous,
                  onChanged: (v) => setState(() {
                    _anonymous = v;
                    _errors = const {};
                  }),
                ),
                if (!_anonymous) ...[
                  const SizedBox(height: AkSpace.space2),
                  AkTextField(
                    key: _keys['prenoms'],
                    fieldKey: const Key('donate-prenoms'),
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
                    fieldKey: const Key('donate-nom'),
                    label: l.fieldLastName,
                    controller: _nom,
                    textCapitalization: TextCapitalization.words,
                    textDirection: Directionality.of(context),
                    textInputAction: TextInputAction.next,
                    maxLength: 80,
                  ),
                  const SizedBox(height: AkSpace.space3),
                  AkPhoneField(
                    key: _keys['tel'],
                    fieldKey: const Key('donate-tel'),
                    label: l.fieldPhoneWhatsapp,
                    controller: _tel,
                    country: _country,
                    onCountryChanged: (c) => setState(() => _country = c),
                    errorText: _errors['tel'],
                  ),
                  const SizedBox(height: AkSpace.space3),
                  AkTextField(
                    key: _keys['email'],
                    fieldKey: const Key('donate-email'),
                    label: l.fieldEmailOptional,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _errors['email'],
                    maxLength: 160,
                  ),
                  const SizedBox(height: AkSpace.space3),
                  // Transparence : un don avec téléphone peut créer une fiche membre.
                  AkBanner(
                    tone: AkTone.info,
                    icon: Icons.info_outline,
                    text: l.donateMemberNote,
                  ),
                ],
                const SizedBox(height: AkSpace.space5),
                AkTextField(
                  fieldKey: const Key('donate-message'),
                  label: l.donateMessage,
                  hint: l.donateMessageHint,
                  controller: _message,
                  textDirection: Directionality.of(context),
                  maxLines: 4,
                  maxLength: 500,
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
            key: const Key('donate-submit'),
            label: l.donateSubmit,
            loading: s.busy,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
