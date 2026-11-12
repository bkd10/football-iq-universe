import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../data/legal_info.dart';
import '../../data/legal_texts.dart';

/// Les documents légaux de l'appli, tous lisibles sans compte.
enum LegalDoc {
  legalNotice('mentions-legales'),
  terms('cgu'),
  privacy('confidentialite'),
  cookies('cookies'),
  ballons('regles-ballons');

  const LegalDoc(this.slug);

  final String slug;

  static LegalDoc fromSlug(String? slug) =>
      LegalDoc.values.firstWhere((d) => d.slug == slug, orElse: () => LegalDoc.terms);

  String get title => switch (this) {
        LegalDoc.legalNotice => 'Mentions légales'.tr,
        LegalDoc.terms => 'Conditions d\'utilisation'.tr,
        LegalDoc.privacy => 'Confidentialité'.tr,
        LegalDoc.cookies => 'Cookies'.tr,
        LegalDoc.ballons => 'Règles des Ballons et remboursements'.tr,
      };

  IconData get icon => switch (this) {
        LegalDoc.legalNotice => Icons.business_outlined,
        LegalDoc.terms => Icons.description_outlined,
        LegalDoc.privacy => Icons.lock_outline,
        LegalDoc.cookies => Icons.cookie_outlined,
        LegalDoc.ballons => Icons.sports_soccer,
      };

  /// Texte en français, sinon en anglais (version de référence : le
  /// français).
  String get body {
    final fr = L10n.language == 'fr';
    final raw = switch (this) {
      LegalDoc.legalNotice => fr ? legalNoticeFr : legalNoticeEn,
      LegalDoc.terms => fr ? termsFr : termsEn,
      LegalDoc.privacy => fr ? privacyFr : privacyEn,
      LegalDoc.cookies => fr ? cookiesFr : cookiesEn,
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
                  child: Semantics(
                    header: true,
                    child: Text(line.substring(3), style: context.textTheme.titleMedium),
                  ),
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
