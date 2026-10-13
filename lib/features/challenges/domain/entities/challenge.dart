import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../videos/domain/entities/video_creator.dart';

part 'challenge.freezed.dart';

/// Un défi — voir PARTIE 8.3 : 5 types (battle, challenge, king, world,
/// sponsored), chacun avec sa propre mécanique de résolution.
@freezed
class Challenge with _$Challenge {
  const factory Challenge({
    required String id,
    required String title,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime createdAt,
    String? description,
    String? category,
    @Default(0) int entryCost,
    @Default(0) int prizePool,
    @Default('coins') String prizeCurrency,
    String? prizeDescription,
    double? currentRecord,
    String? recordUnit,
    int? maxParticipants,
    @Default(0) int participantsCount,
    @Default('active') String status,
    String? winnerId,
    String? sponsorName,
    String? sponsorLogoUrl,
    @Default(false) bool isOfficial,
    VideoCreator? creator,
    VideoCreator? recordHolder,
  }) = _Challenge;

  const Challenge._();

  bool get hasEnded => DateTime.now().isAfter(endDate);
  Duration get timeRemaining => endDate.difference(DateTime.now());

  bool get isFull =>
      maxParticipants != null && participantsCount >= maxParticipants!;
}
