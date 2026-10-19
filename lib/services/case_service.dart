import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaseService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCases() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('cases')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> cases =
        List<Map<String, dynamic>>.from(response);

    for (var i = 0; i < cases.length; i++) {
      final clientId = cases[i]['client_id'];
      if (clientId != null) {
        try {
          final clientResponse = await _supabase
              .from('clients')
              .select('name')
              .eq('id', clientId)
              .maybeSingle();
          if (clientResponse != null) {
            cases[i]['clients'] = clientResponse;
          }
        } catch (e) {
          debugPrint('Error fetching client for case: $e');
        }
      }
    }
    return cases;
  }

  Future<Map<String, dynamic>?> getCaseById(String caseId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('cases')
        .select()
        .eq('id', caseId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    final Map<String, dynamic> caseData = Map<String, dynamic>.from(response);

    final clientId = caseData['client_id'];
    if (clientId != null) {
      try {
        final clientResponse = await _supabase
            .from('clients')
            .select()
            .eq('id', clientId)
            .maybeSingle();
        if (clientResponse != null) {
          caseData['clients'] = clientResponse;
        }
      } catch (e) {
        debugPrint('Error fetching client: $e');
      }
    }
    return caseData;
  }

  Future<Map<String, dynamic>?> getClientById(String clientId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('clients')
          .select()
          .eq('id', clientId)
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Fetch Client Error: $e');
      return null;
    }
  }

  Future<void> addCase({
    required String clientId,
    required String caseNumber,
    required String title,
    required String courtName,
    required String caseType,
    required String status,
    DateTime? nextHearingDate,
    DateTime? filingDate,
    String? oppositeParty,
    String? notes,
    String? judgeName,
    String? currentStage,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated!");

    final Map<String, dynamic> insertData = {
      'user_id': userId,
      'client_id': clientId,
      'case_number': caseNumber,
      'title': title,
      'court_name': courtName,
      'case_type': caseType,
      'status': status,
      'opposite_party': oppositeParty,
      'notes': notes,
      'judge_name': judgeName,
      'current_stage': currentStage,
    };

    if (nextHearingDate != null) {
      insertData['next_hearing_date'] =
          nextHearingDate.toUtc().toIso8601String();
    }
    // ✅ ফাইলিং ডেট
    if (filingDate != null) {
      // ✅ শুধু তারিখ (Date) হিসেবে সেভ করি, UTC কনভার্ট করি না
      insertData['filing_date'] =
          DateTime(filingDate.year, filingDate.month, filingDate.day)
              .toIso8601String();
    }

    try {
      await _supabase.from('cases').insert(insertData);
      debugPrint('Case inserted successfully!');
    } catch (e) {
      debugPrint('Supabase Case Insert Error: $e');
      rethrow;
    }
  }

  Future<void> updateCase({
    required String caseId,
    String? clientId,
    String? caseNumber,
    String? title,
    String? courtName,
    String? caseType,
    String? status,
    DateTime? nextHearingDate,
    DateTime? filingDate,
    String? oppositeParty,
    String? notes,
    String? judgeName,
    String? currentStage,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated!");

    final Map<String, dynamic> updateData = {};
    if (clientId != null) updateData['client_id'] = clientId;
    if (caseNumber != null) updateData['case_number'] = caseNumber;
    if (title != null) updateData['title'] = title;
    if (courtName != null) updateData['court_name'] = courtName;
    if (caseType != null) updateData['case_type'] = caseType;
    if (status != null) updateData['status'] = status;
    if (oppositeParty != null) updateData['opposite_party'] = oppositeParty;
    if (notes != null) updateData['notes'] = notes;
    if (judgeName != null) updateData['judge_name'] = judgeName;
    if (currentStage != null) updateData['current_stage'] = currentStage;
    if (nextHearingDate != null) {
      updateData['next_hearing_date'] =
          nextHearingDate.toUtc().toIso8601String();
    }
    // ✅ ফাইলিং ডেট
    if (filingDate != null) {
      // ✅ শুধু তারিখ (Date) হিসেবে সেভ করি, UTC কনভার্ট করি না
      updateData['filing_date'] =
          DateTime(filingDate.year, filingDate.month, filingDate.day)
              .toIso8601String();
    }

    try {
      await _supabase
          .from('cases')
          .update(updateData)
          .eq('id', caseId)
          .eq('user_id', userId);
      debugPrint('Case updated successfully!');
    } catch (e) {
      debugPrint('Supabase Case Update Error: $e');
      rethrow;
    }
  }

  Future<void> deleteCase(String caseId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated!");

    try {
      await _supabase
          .from('cases')
          .delete()
          .eq('id', caseId)
          .eq('user_id', userId);
      debugPrint('Case deleted successfully!');
    } catch (e) {
      debugPrint('Supabase Case Delete Error: $e');
      rethrow;
    }
  }
}
