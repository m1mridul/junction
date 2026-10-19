import 'package:flutter/material.dart';
import '../services/hearing_service.dart';
import '../services/case_service.dart';
import 'case_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  final HearingService _hearingService = HearingService();
  final CaseService _caseService = CaseService();

  List<Map<String, dynamic>> _allHearings = [];
  List<Map<String, dynamic>> _selectedDateHearings = [];
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  // ✅ সপ্তাহের দিন (রবি প্রথমে - বাংলাদেশ স্ট্যান্ডার্ড)
  final List<String> _weekDays = [
    'রবি',
    'সোম',
    'মঙ্গল',
    'বুধ',
    'বৃহঃ',
    'শুক্র',
    'শনি'
  ];

  // ✅ বাংলা মাস
  final List<String> _bengaliMonths = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllHearings();
  }

  // ✅ আজকের তারিখে রিসেট
  void resetToToday() {
    if (!mounted) return;
    setState(() {
      _selectedDate = DateTime.now();
      _currentMonth = DateTime.now();
    });
    _filterHearingsForDate(_selectedDate);
    _fetchAllHearings();
  }

  // ✅ সব শুনানি আনা (hearing_history + cases.next_hearing_date)
  Future<void> _fetchAllHearings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // ১. hearing_history থেকে সব শুনানি
      final hearingData = await _hearingService.getAllHearings();

      // ২. cases থেকে সব কেস (next_hearing_date সহ)
      final caseData = await _caseService.getCases();

      // ৩. উভয় সোর্স একত্রিত করা
      final List<Map<String, dynamic>> combinedHearings = [];

      // hearing_history থেকে
      for (final h in hearingData) {
        combinedHearings.add({
          'id': h['id'],
          'hearing_date': h['hearing_date'],
          'stage_note': h['stage_note'],
          'court_order': h['court_order'],
          'next_date': h['next_date'],
          'case_id': h['case_id'],
          'cases': h['cases'],
          'source': 'history',
        });
      }

      // cases থেকে next_hearing_date
      for (final c in caseData) {
        if (c['next_hearing_date'] != null) {
          combinedHearings.add({
            'id': 'case_${c['id']}',
            'hearing_date': c['next_hearing_date'],
            'stage_note': 'পরবর্তী শুনানি নির্ধারিত',
            'court_order': null,
            'next_date': null,
            'case_id': c['id'],
            'cases': {
              'case_number': c['case_number'],
              'title': c['title'],
              'court_name': c['court_name'],
              'case_type': c['case_type'],
            },
            'source': 'case',
          });
        }
      }

      if (mounted) {
        setState(() {
          _allHearings = combinedHearings;
          _isLoading = false;
        });
        _filterHearingsForDate(_selectedDate);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('শুনানি লোড ব্যর্থ: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ নির্দিষ্ট তারিখের শুনানি ফিল্টার (ডুপ্লিকেট ফিল্টার সহ)
  void _filterHearingsForDate(DateTime date) {
    if (!mounted) return;

    final filtered = _allHearings.where((h) {
      final hearingDate = h['hearing_date'];
      if (hearingDate == null) return false;
      try {
        final dt = DateTime.parse(hearingDate).toLocal();
        return dt.year == date.year &&
            dt.month == date.month &&
            dt.day == date.day;
      } catch (_) {
        return false;
      }
    }).toList();

    final List<Map<String, dynamic>> uniqueHearings = [];
    final Set<String> seen = {};

    for (final h in filtered) {
      final caseId = h['case_id'] ?? '';
      final hearingDate = h['hearing_date'] ?? '';
      String dayKey = '';
      try {
        final dt = DateTime.parse(hearingDate).toLocal();
        dayKey = '${dt.year}-${dt.month}-${dt.day}';
      } catch (_) {}

      final key = '$caseId-$dayKey';

      if (!seen.contains(key)) {
        seen.add(key);
        uniqueHearings.add(h);
      } else {
        // history কে প্রাধান্য দেওয়া
        if (h['source'] == 'history') {
          final index = uniqueHearings.indexWhere((item) {
            final itemCaseId = item['case_id'] ?? '';
            final itemDate = item['hearing_date'] ?? '';
            String itemDayKey = '';
            try {
              final dt = DateTime.parse(itemDate).toLocal();
              itemDayKey = '${dt.year}-${dt.month}-${dt.day}';
            } catch (_) {}
            return '$itemCaseId-$itemDayKey' == key;
          });
          if (index != -1) {
            uniqueHearings[index] = h;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _selectedDateHearings = uniqueHearings;
      });
    }
  }

  // ✅ কেস টাইপ অনুযায়ী আইকন
  IconData _getCaseIcon(String caseType) {
    switch (caseType) {
      case 'দেওয়ানি':
        return Icons.description;
      case 'ফৌজদারি':
        return Icons.gavel;
      case 'পারিবারিক':
        return Icons.family_restroom;
      case 'জমি সংক্রান্ত':
        return Icons.landscape;
      default:
        return Icons.folder;
    }
  }

  // ✅ কেস টাইপ অনুযায়ী কালার
  Color _getCaseColor(String caseType) {
    switch (caseType) {
      case 'দেওয়ানি':
        return Colors.orangeAccent;
      case 'ফৌজদারি':
        return Colors.redAccent;
      case 'পারিবারিক':
        return Colors.purpleAccent;
      case 'জমি সংক্রান্ত':
        return Colors.greenAccent;
      default:
        return const Color(0xFFE5B25D);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_bengaliMonths[date.month - 1]} ${date.year}';
  }

  // ✅ সময় ফরম্যাট
  String _formatTime(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      return '$hour:${dt.minute.toString().padLeft(2, '0')} টায়';
    } catch (_) {
      return '';
    }
  }

  bool _hasHistoryHearingOnDate(DateTime date) {
    return _allHearings.any((h) {
      if (h['source'] != 'history') return false;
      final hearingDate = h['hearing_date'];
      if (hearingDate == null) return false;
      try {
        final dt = DateTime.parse(hearingDate).toLocal();
        return dt.year == date.year &&
            dt.month == date.month &&
            dt.day == date.day;
      } catch (_) {
        return false;
      }
    });
  }

  bool _hasCaseHearingOnDate(DateTime date) {
    return _allHearings.any((h) {
      if (h['source'] != 'case') return false;
      final hearingDate = h['hearing_date'];
      if (hearingDate == null) return false;
      try {
        final dt = DateTime.parse(hearingDate).toLocal();
        return dt.year == date.year &&
            dt.month == date.month &&
            dt.day == date.day;
      } catch (_) {
        return false;
      }
    });
  }

  void _changeMonth(int delta) {
    if (!mounted) return;
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ক্যালেন্ডার'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'আপনার সকল তারিখ ও শুনানির সময়সূচি',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5B25D)))
          : Column(
              children: [
                // ✅ ক্যালেন্ডার সেকশন
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2C3E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5B25D).withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE5B25D).withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left,
                                color: Color(0xFFE5B25D)),
                            onPressed: () => _changeMonth(-1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Text(
                            '${_bengaliMonths[_currentMonth.month - 1]} ${_currentMonth.year}',
                            style: const TextStyle(
                              color: Color(0xFFE5B25D),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right,
                                color: Color(0xFFE5B25D)),
                            onPressed: () => _changeMonth(1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (i) {
                          return SizedBox(
                            width: 32,
                            child: Text(
                              _weekDays[i],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      _buildCalendarGrid(),
                    ],
                  ),
                ),
                // ✅ আজকের কার্যসূচি
                Expanded(
                  child: Container(
                    color: const Color(0xFF032836),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isSameDay(_selectedDate, DateTime.now())
                                    ? 'আজকের কার্যসূচি'
                                    : '${_formatDate(_selectedDate)}',
                                style: const TextStyle(
                                  color: Color(0xFFE5B25D),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'সব শুনানি দেখার ফিচার শীঘ্রই আসছে')),
                                  );
                                },
                                child: Row(
                                  children: [
                                    const Text('সব দেখুন',
                                        style: TextStyle(
                                            color: Color(0xFFE5B25D),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios,
                                        color: const Color(0xFFE5B25D)
                                            .withValues(alpha: 0.7),
                                        size: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _selectedDateHearings.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.event_busy,
                                          size: 64, color: Colors.white24),
                                      SizedBox(height: 12),
                                      Text('এই দিনে কোনো শুনানি নেই',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 14)),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchAllHearings,
                                  color: const Color(0xFFE5B25D),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: _selectedDateHearings.length,
                                    itemBuilder: (ctx, index) {
                                      final hearing =
                                          _selectedDateHearings[index];
                                      return _buildHearingCard(hearing);
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final totalDays = lastDayOfMonth.day;
    final leadingEmpty = firstWeekday;
    final totalCells = leadingEmpty + totalDays;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (colIndex) {
            final cellIndex = rowIndex * 7 + colIndex;
            final dayNumber = cellIndex - leadingEmpty + 1;

            if (dayNumber < 1 || dayNumber > totalDays) {
              return const SizedBox(width: 32, height: 36);
            }

            final date =
                DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
            final isSelected = _isSameDay(date, _selectedDate);
            final isToday = _isSameDay(date, DateTime.now());
            final hasHistory = _hasHistoryHearingOnDate(date);
            final hasCase = _hasCaseHearingOnDate(date);
            final hasHearing = hasHistory || hasCase;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
                _filterHearingsForDate(date);
              },
              child: Container(
                width: 32,
                height: 36,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE5B25D)
                      : isToday
                          ? const Color(0xFFE5B25D).withValues(alpha: 0.2)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday && !isSelected
                      ? Border.all(color: const Color(0xFFE5B25D), width: 1)
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        color:
                            isSelected ? const Color(0xFF032836) : Colors.white,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (hasHearing)
                      Positioned(
                        bottom: 3,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasHistory)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF032836)
                                      : const Color(0xFFE5B25D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (hasCase) ...[
                              if (hasHistory) const SizedBox(width: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF032836)
                                      : Colors.lightBlueAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildHearingCard(Map<String, dynamic> hearing) {
    final caseData = hearing['cases'] as Map<String, dynamic>?;
    final caseNumber = caseData?['case_number'] ?? '';
    final caseTitle = caseData?['title'] ?? '';
    final courtName = caseData?['court_name'] ?? '';
    final caseType = caseData?['case_type'] ?? 'অন্যান্য';
    final stageNote = hearing['stage_note'] ?? '';
    final hearingTime = _formatTime(hearing['hearing_date']);
    final isFromCase = hearing['source'] == 'case';

    final icon = _getCaseIcon(caseType);
    final iconColor = _getCaseColor(caseType);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF0F2C3E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isFromCase
              ? const Color(0xFFE5B25D).withValues(alpha: 0.3)
              : Colors.white12,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          if (caseData != null) {
            // ✅ ডেটাবেস থেকে সম্পূর্ণ কেস ডেটা (client_id সহ) নিয়ে আসি
            final fullCaseData =
                await _caseService.getCaseById(hearing['case_id']);

            if (fullCaseData != null && mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CaseDetailScreen(caseData: fullCaseData),
                ),
              );
              _fetchAllHearings();
            } else {
              // ফলব্যাক
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CaseDetailScreen(caseData: {
                    'id': hearing['case_id'],
                    ...caseData,
                  }),
                ),
              );
              _fetchAllHearings();
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$caseType মামলা নং $caseNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFromCase)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5B25D)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'আসন্ন',
                              style: TextStyle(
                                color: Color(0xFFE5B25D),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (caseTitle.isNotEmpty)
                      Text(
                        caseTitle,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_city,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            courtName,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'শুনানির তারিখ: ${_formatDate(DateTime.parse(hearing['hearing_date']).toLocal())}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (hearingTime.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              color: Colors.white38, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'সময়: $hearingTime',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    if (stageNote.isNotEmpty && !isFromCase) ...[
                      const SizedBox(height: 4),
                      Text(
                        'স্টেজ: $stageNote',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white38, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
