import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HearingService {
  final _supabase = Supabase.instance.client;

  // ✅ 1. Fetch all hearings for a specific case
  Future<List<Map<String, dynamic>>> getHearingsByCaseId(String caseId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('hearing_history')
          .select()
          .eq('case_id', caseId)
          .eq('user_id', userId)
          .order('hearing_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Fetch Hearings Error: $e');
      rethrow;
    }
  }

  // ✅ 2. Add hearing record & update next_hearing_date in cases table
  Future<void> addHearing({
    required String caseId,
    required DateTime hearingDate,
    String? stageNote,
    String? courtOrder,
    DateTime? nextDate,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated!");

    final Map<String, dynamic> insertData = {
      'user_id': userId,
      'case_id': caseId,
      'hearing_date': hearingDate.toIso8601String(),
      'stage_note': stageNote,
      'court_order': courtOrder,
    };

    if (nextDate != null) {
      insertData['next_date'] = nextDate.toIso8601String();
    }

    try {
      // Hearing record insert
      await _supabase.from('hearing_history').insert(insertData);

      // ✅ Automatic case's next_hearing_date update
      if (nextDate != null) {
        await _supabase
            .from('cases')
            .update({
              'next_hearing_date': nextDate.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', caseId)
            .eq('user_id', userId);
      }
    } catch (e) {
      debugPrint('Add Hearing Error: $e');
      rethrow;
    }
  }

  // ✅ 3. Update hearing record
  Future<void> updateHearing({
    required String hearingId,
    String? stageNote,
    String? courtOrder,
    DateTime? nextDate,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated!");

    final Map<String, dynamic> updateData = {};
    if (stageNote != null) updateData['stage_note'] = stageNote;
    if (courtOrder != null) updateData['court_order'] = courtOrder;
    if (nextDate != null) updateData['next_date'] = nextDate.toIso8601String();

    if (updateData.isEmpty) return;

    try {
      await _supabase
          .from('hearing_history')
          .update(updateData)
          .eq('id', hearingId)
          .eq('user_id', userId);
      debugPrint('Hearing updated successfully!');
    } catch (e) {
      debugPrint('Update Hearing Error: $e');
      rethrow;
    }
  }

  // ✅ 4. Delete hearing record
  Future<void> deleteHearing(String hearingId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated!");

    try {
      await _supabase
          .from('hearing_history')
          .delete()
          .eq('id', hearingId)
          .eq('user_id', userId);
      debugPrint('Hearing deleted successfully!');
    } catch (e) {
      debugPrint('Delete Hearing Error: $e');
      rethrow;
    }
  }
}
