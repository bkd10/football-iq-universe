import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../../core/errors/exceptions.dart';
import '../models/coin_transaction_model.dart';

/// Appelle les RPC serveur `award_coins`/`spend_coins` (voir
/// `supabase/migrations/20260101000005_economy_rpc.sql`) — équivalent SQL
/// des Edge Functions décrites en PARTIE 4.2. Le client ne calcule jamais
/// lui-même un solde : il reçoit `new_balance` en retour de la fonction.
class EconomyRemoteDataSource {
  const EconomyRemoteDataSource(this._client);

  final supa.SupabaseClient _client;

  Future<int> awardCoins({required String reason, String? referenceId}) async {
    try {
      final result = await _client.rpc<Map<String, dynamic>>(
        'award_coins',
        params: {
          'p_reason': reason,
          if (referenceId != null) 'p_reference_id': referenceId,
          // Date calendaire LOCALE de l'appareil (pas UTC) : le serveur
          // s'en sert comme "aujourd'hui" pour la série de connexion et
          // les plafonds quotidiens, pour ne pas casser une série à tort
          // à cause d'un décalage avec le fuseau du serveur.
          'p_local_date': _localDateString(),
        },
      );
      return result['new_balance'] as int;
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<int> spendCoins({
    required String reason,
    required int amount,
    String? referenceId,
  }) async {
    try {
      final result = await _client.rpc<Map<String, dynamic>>(
        'spend_coins',
        params: {
          'p_reason': reason,
          'p_amount': amount,
          if (referenceId != null) 'p_reference_id': referenceId,
        },
      );
      return result['new_balance'] as int;
    } on supa.PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<CoinTransactionModel>> getTransactions({int limit = 30}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Connecte-toi pour voir ton portefeuille.');
    }

    try {
      final rows = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('currency', 'coins')
          .order('created_at', ascending: false)
          .limit(limit);

      return rows
          .map((row) => CoinTransactionModel.fromJson(row))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Date calendaire locale de l'appareil au format `YYYY-MM-DD`, utilisée
  /// par le serveur comme référence de "jour" (voir
  /// `20260101000017_local_timezone_daily_resets.sql`). Volontairement basé
  /// sur `DateTime.now()` (heure locale) et non `.toUtc()`.
  String _localDateString() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  /// Traduit les exceptions PL/pgSQL (`raise exception ... using errcode`)
  /// en exceptions applicatives typées. Le "code 28000" est réservé à
  /// l'absence de session ; tout le reste est une règle métier (P0001) dont
  /// on distingue le type par le message, faute de codes dédiés côté SQL.
  Exception _mapRpcError(supa.PostgrestException e) {
    if (e.code == '28000') {
      return AuthException(e.message);
    }
    if (e.message.contains('insuffisant')) {
      return InsufficientCoinsException(e.message);
    }
    if (e.message.toLowerCase().contains('limite') ||
        e.message.toLowerCase().contains('déjà réclamée')) {
      return DailyLimitException(e.message);
    }
    return ServerException(e.message);
  }
}
