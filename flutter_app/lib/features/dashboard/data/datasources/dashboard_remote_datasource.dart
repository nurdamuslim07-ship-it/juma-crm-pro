import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_summary_model.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._client);
  final SupabaseClient _client;

  Future<DashboardSummaryModel> getSummary() async {
    final rows = await _client.rpc('dashboard_summary') as List;
    if (rows.isEmpty) return DashboardSummaryModel.empty;
    return DashboardSummaryModel.fromRow(rows.first as Map<String, dynamic>);
  }
}
