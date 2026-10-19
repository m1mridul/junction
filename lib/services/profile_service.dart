import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  // ✅ প্রোফাইল আনা
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Fetch Profile Error: $e');
      return null;
    }
  }

  // ✅ প্রোফাইল আপডেট
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? address,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated!");

    final Map<String, dynamic> updateData = {};
    if (fullName != null) updateData['full_name'] = fullName;
    if (phone != null) updateData['phone'] = phone;
    if (address != null) updateData['address'] = address;

    if (updateData.isEmpty) return;

    try {
      await _supabase.from('profiles').update(updateData).eq('id', userId);
      debugPrint('Profile updated successfully!');
    } catch (e) {
      debugPrint('Update Profile Error: $e');
      rethrow;
    }
  }
}
