import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../providers/admin_providers.dart';

/// Création d'un défi officiel (type « Défi Monde ») : gratuit pour les
/// joueurs, sans coût de création, marqué officiel.
class AdminOfficialChallengeScreen extends ConsumerStatefulWidget {
  const AdminOfficialChallengeScreen({super.key});

  @override
  ConsumerState<AdminOfficialChallengeScreen> createState() => _AdminOfficialChallengeScreenState();
}

class _AdminOfficialChallengeScreenState extends ConsumerState<AdminOfficialChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prizeController = TextEditingController();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prizeController.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now().add(const Duration(hours: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endDate),
    );
    if (time == null) return;

    setState(() {
      _endDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final id = await ref.read(adminDataSourceProvider).createOfficialChallenge(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            endDate: _endDate,
            prizeDescription: _prizeController.text.trim().isEmpty ? null : _prizeController.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(adminStatsProvider);
      context
        ..showSnackBar('Défi officiel publié.')
        ..pushReplacement(RouteNames.challengeDetailPath(id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.showSnackBar(adminErrorText(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final end = '${_endDate.day}/${_endDate.month}/${_endDate.year} à '
        '${_endDate.hour.toString().padLeft(2, '0')}h${_endDate.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Défi officiel')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextFormField(
              controller: _titleController,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Titre', hintText: 'Défi Ballon d\'Or'),
              validator: (v) => (v == null || v.trim().length < 3) ? '3 caractères minimum.' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              maxLength: 1000,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Règles du défi',
                hintText: 'Ex : ton plus beau but de la semaine, en une seule prise.',
              ),
            ),
            TextFormField(
              controller: _prizeController,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Récompense (optionnel)',
                hintText: 'Ex : le gagnant est mis en avant sur la page d\'accueil',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Fin du défi'),
              subtitle: Text(end),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickEndDate,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Publier le défi officiel',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
