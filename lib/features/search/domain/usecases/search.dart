import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/search_results.dart';
import '../repositories/search_repository.dart';

class Search {
  const Search(this._repository);

  final SearchRepository _repository;

  Future<Either<Failure, SearchResults>> call(String query) => _repository.search(query);
}
