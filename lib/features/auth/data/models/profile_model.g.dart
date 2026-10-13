// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) => ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String? ?? '',
      country: json['country'] as String?,
      city: json['city'] as String?,
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      position: json['position'] as String?,
      preferredFoot: json['preferred_foot'] as String? ?? 'droit',
      heightCm: (json['height_cm'] as num?)?.toInt(),
      weightKg: (json['weight_kg'] as num?)?.toInt(),
      role: json['role'] as String? ?? 'player',
      guardianName: json['guardian_name'] as String?,
      guardianEmail: json['guardian_email'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      verificationType: json['verification_type'] as String?,
      coins: (json['coins'] as num?)?.toInt() ?? 500,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      level: json['level'] as String? ?? 'rookie',
      iqTechnique: (json['iq_technique'] as num?)?.toInt() ?? 0,
      iqCreativity: (json['iq_creativity'] as num?)?.toInt() ?? 0,
      iqPopularity: (json['iq_popularity'] as num?)?.toInt() ?? 0,
      iqConsistency: (json['iq_consistency'] as num?)?.toInt() ?? 0,
      iqTactical: (json['iq_tactical'] as num?)?.toInt() ?? 0,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      lastLoginDate: json['last_login_date'] == null
          ? null
          : DateTime.parse(json['last_login_date'] as String),
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      videosCount: (json['videos_count'] as num?)?.toInt() ?? 0,
      movesCreatedCount: (json['moves_created_count'] as num?)?.toInt() ?? 0,
      likesReceivedCount: (json['likes_received_count'] as num?)?.toInt() ?? 0,
      challengesWonCount: (json['challenges_won_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ProfileModelToJson(ProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'bio': instance.bio,
      'country': instance.country,
      'city': instance.city,
      'birth_date': instance.birthDate?.toIso8601String(),
      'position': instance.position,
      'preferred_foot': instance.preferredFoot,
      'height_cm': instance.heightCm,
      'weight_kg': instance.weightKg,
      'role': instance.role,
      'guardian_name': instance.guardianName,
      'guardian_email': instance.guardianEmail,
      'is_verified': instance.isVerified,
      'verification_type': instance.verificationType,
      'coins': instance.coins,
      'stars': instance.stars,
      'level': instance.level,
      'iq_technique': instance.iqTechnique,
      'iq_creativity': instance.iqCreativity,
      'iq_popularity': instance.iqPopularity,
      'iq_consistency': instance.iqConsistency,
      'iq_tactical': instance.iqTactical,
      'streak_days': instance.streakDays,
      'last_login_date': instance.lastLoginDate?.toIso8601String(),
      'followers_count': instance.followersCount,
      'following_count': instance.followingCount,
      'videos_count': instance.videosCount,
      'moves_created_count': instance.movesCreatedCount,
      'likes_received_count': instance.likesReceivedCount,
      'challenges_won_count': instance.challengesWonCount,
    };
