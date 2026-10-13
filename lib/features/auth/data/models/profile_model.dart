import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/profile.dart';

part 'profile_model.g.dart';

/// Colonnes de `profiles` lisibles par tout le monde. `birth_date` n'y est
/// volontairement pas : la base refuse de la renvoyer aux autres
/// utilisateurs (voir `20260101000021_security_audit_fixes.sql`). Un
/// `select()` sans liste (`*`) échouerait donc avec une erreur de droits.
/// Le joueur lit son propre profil complet via la RPC `get_my_profile`.
const kPublicProfileColumns = 'id, username, display_name, avatar_url, bio, '
    'country, city, position, preferred_foot, height_cm, weight_kg, role, '
    'is_verified, verification_type, coins, stars, level, iq_technique, '
    'iq_creativity, iq_popularity, iq_consistency, iq_tactical, streak_days, '
    'last_login_date, followers_count, following_count, videos_count, '
    'moves_created_count, likes_received_count, challenges_won_count, '
    'created_at, updated_at';

/// Représentation JSON de la table `profiles`. Fait le pont entre les
/// colonnes `snake_case` de Postgres et l'entité `Profile` (camelCase) du
/// domain — le domain ne doit jamais connaître la forme du JSON brut.
@JsonSerializable(fieldRename: FieldRename.snake)
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.avatarUrl,
    this.bio = '',
    this.country,
    this.city,
    this.birthDate,
    this.position,
    this.preferredFoot = 'droit',
    this.heightCm,
    this.weightKg,
    this.role = 'player',
    this.guardianName,
    this.guardianEmail,
    this.isVerified = false,
    this.verificationType,
    this.coins = 500,
    this.stars = 0,
    this.level = 'rookie',
    this.iqTechnique = 0,
    this.iqCreativity = 0,
    this.iqPopularity = 0,
    this.iqConsistency = 0,
    this.iqTactical = 0,
    this.streakDays = 0,
    this.lastLoginDate,
    this.followersCount = 0,
    this.followingCount = 0,
    this.videosCount = 0,
    this.movesCreatedCount = 0,
    this.likesReceivedCount = 0,
    this.challengesWonCount = 0,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);

  final String id;
  final String username;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? displayName;
  final String? avatarUrl;
  final String bio;
  final String? country;
  final String? city;
  final DateTime? birthDate;
  final String? position;
  final String preferredFoot;
  final int? heightCm;
  final int? weightKg;
  final String role;
  final String? guardianName;
  final String? guardianEmail;
  final bool isVerified;
  final String? verificationType;
  final int coins;
  final int stars;
  final String level;
  final int iqTechnique;
  final int iqCreativity;
  final int iqPopularity;
  final int iqConsistency;
  final int iqTactical;
  final int streakDays;
  final DateTime? lastLoginDate;
  final int followersCount;
  final int followingCount;
  final int videosCount;
  final int movesCreatedCount;
  final int likesReceivedCount;
  final int challengesWonCount;

  Profile toEntity() {
    return Profile(
      id: id,
      username: username,
      createdAt: createdAt,
      updatedAt: updatedAt,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      country: country,
      city: city,
      birthDate: birthDate,
      position: position,
      preferredFoot: preferredFoot,
      heightCm: heightCm,
      weightKg: weightKg,
      role: role,
      guardianName: guardianName,
      guardianEmail: guardianEmail,
      isVerified: isVerified,
      verificationType: verificationType,
      coins: coins,
      stars: stars,
      level: level,
      iqTechnique: iqTechnique,
      iqCreativity: iqCreativity,
      iqPopularity: iqPopularity,
      iqConsistency: iqConsistency,
      iqTactical: iqTactical,
      streakDays: streakDays,
      lastLoginDate: lastLoginDate,
      followersCount: followersCount,
      followingCount: followingCount,
      videosCount: videosCount,
      movesCreatedCount: movesCreatedCount,
      likesReceivedCount: likesReceivedCount,
      challengesWonCount: challengesWonCount,
    );
  }
}
