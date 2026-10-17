import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';

/// Ligne « date + heure » cliquable des formulaires de défi.
class DateTimeField extends StatelessWidget {
  const DateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.enabled = true,
    super.key,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool enabled;

  static String format(DateTime d) => '{date} à {time}'.trArgs({
        'date': '${d.day}/${d.month}/${d.year}',
        'time': '${d.hour.toString().padLeft(2, '0')}:'
            '${d.minute.toString().padLeft(2, '0')}',
      });

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value.isBefore(firstDate) ? firstDate : value,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
    if (time == null) return;
    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(format(value)),
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: enabled ? () => _pick(context) : null,
    );
  }
}
