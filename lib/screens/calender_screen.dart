import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _todayHearings = [];

  @override
  void initState() {
    super.initState();
    _fetchTodayHearings();
  }

  Future<void> _fetchTodayHearings() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final now = DateTime.now();
        final startOfDay =
            DateTime(now.year, now.month, now.day).toIso8601String();
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59)
            .toIso8601String();

        final resp = await _supabase
            .from('cases')
            .select()
            .eq('user_id', userId)
            .gte('next_hearing_date', startOfDay)
            .lte('next_hearing_date', endOfDay)
            .order('next_hearing_date', ascending: true);

        setState(() {
          _todayHearings = List<Map<String, dynamic>>.from(resp);
        });
      }
    } catch (e) {
      debugPrint("Error fetching today's hearings: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ক্যালেন্ডার'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5B25D)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'আজকের কার্যসূচি',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5B25D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_todayHearings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2C3E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Center(
                        child: Text(
                          'আজ কোনো শুনানি নেই',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ..._todayHearings
                        .map((caseData) => _buildHearingCard(caseData)),
                ],
              ),
            ),
    );
  }

  Widget _buildHearingCard(Map<String, dynamic> caseData) {
    final caseType = caseData['case_type'] ?? '';
    final caseNumber = caseData['case_number'] ?? '';
    final courtName = caseData['court_name'] ?? '';
    final nextHearing = caseData['next_hearing_date'];

    String timeText = '';
    if (nextHearing != null) {
      try {
        final dt = DateTime.parse(nextHearing).toLocal();
        final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
        timeText = '$hour:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2C3E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$caseType মামলা নং $caseNumber',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_city, color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  courtName,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Text(
                timeText.isNotEmpty
                    ? 'সময়: $timeText'
                    : 'সময় নির্ধারিত হয়নি',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
