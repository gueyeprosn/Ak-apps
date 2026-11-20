import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/ak_tokens.dart';
import '../../core/format.dart';
import '../../core/phone.dart' show latinDigits;
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/ak_choice.dart';
import '../../shared/widgets/ak_widgets.dart';

/// Montant saisi dans « autre » : chiffres seulement (arabo-indiens acceptés),
/// espaces ignorés. `null` si vide ou illisible.
int? parseOtherAmount(String raw) {
  final digits = latinDigits(raw).replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

/// Chiffres latins uniquement, tels qu'envoyés au serveur.
String otherAmountDigits(String raw) =>
    latinDigits(raw).replaceAll(RegExp(r'\D'), '');

/// Choix d'un montant parmi ceux du site, plus « autre montant ».
class AmountChoice extends StatelessWidget {
  const AmountChoice({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.otherController,
    this.perMonth = false,
    this.errorText,
  });

  /// Montants proposés (valeurs du serveur : `1400`, `5000`…).
  final List<String> values;

  /// Valeur choisie : l'une de [values] ou `autre`.
  final String selected;
  final ValueChanged<String> onSelected;
  final TextEditingController otherController;
  final bool perMonth;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final v in values) ...[
          AkChoiceTile(
            key: Key('amount-$v'),
            title: formatAmount(int.parse(v), lang),
            subtitle: perMonth ? l.amountPerMonth : null,
            selected: selected == v,
            onTap: () => onSelected(v),
          ),
          const SizedBox(height: AkSpace.space2),
        ],
        AkChoiceTile(
          key: const Key('amount-autre'),
          title: l.amountOther,
          selected: selected == 'autre',
          onTap: () => onSelected('autre'),
        ),
        if (selected == 'autre') ...[
          const SizedBox(height: AkSpace.space3),
          AkTextField(
            fieldKey: const Key('amount-other-field'),
            label: l.fieldAmountOther,
            controller: otherController,
            keyboardType: TextInputType.number,
            errorText: errorText,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩ ]')),
            ],
            maxLength: 12,
          ),
        ],
      ],
    );
  }
}
