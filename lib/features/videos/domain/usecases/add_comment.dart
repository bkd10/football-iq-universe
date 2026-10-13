import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/video_comment.dart';
import '../repositories/video_repository.dart';

class AddComment {
  const AddComment(this._repository);

  final VideoRepository _repository;

  Future<Either<Failure, VideoComment>> call({
    required String videoId,
    required String content,
    String? parentId,
  }) {
    return _repository.addComment(
      videoId: videoId,
      content: content,
      parentId: parentId,
    );
  }
}
