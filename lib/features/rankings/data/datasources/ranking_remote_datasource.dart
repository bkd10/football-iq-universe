import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/constants/ranking_category.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/ranking_entry_model.dart';

class RankingRemoteDataSource {
  const RankingRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<List<RankingEntryModel>> getRankings({
    required String category,
    String? country,
    String? city,
    int limit = 50,
  }) async {
    final column = RankingCategory.columns[category] ?? 'stars';

    try {
      final baseQuery = _client
          .from('profiles')
          .select('id, username, display_name, avatar_url, level, country, city, score:$column')
          // Recruteurs, marques et admins n'ont pas leur place au classement.
          .eq('role', 'player');

      final withCountry = country != null ? baseQuery.eq('country', country) : baseQuery;
      final withCity = city != null ? withCountry.eq('city', city) : withCountry;

      final rows = await withCity.order(column, ascending: false).limit(limit);

      return rows
          .map((row) => RankingEntryModel.fromJson(row))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
