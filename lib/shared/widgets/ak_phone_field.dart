import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/ak_theme.dart';
import '../../app/theme/ak_tokens.dart';
import '../../core/phone.dart';
import '../../l10n/app_localizations.dart';
import 'ak_widgets.dart';

/// Téléphone international : pays (indicatif) puis numéro national.
///
/// Le numéro reste en chiffres latins, de gauche à droite (voir [AkTextField]).
/// Le pays « Autre » demande le numéro complet avec son indicatif.
class AkPhoneField extends StatelessWidget {
  const AkPhoneField({
    super.key,
    required this.label,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.errorText,
    this.fieldKey,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onCountryChanged;
  final String? errorText;
  final Key? fieldKey;
  final TextInputAction? textInputAction;

  Future<void> _pick(BuildContext context) async {
    final lang = Localizations.localeOf(context).languageCode;
    final chosen = await showModalBottomSheet<PhoneCountry>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in [...phoneCountries, phoneOtherCountry])
              ListTile(
                key: Key('dial-${c.iso.isEmpty ? 'other' : c.iso}'),
                title: Text(c.name(lang), style: AkText.body),
                trailing: c.dial.isEmpty
                    ? null
                    : Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text('+${c.dial}', style: AkText.bodyStrong),
                      ),
                selected: c.iso == country.iso,
                onTap: () => Navigator.of(ctx).pop(c),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) onCountryChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.ak;
    final lang = Localizations.localeOf(context).languageCode;
    final other = country.dial.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.fieldDial, style: AkText.label),
        const SizedBox(height: AkSpace.space1),
        Semantics(
          button: true,
          label: '${l.fieldDial}: ${country.name(lang)}',
          child: InkWell(
            key: const Key('dial-picker'),
            borderRadius: BorderRadius.circular(AkRadius.radiusMd),
            onTap: () => _pick(context),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: AkSpace.space4, vertical: AkSpace.space2),
              decoration: BoxDecoration(
                color: p.surfaceRaised,
                borderRadius: BorderRadius.circular(AkRadius.radiusMd),
                border: Border.all(color: p.borderControl, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(child: Text(country.name(lang), style: AkText.body)),
                        if (!other) ...[
                          const SizedBox(width: AkSpace.space2),
                          // L'indicatif reste de gauche à droite, même en arabe.
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text('+${country.dial}', style: AkText.body),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.expand_more, color: p.inkSoft),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AkSpace.space3),
        AkTextField(
          fieldKey: fieldKey,
          label: label,
          controller: controller,
          prefixText: other ? '+' : '+${country.dial}',
          hint: other ? l.fieldPhoneFull : null,
          keyboardType: TextInputType.phone,
          textInputAction: textInputAction,
          errorText: errorText,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩ ]'))],
          maxLength: 18,
        ),
      ],
    );
  }
}
