// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotificationModel _$AppNotificationModelFromJson(
        Map<String, dynamic> json) =>
    AppNotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      body: json['body'] as String?,
      actorId: json['actor_id'] as String?,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      actor: json['actor'] == null
          ? null
          : NotificationActorModel.fromJson(
              json['actor'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppNotificationModelToJson(
        AppNotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'created_at': instance.createdAt.toIso8601String(),
      'is_read': instance.isRead,
      'body': instance.body,
      'actor_id': instance.actorId,
      'reference_type': instance.referenceType,
      'reference_id': instance.referenceId,
      'actor': instance.actor?.toJson(),
    };

NotificationActorModel _$NotificationActorModelFromJson(
        Map<String, dynamic> json) =>
    NotificationActorModel(
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$NotificationActorModelToJson(
        NotificationActorModel instance) =>
    <String, dynamic>{
      'username': instance.username,
      'avatar_url': instance.avatarUrl,
    };
