import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

bool get developmentLoginEnabled =>
    kDebugMode &&
    const bool.fromEnvironment('LOCAL_DEVELOPMENT_ACCESS') &&
    (kIsWeb
        ? const {'localhost', '127.0.0.1', '::1'}.contains(Uri.base.host)
        : const bool.fromEnvironment('LOCAL_DEVELOPMENT_SIMULATOR'));

Future<void> signInToDevelopmentAccount(SupabaseClient client) async {
  if (!developmentLoginEnabled) throw StateError('Development login disabled');
  final response = await http
      .post(
        Uri.parse('http://127.0.0.1:8081/session'),
        headers: {
          'X-Juma-Development': '1',
          if (!kIsWeb) 'Origin': 'http://127.0.0.1:8080',
        },
      )
      .timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) throw StateError('Development login failed');
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  await client.auth.setSession(body['refresh_token'] as String);
}
