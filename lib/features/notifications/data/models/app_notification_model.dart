import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/app_notification.dart';

part 'app_notification_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.isRead = false,
    this.body,
    this.actorId,
    this.referenceType,
    this.referenceId,
    this.actor,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationModelFromJson(json);

  final String id;
  final String type;
  final String title;
  final DateTime createdAt;
  final bool isRead;
  final String? body;
  final String? actorId;
  final String? referenceType;
  final String? referenceId;
  @JsonKey(name: 'actor')
  final NotificationActorModel? actor;

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      createdAt: createdAt,
      isRead: isRead,
      body: body,
      actorId: actorId,
      actorUsername: actor?.username,
      actorAvatarUrl: actor?.avatarUrl,
      referenceType: referenceType,
      referenceId: referenceId,
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class NotificationActorModel {
  const NotificationActorModel({required this.username, this.avatarUrl});

  factory NotificationActorModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationActorModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationActorModelToJson(this);

  final String username;
  final String? avatarUrl;
}
