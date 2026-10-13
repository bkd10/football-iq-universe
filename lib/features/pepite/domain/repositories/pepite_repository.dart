import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/pepite_of_the_day.dart';

abstract class PepiteRepository {
  Future<Either<Failure, PepiteOfTheDay?>> getPepiteOfTheDay();
}
