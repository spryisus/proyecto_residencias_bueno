
import 'package:http/http.dart' as http;
import '../app/config/supabase_client.dart';

Future<bool> testSupabaseConnection() async {
  try {
    // Prueba básica usando la configuración centralizada
    final response = await http.get(
      Uri.parse('${AppSupabaseConfig.supabaseUrl}/auth/v1/settings'),
      headers: {
        'apikey': AppSupabaseConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${AppSupabaseConfig.supabaseAnonKey}',
      },
    ).timeout(Duration(seconds: 10));
    
    return response.statusCode == 200;
  } catch (e) {
    // ignore: avoid_print
    print('Error testing Supabase connection: $e');
    return false;
  }
}

