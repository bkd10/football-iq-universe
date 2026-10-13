import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/exceptions.dart';
import '../models/pepite_of_the_day_model.dart';

class PepiteRemoteDataSource {
  const PepiteRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<PepiteOfTheDayModel?> getPepiteOfTheDay() async {
    try {
      final rows = await _client.rpc<List<dynamic>>('get_pepite_of_the_day');
      if (rows.isEmpty) return null;
      return PepiteOfTheDayModel.fromJson(rows.first as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
