import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/pepite_of_the_day.dart';
import '../repositories/pepite_repository.dart';

class GetPepiteOfTheDay {
  const GetPepiteOfTheDay(this._repository);

  final PepiteRepository _repository;

  Future<Either<Failure, PepiteOfTheDay?>> call() => _repository.getPepiteOfTheDay();
}
