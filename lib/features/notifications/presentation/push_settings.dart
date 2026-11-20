import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/ak_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ak_widgets.dart';
import 'push_controller.dart';

class PushSettings extends ConsumerWidget {
  const PushSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(pushControllerProvider);
    if (status == PushStatus.unavailable) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final controller = ref.read(pushControllerProvider.notifier);

    return AkCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        key: const Key('push-toggle'),
        title: Text(l.pushSettingTitle, style: AkText.bodyStrong),
        subtitle: Text(status == PushStatus.denied ? l.pushDenied : l.pushSettingSubtitle),
        value: status == PushStatus.on || (status == PushStatus.working && controller.optedIn),
        onChanged: status == PushStatus.working
            ? null
            : (enabled) async {
                final succeeded = await (enabled ? controller.enable() : controller.disable());
                if (succeeded || !context.mounted || ref.read(pushControllerProvider) == PushStatus.denied) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pushUpdateError)));
              },
      ),
    );
  }
}
