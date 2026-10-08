import 'package:flutter/material.dart';
import '../services/hearing_service.dart';
import '../services/case_service.dart';
import 'edit_case_screen.dart';
import 'edit_hearing_screen.dart';

class CaseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;

  const CaseDetailScreen({super.key, required this.caseData});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final HearingService _hearingService = HearingService();
  final CaseService _caseService = CaseService();

  late Map<String, dynamic> _currentCaseData;

  List<Map<String, dynamic>> _hearings = [];
  bool _isLoadingHearings = true;

  @override
  void initState() {
    super.initState();
    _currentCaseData = Map<String, dynamic>.from(widget.caseData);
    _fetchHearings();
  }

  // ✅ বাংলা মাস
  String _getBengaliMonth(int month) {
    const months = [
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
    return months[month - 1];
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'নির্ধারিত হয়নি';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day} ${_getBengaliMonth(dt.month)} ${dt.year}';
    } catch (_) {
      return 'নির্ধারিত হয়নি';
    }
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    return '${dt.day} ${_getBengaliMonth(dt.month)} ${dt.year}, $hour:${dt.minute.toString().padLeft(2, '0')} টায়';
  }

  Future<void> _fetchHearings() async {
    setState(() => _isLoadingHearings = true);
    try {
      final data =
          await _hearingService.getHearingsByCaseId(_currentCaseData['id']);
      setState(() {
        _hearings = data;
        _isLoadingHearings = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('শুনানির ইতিহাস লোড ব্যর্থ: $e')),
        );
      }
      setState(() => _isLoadingHearings = false);
    }
  }

  // ✅ স্ট্যাটাস লেবেল ও কালার
  String _getStatusLabel(String status) {
    switch (status) {
      case 'Active':
        return 'চলমান';
      case 'Pending':
        return 'বিচারাধীন';
      case 'Disposed':
        return 'নিষ্পত্তি';
      case 'Closed':
        return 'বন্ধ';
      case 'Appealed':
        return 'আপিলকৃত';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.redAccent;
      case 'Pending':
        return Colors.orangeAccent;
      case 'Disposed':
        return Colors.greenAccent;
      case 'Closed':
        return Colors.grey;
      case 'Appealed':
        return Colors.blueAccent;
      default:
        return Colors.white54;
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

  // ✅ ডিলিট কনফার্মেশন
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2C3E),
        title: const Text(
          'মামলা ডিলিট করবেন?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'এই মামলাটি এবং এর সব শুনানির রেকর্ড স্থায়ীভাবে মুছে যাবে। এটি ফিরিয়ে আনা যাবে না।',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'বাতিল',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'ডিলিট করুন',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _caseService.deleteCase(_currentCaseData['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('মামলা সফলভাবে ডিলিট হয়েছে')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ডিলিট ব্যর্থ: $e')),
        );
      }
    }
  }

  // ✅ এডিট স্ক্রিনে নেভিগেট
  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditCaseScreen(caseData: _currentCaseData),
      ),
    );

    if (result == true && mounted) {
      try {
        final updatedCase =
            await _caseService.getCaseById(_currentCaseData['id']);
        if (updatedCase != null && mounted) {
          setState(() {
            _currentCaseData = updatedCase;
          });
        }
      } catch (e) {
        debugPrint('Error refreshing case: $e');
      }
    }
  }

  // ✅ শুনানি ডিলিট কনফার্মেশন
  Future<void> _confirmDeleteHearing(Map<String, dynamic> hearing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F2C3E),
        title: const Text(
          'শুনানি ডিলিট করবেন?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'এই শুনানির রেকর্ড স্থায়ীভাবে মুছে যাবে। এটি ফিরিয়ে আনা যাবে না।',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'বাতিল',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'ডিলিট করুন',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _hearingService.deleteHearing(hearing['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('শুনানি সফলভাবে ডিলিট হয়েছে')),
        );
        _fetchHearings();
        final updatedCase =
            await _caseService.getCaseById(_currentCaseData['id']);
        if (updatedCase != null && mounted) {
          setState(() => _currentCaseData = updatedCase);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ডিলিট ব্যর্থ: $e')),
        );
      }
    }
  }

  // ✅ শুনানি এডিট স্ক্রিনে নেভিগেট
  Future<void> _navigateToEditHearing(Map<String, dynamic> hearing) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditHearingScreen(hearingData: hearing),
      ),
    );
    if (result == true && mounted) {
      _fetchHearings();
    }
  }

  // ✅ নতুন শুনানি যোগ করার বটম শিট
  void _showAddHearingSheet() {
    final stageNoteController = TextEditingController();
    final courtOrderController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // ✅ ১. তারিখ প্রি-ফিল: কেসের next_hearing_date অথবা বর্তমান সময়
    DateTime? selectedHearingDate;
    if (_currentCaseData['next_hearing_date'] != null) {
      try {
        selectedHearingDate =
            DateTime.parse(_currentCaseData['next_hearing_date']).toLocal();
      } catch (_) {
        selectedHearingDate = DateTime.now();
      }
    } else {
      selectedHearingDate = DateTime.now();
    }

    DateTime? selectedNextDate;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0F2C3E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_circle,
                          color: Color(0xFFE5B25D), size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'নতুন শুনানি যোগ করুন',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ✅ শুনানির তারিখ ও সময়
                  _buildSheetSectionLabel('শুনানির তারিখ ও সময় *'),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedHearingDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        builder: (ctx, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFE5B25D),
                              onPrimary: Color(0xFF032836),
                              surface: Color(0xFF0F2C3E),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        ),
                      );

                      if (pickedDate == null || !mounted) return;

                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedHearingDate != null
                            ? TimeOfDay(
                                hour: selectedHearingDate!.hour,
                                minute: selectedHearingDate!.minute,
                              )
                            : TimeOfDay.now(),
                        builder: (ctx, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFE5B25D),
                              onPrimary: Color(0xFF032836),
                              surface: Color(0xFF0F2C3E),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        ),
                      );

                      if (pickedTime == null) return;

                      setModalState(() {
                        selectedHearingDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event,
                              color: Color(0xFFE5B25D), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedHearingDate == null
                                  ? 'তারিখ ও সময় নির্বাচন করুন'
                                  : _formatDateTime(selectedHearingDate!),
                              style: TextStyle(
                                color: selectedHearingDate == null
                                    ? Colors.white54
                                    : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(Icons.edit,
                              color: Colors.white38, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // স্টেজ / নোট
                  _buildSheetSectionLabel('স্টেজ / নোট *'),
                  TextFormField(
                    controller: stageNoteController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('স্টেজ / নোট'),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'স্টেজ বা নোট লিখুন'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // কোর্ট অর্ডার
                  _buildSheetSectionLabel('আদালতের আদেশ'),
                  TextFormField(
                    controller: courtOrderController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('আদালতের আদেশ (ঐচ্ছিক)'),
                  ),
                  const SizedBox(height: 12),

                  // পরবর্তী তারিখ
                  _buildSheetSectionLabel('পরবর্তী শুনানির তারিখ'),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedNextDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        builder: (ctx, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFE5B25D),
                              onPrimary: Color(0xFF032836),
                              surface: Color(0xFF0F2C3E),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        ),
                      );

                      if (pickedDate == null || !mounted) return;

                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedNextDate != null
                            ? TimeOfDay(
                                hour: selectedNextDate!.hour,
                                minute: selectedNextDate!.minute,
                              )
                            : TimeOfDay.now(),
                        builder: (ctx, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFE5B25D),
                              onPrimary: Color(0xFF032836),
                              surface: Color(0xFF0F2C3E),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        ),
                      );

                      if (pickedTime == null) return;

                      setModalState(() {
                        selectedNextDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Color(0xFFE5B25D), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedNextDate == null
                                  ? 'তারিখ ও সময় নির্বাচন করুন'
                                  : _formatDateTime(selectedNextDate!),
                              style: TextStyle(
                                color: selectedNextDate == null
                                    ? Colors.white54
                                    : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (selectedNextDate != null)
                            GestureDetector(
                              onTap: () =>
                                  setModalState(() => selectedNextDate = null),
                              child: const Icon(Icons.close,
                                  color: Colors.white54, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // সংরক্ষণ বাটন
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5B25D),
                        foregroundColor: const Color(0xFF032836),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (selectedHearingDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'শুনানির তারিখ ও সময় নির্বাচন করুন'),
                                  ),
                                );
                                return;
                              }

                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSaving = true);

                              try {
                                await _hearingService.addHearing(
                                  caseId: _currentCaseData['id'],
                                  hearingDate: selectedHearingDate!,
                                  stageNote: stageNoteController.text.trim(),
                                  courtOrder: courtOrderController.text.trim(),
                                  nextDate: selectedNextDate,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _fetchHearings();
                                final updatedCase = await _caseService
                                    .getCaseById(_currentCaseData['id']);
                                if (updatedCase != null && mounted) {
                                  setState(
                                      () => _currentCaseData = updatedCase);
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('শুনানি সফলভাবে যোগ হয়েছে'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('ব্যর্থ: $e')),
                                  );
                                }
                              } finally {
                                setModalState(() => isSaving = false);
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF032836)),
                            )
                          : const Text(
                              'সংরক্ষণ করুন',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white30),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE5B25D)),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _currentCaseData['status'] ?? 'Active';
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCaseData['case_number'] ?? 'মামলার বিস্তারিত'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF0F2C3E),
            onSelected: (value) {
              if (value == 'edit') {
                _navigateToEdit();
              } else if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Color(0xFFE5B25D), size: 20),
                    SizedBox(width: 12),
                    Text('এডিট করুন', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('ডিলিট করুন',
                        style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ কেস ইনফো সেকশন
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0F2C3E),
              border: Border(
                bottom: BorderSide(color: Colors.white12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentCaseData['title'] ?? 'শিরোনাম নেই',
                        style: const TextStyle(
                          color: Color(0xFFE5B25D),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'আদালত: ${_currentCaseData['court_name'] ?? 'নেই'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),

                // ✅ ক্লায়েন্ট (না থাকলে মেসেজ)
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'ক্লায়েন্ট: ${_currentCaseData['clients']?['name'] ?? 'যোগ করা হয়নি'}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    if (_currentCaseData['client_id'] == null)
                      TextButton(
                        onPressed: _navigateToEdit,
                        child: const Text(
                          'যোগ করুন',
                          style: TextStyle(
                            color: Color(0xFFE5B25D),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                if (_currentCaseData['opposite_party'] != null &&
                    _currentCaseData['opposite_party']
                        .toString()
                        .isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'বিপক্ষ: ${_currentCaseData['opposite_party']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'মামলার ধরন: ${_currentCaseData['case_type'] ?? 'নেই'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),

                if (_currentCaseData['next_hearing_date'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'পরবর্তী শুনানি: ${_formatDate(_currentCaseData['next_hearing_date'])}',
                    style: const TextStyle(
                        color: Color(0xFFE5B25D),
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],

                if (_currentCaseData['notes'] != null &&
                    _currentCaseData['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.notes,
                          color: Color(0xFFE5B25D), size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        'নোট:',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07384A).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currentCaseData['notes'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ✅ শুনানির ইতিহাস
          Expanded(
            child: _isLoadingHearings
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE5B25D)))
                : _buildHearingsSection(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE5B25D),
        onPressed: _showAddHearingSheet,
        child: const Icon(Icons.add, color: Color(0xFF032836)),
      ),
    );
  }

  // ✅ শুনানির সেকশন (history + upcoming)
  Widget _buildHearingsSection() {
    // ✅ যদি hearing_history খালি, কিন্তু next_hearing_date আছে
    if (_hearings.isEmpty && _currentCaseData['next_hearing_date'] != null) {
      return RefreshIndicator(
        onRefresh: _fetchHearings,
        color: const Color(0xFFE5B25D),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // আসন্ন শুনানির কার্ড (cases থেকে)
            Card(
              color: const Color(0xFF0F2C3E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: const Color(0xFFE5B25D).withValues(alpha: 0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event,
                            color: Color(0xFFE5B25D), size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'আসন্ন শুনানি',
                          style: TextStyle(
                            color: Color(0xFFE5B25D),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE5B25D).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'নির্ধারিত',
                            style: TextStyle(
                              color: Color(0xFFE5B25D),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatDate(_currentCaseData['next_hearing_date']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'এখনো কোনো শুনানির রেকর্ড নেই। "+" বাটনে ট্যাপ করে শুনানির বিস্তারিত যোগ করুন।',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ যদি hearing_history খালি এবং next_hearing_date-ও নেই
    if (_hearings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.white24),
            SizedBox(height: 12),
            Text(
              'এখনো কোনো শুনানির রেকর্ড নেই',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // ✅ hearing_history আছে
    return RefreshIndicator(
      onRefresh: _fetchHearings,
      color: const Color(0xFFE5B25D),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _hearings.length,
        itemBuilder: (ctx, index) {
          final hearing = _hearings[index];
          return _buildHearingCard(hearing);
        },
      ),
    );
  }

  // ✅ শুনানির কার্ড
  Widget _buildHearingCard(Map<String, dynamic> hearing) {
    final hearingDate = hearing['hearing_date'];
    final stageNote = hearing['stage_note'] ?? '';
    final courtOrder = hearing['court_order'] ?? '';
    final nextDate = hearing['next_date'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF0F2C3E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _showHearingOptions(hearing);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: Color(0xFFE5B25D), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(hearingDate),
                    style: const TextStyle(
                      color: Color(0xFFE5B25D),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.more_vert, color: Colors.white38, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              if (stageNote.isNotEmpty) ...[
                const Text(
                  'স্টেজ / নোট:',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  stageNote,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],
              if (courtOrder.isNotEmpty) ...[
                const Text(
                  'আদালতের আদেশ:',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  courtOrder,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],
              if (nextDate != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5B25D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward,
                          color: Color(0xFFE5B25D), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'পরবর্তী তারিখ: ${_formatDate(nextDate)}',
                        style: const TextStyle(
                          color: Color(0xFFE5B25D),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ✅ শুনানির অপশন ডায়ালগ
  void _showHearingOptions(Map<String, dynamic> hearing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2C3E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFFE5B25D)),
              title: const Text(
                'শুনানি এডিট করুন',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToEditHearing(hearing);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text(
                'শুনানি ডিলিট করুন',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteHearing(hearing);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
