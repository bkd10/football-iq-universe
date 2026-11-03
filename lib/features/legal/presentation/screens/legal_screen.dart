import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../data/legal_info.dart';
import '../../data/legal_texts.dart';

/// Les trois documents légaux de l'appli.
enum LegalDoc {
  terms('cgu'),
  privacy('confidentialite'),
  ballons('regles-ballons');

  const LegalDoc(this.slug);

  final String slug;

  static LegalDoc fromSlug(String? slug) =>
      LegalDoc.values.firstWhere((d) => d.slug == slug, orElse: () => LegalDoc.terms);

  String get title => switch (this) {
        LegalDoc.terms => 'Conditions d\'utilisation'.tr,
        LegalDoc.privacy => 'Confidentialité'.tr,
        LegalDoc.ballons => 'Règles des Ballons'.tr,
      };

  /// Texte en français, sinon en anglais (version de référence : le
  /// français).
  String get body {
    final fr = L10n.language == 'fr';
    final raw = switch (this) {
      LegalDoc.terms => fr ? termsFr : termsEn,
      LegalDoc.privacy => fr ? privacyFr : privacyEn,
      LegalDoc.ballons => fr ? ballonsFr : ballonsEn,
    };
    var text = raw.trim();
    LegalInfo.placeholders.forEach((k, v) => text = text.replaceAll('{$k}', v));
    return text;
  }
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.doc, super.key});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final lines = doc.body.split('\n').where((l) => l.trim().isNotEmpty);
    final showNote = L10n.language != 'fr' && L10n.language != 'en';
    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (showNote) ...[
              Text(
                'Ce document est disponible en français et en anglais.'.tr,
                style: context.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            for (final line in lines)
              if (line.startsWith('## '))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
                  child: Text(line.substring(3), style: context.textTheme.titleMedium),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(line, style: context.textTheme.bodyMedium),
                ),
          ],
        ),
      ),
    );
  }
}
