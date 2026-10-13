import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';

class UploadVideo {
  const UploadVideo(this._repository);

  final VideoRepository _repository;

  Future<Either<Failure, Video>> call({
    required XFile videoFile,
    required String caption,
    required String category,
    int? durationSeconds,
    bool isMove = false,
    String? moveName,
    String? originalMoveId,
    XFile? thumbnailFile,
  }) {
    return _repository.uploadVideo(
      videoFile: videoFile,
      caption: caption,
      category: category,
      durationSeconds: durationSeconds,
      isMove: isMove,
      moveName: moveName,
      originalMoveId: originalMoveId,
      thumbnailFile: thumbnailFile,
    );
  }
}
