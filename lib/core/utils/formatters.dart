import '../l10n/l10n.dart';

/// Formatage de nombres et durées pour l'affichage (compteurs, stats, vidéo).
class Formatters {
  const Formatters._();

  /// Compacte un compteur pour l'affichage : 1200 -> "1.2K", 3400000 -> "3.4M".
  static String compactCount(int value) {
    if (value < 1000) return '$value';
    if (value < 1000000) {
      final k = value / 1000;
      return '${_trimTrailingZero(k)}K';
    }
    final m = value / 1000000;
    return '${_trimTrailingZero(m)}M';
  }

  static String _trimTrailingZero(double value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }

  /// Formate une durée vidéo en mm:ss.
  static String videoDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Timestamp relatif simple (à la TikTok) : "3h", "2j", "5sem".
  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'à l\'instant'.tr;
    if (diff.inHours < 1) return '{n}min'.trArgs({'n': diff.inMinutes});
    if (diff.inDays < 1) return '{n}h'.trArgs({'n': diff.inHours});
    if (diff.inDays < 7) return '{n}j'.trArgs({'n': diff.inDays});
    if (diff.inDays < 30) return '{n}sem'.trArgs({'n': (diff.inDays / 7).floor()});
    return '{n}mois'.trArgs({'n': (diff.inDays / 30).floor()});
  }

  /// Temps restant avant la fin d'un défi : "2j 4h", "3h 12min", "Terminé".
  static String countdown(Duration remaining) {
    if (remaining.isNegative) return 'Terminé'.tr;
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    if (days > 0) return '{d}j {h}h'.trArgs({'d': days, 'h': hours});
    if (hours > 0) return '{h}h {m}min'.trArgs({'h': hours, 'm': minutes});
    return '{n}min'.trArgs({'n': minutes});
  }

  /// Date courte « 24/11 18:00 », sans compte à rebours (réglage
  /// `show_countdowns` désactivé, par défaut chez les moins de 18 ans).
  static String shortDate(DateTime date) {
    final d = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  /// Texte de temps d'un défi : compte à rebours, ou date fixe si
  /// [countdowns] vaut false.
  static String challengeTime({
    required bool hasStarted,
    required DateTime startDate,
    required DateTime endDate,
    required bool countdowns,
    String startPrefix = 'Dans {time}',
  }) {
    if (!countdowns) {
      return hasStarted
          ? 'Fin le {date}'.trArgs({'date': shortDate(endDate)})
          : 'Début le {date}'.trArgs({'date': shortDate(startDate)});
    }
    return hasStarted
        ? countdown(endDate.difference(DateTime.now()))
        : startPrefix.trArgs({'time': countdown(startDate.difference(DateTime.now()))});
  }
}
