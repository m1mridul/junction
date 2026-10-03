import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientService {
  final _supabase = Supabase.instance.client;

  // ✅ Fetch All Clients
  Future<List<Map<String, dynamic>>> getClients() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('clients')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ✅ Add New Client
  Future<void> addClient({
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated!");

    try {
      await _supabase.from('clients').insert({
        'user_id': userId,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
      });
      debugPrint('Client added successfully!');
    } catch (e) {
      debugPrint('Supabase Client Insert Error: $e');
      rethrow;
    }
  }

  // ✅ Update Client
  Future<void> updateClient({
    required String clientId,
    String? name,
    String? phone,
    String? email,
    String? address,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated!");

    final Map<String, dynamic> updateData = {};
    if (name != null) updateData['name'] = name;
    if (phone != null) updateData['phone'] = phone;
    if (email != null) updateData['email'] = email;
    if (address != null) updateData['address'] = address;

    try {
      await _supabase
          .from('clients')
          .update(updateData)
          .eq('id', clientId)
          .eq('user_id', userId);
      debugPrint('Client updated successfully!');
    } catch (e) {
      debugPrint('Supabase Client Update Error: $e');
      rethrow;
    }
  }

  // ✅ Delete Client
  Future<void> deleteClient(String clientId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated!");

    try {
      await _supabase
          .from('clients')
          .delete()
          .eq('id', clientId)
          .eq('user_id', userId);
      debugPrint('Client deleted successfully!');
    } catch (e) {
      debugPrint('Supabase Client Delete Error: $e');
      rethrow;
    }
  }
}
