import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../providers/safety_providers.dart';

/// Rappel de pause : après N minutes d'utilisation continue (réglage
/// `break_reminder_minutes`, 45 min par défaut pour les moins de 18 ans),
/// une fenêtre propose de faire une pause. Le compteur ne tourne que quand
/// l'appli est au premier plan. Aucune récompense ni pénalité.
class BreakReminder extends ConsumerStatefulWidget {
  const BreakReminder({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BreakReminder> createState() => _BreakReminderState();
}

class _BreakReminderState extends ConsumerState<BreakReminder> with WidgetsBindingObserver {
  Timer? _tick;
  int _activeSeconds = 0;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => _onTick());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Après une vraie pause (appli en arrière-plan), on repart de zéro.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _activeSeconds = 0;
    }
  }

  void _onTick() {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed || _showing) return;
    _activeSeconds += 30;
    final minutes = ref.read(mySafetyNowProvider).breakReminderMinutes;
    if (minutes > 0 && _activeSeconds >= minutes * 60) {
      _activeSeconds = 0;
      _show(minutes);
    }
  }

  Future<void> _show(int minutes) async {
    if (!mounted) return;
    _showing = true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.self_improvement, size: 36),
        title: Text('Et si tu faisais une pause ?'.tr),
        content: Text(
          ('Tu joues depuis {n} minutes. Va boire un verre d\'eau, t\'entraîner '
                  'avec un vrai ballon ou voir tes amis : ta progression t\'attend.')
              .trArgs({'n': minutes}),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('OK'.tr)),
        ],
      ),
    );
    _showing = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
