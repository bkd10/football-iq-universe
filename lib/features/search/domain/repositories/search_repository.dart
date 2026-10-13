import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/search_results.dart';

abstract class SearchRepository {
  Future<Either<Failure, SearchResults>> search(String query);
}
