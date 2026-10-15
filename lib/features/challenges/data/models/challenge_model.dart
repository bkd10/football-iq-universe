import 'package:json_annotation/json_annotation.dart';

import '../../../videos/data/models/video_creator_model.dart';
import '../../domain/entities/challenge.dart';

part 'challenge_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ChallengeModel {
  const ChallengeModel({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.description,
    this.category,
    this.entryCost = 0,
    this.prizePool = 0,
    this.prizeCurrency = 'coins',
    this.prizeDescription,
    this.currentRecord,
    this.recordUnit,
    this.maxParticipants,
    this.participantsCount = 0,
    this.status = 'active',
    this.winnerId,
    this.sponsorName,
    this.sponsorLogoUrl,
    this.isOfficial = false,
    this.creator,
    this.recordHolder,
    this.opponentId,
    this.opponent,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) =>
      _$ChallengeModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChallengeModelToJson(this);

  final String id;
  final String title;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final String? description;
  final String? category;
  final int entryCost;
  final int prizePool;
  final String prizeCurrency;
  final String? prizeDescription;
  final double? currentRecord;
  final String? recordUnit;
  final int? maxParticipants;
  final int participantsCount;
  final String status;
  final String? winnerId;
  final String? sponsorName;
  final String? sponsorLogoUrl;
  final bool isOfficial;
  final VideoCreatorModel? creator;
  @JsonKey(name: 'record_holder')
  final VideoCreatorModel? recordHolder;
  final String? opponentId;
  final VideoCreatorModel? opponent;

  Challenge toEntity() {
    return Challenge(
      id: id,
      title: title,
      type: type,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      description: description,
      category: category,
      entryCost: entryCost,
      prizePool: prizePool,
      prizeCurrency: prizeCurrency,
      prizeDescription: prizeDescription,
      currentRecord: currentRecord,
      recordUnit: recordUnit,
      maxParticipants: maxParticipants,
      participantsCount: participantsCount,
      status: status,
      winnerId: winnerId,
      sponsorName: sponsorName,
      sponsorLogoUrl: sponsorLogoUrl,
      isOfficial: isOfficial,
      creator: creator?.toEntity(),
      recordHolder: recordHolder?.toEntity(),
      opponentId: opponentId,
      opponent: opponent?.toEntity(),
    );
  }
}
