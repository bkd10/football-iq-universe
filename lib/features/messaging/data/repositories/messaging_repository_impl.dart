import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../datasources/messaging_remote_datasource.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  const MessagingRepositoryImpl(this._remoteDataSource);

  final MessagingRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<Conversation>>> getConversations() async {
    try {
      final models = await _remoteDataSource.getConversations();
      return Right(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(
    String conversationId,
  ) async {
    try {
      final models = await _remoteDataSource.getMessages(conversationId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markConversationRead(
    String conversationId,
  ) async {
    try {
      await _remoteDataSource.markConversationRead(conversationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, String>> getGuardianApprovalToken(
    String conversationId,
  ) async {
    try {
      final token =
          await _remoteDataSource.getGuardianApprovalToken(conversationId);
      return Right(token);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String conversationId,
    required String body,
  }) async {
    try {
      await _remoteDataSource.sendMessage(
        conversationId: conversationId,
        body: body,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, String>> requestScoutContact(String playerId) async {
    try {
      final result = await _remoteDataSource.requestScoutContact(playerId);
      return Right(result['status'] as String);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> approveGuardianContact(String token) async {
    try {
      await _remoteDataSource.approveGuardianContact(token);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> declineGuardianContact(String token) async {
    try {
      await _remoteDataSource.declineGuardianContact(token);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
