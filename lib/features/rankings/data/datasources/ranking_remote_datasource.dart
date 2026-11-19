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
      // `get_rankings` : recruteurs, marques, admins et bannis exclus ; la
      // ville d'un joueur qui la masque (mineurs par défaut) n'est ni
      // affichée, ni utilisée pour le classement de sa ville.
      final rows = await _client.rpc<List<dynamic>>('get_rankings', params: {
        'p_category': column,
        'p_country': country,
        'p_city': city,
        'p_limit': limit,
      },);

      return rows
          .map((row) => RankingEntryModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
