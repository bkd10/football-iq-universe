// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChallengeModel _$ChallengeModelFromJson(Map<String, dynamic> json) =>
    ChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      category: json['category'] as String?,
      entryCost: (json['entry_cost'] as num?)?.toInt() ?? 0,
      prizePool: (json['prize_pool'] as num?)?.toInt() ?? 0,
      prizeCurrency: json['prize_currency'] as String? ?? 'coins',
      prizeDescription: json['prize_description'] as String?,
      currentRecord: (json['current_record'] as num?)?.toDouble(),
      recordUnit: json['record_unit'] as String?,
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      participantsCount: (json['participants_count'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
      winnerId: json['winner_id'] as String?,
      sponsorName: json['sponsor_name'] as String?,
      sponsorLogoUrl: json['sponsor_logo_url'] as String?,
      isOfficial: json['is_official'] as bool? ?? false,
      creator: json['creator'] == null
          ? null
          : VideoCreatorModel.fromJson(json['creator'] as Map<String, dynamic>),
      recordHolder: json['record_holder'] == null
          ? null
          : VideoCreatorModel.fromJson(
              json['record_holder'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChallengeModelToJson(ChallengeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': instance.type,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'description': instance.description,
      'category': instance.category,
      'entry_cost': instance.entryCost,
      'prize_pool': instance.prizePool,
      'prize_currency': instance.prizeCurrency,
      'prize_description': instance.prizeDescription,
      'current_record': instance.currentRecord,
      'record_unit': instance.recordUnit,
      'max_participants': instance.maxParticipants,
      'participants_count': instance.participantsCount,
      'status': instance.status,
      'winner_id': instance.winnerId,
      'sponsor_name': instance.sponsorName,
      'sponsor_logo_url': instance.sponsorLogoUrl,
      'is_official': instance.isOfficial,
      'creator': instance.creator?.toJson(),
      'record_holder': instance.recordHolder?.toJson(),
    };
