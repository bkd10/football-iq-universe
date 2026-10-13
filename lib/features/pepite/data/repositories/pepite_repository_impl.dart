import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/pepite_of_the_day.dart';
import '../../domain/repositories/pepite_repository.dart';
import '../datasources/pepite_remote_datasource.dart';

class PepiteRepositoryImpl implements PepiteRepository {
  const PepiteRepositoryImpl(this._remoteDataSource);

  final PepiteRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, PepiteOfTheDay?>> getPepiteOfTheDay() async {
    try {
      final model = await _remoteDataSource.getPepiteOfTheDay();
      return Right(model?.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
