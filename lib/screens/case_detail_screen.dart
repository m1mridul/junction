import 'package:flutter/material.dart';
import '../services/hearing_service.dart';
import '../services/case_service.dart';
import 'edit_case_screen.dart';

class CaseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;

  const CaseDetailScreen({super.key, required this.caseData});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final HearingService _hearingService = HearingService();
  final CaseService _caseService = CaseService();
  List<Map<String, dynamic>> _hearings = [];
  bool _isLoadingHearings = true;

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

  @override
  void initState() {
    super.initState();
    _fetchHearings();
  }

  Future<void> _fetchHearings() async {
    setState(() => _isLoadingHearings = true);
    try {
      final data =
          await _hearingService.getHearingsByCaseId(widget.caseData['id']);
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
      await _caseService.deleteCase(widget.caseData['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('মামলা সফলভাবে ডিলিট হয়েছে')),
        );
        Navigator.pop(context, true); // ✅ লিস্টে ফিরে যাবে ও রিফ্রেশ করবে
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
        builder: (_) => EditCaseScreen(caseData: widget.caseData),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true); // ✅ লিস্টে ফিরে যাবে ও রিফ্রেশ করবে
    }
  }

  // ✅ নতুন শুনানি যোগ করার বটম শিট
  void _showAddHearingSheet() {
    final stageNoteController = TextEditingController();
    final courtOrderController = TextEditingController();
    final formKey = GlobalKey<FormState>();
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
                  TextFormField(
                    controller: stageNoteController,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        _inputDecoration('স্টেজ / নোট (যেমন: চার্জ গঠন) *'),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'স্টেজ বা নোট লিখুন'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: courtOrderController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('আদালতের আদেশ'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setModalState(() => selectedNextDate = picked);
                      }
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
                                  ? 'পরবর্তী শুনানির তারিখ নির্বাচন করুন'
                                  : '${selectedNextDate!.day} ${_getBengaliMonth(selectedNextDate!.month)} ${selectedNextDate!.year}',
                              style: TextStyle(
                                color: selectedNextDate == null
                                    ? Colors.white54
                                    : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSaving = true);

                              try {
                                await _hearingService.addHearing(
                                  caseId: widget.caseData['id'],
                                  hearingDate: DateTime.now(),
                                  stageNote: stageNoteController.text.trim(),
                                  courtOrder: courtOrderController.text.trim(),
                                  nextDate: selectedNextDate,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _fetchHearings();
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
    final status = widget.caseData['status'] ?? 'Active';
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.caseData['case_number'] ?? 'মামলার বিস্তারিত'),
        actions: [
          // ✅ পপআপ মেনু (এডিট ও ডিলিট)
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
                        widget.caseData['title'] ?? 'শিরোনাম নেই',
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
                  'আদালত: ${widget.caseData['court_name'] ?? 'নেই'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'ক্লায়েন্ট: ${widget.caseData['clients']?['name'] ?? 'নেই'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (widget.caseData['opposite_party'] != null &&
                    widget.caseData['opposite_party']
                        .toString()
                        .isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'বিপক্ষ: ${widget.caseData['opposite_party']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'মামলার ধরন: ${widget.caseData['case_type'] ?? 'নেই'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (widget.caseData['next_hearing_date'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'পরবর্তী শুনানি: ${_formatDate(widget.caseData['next_hearing_date'])}',
                    style: const TextStyle(
                        color: Color(0xFFE5B25D),
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
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
                : _hearings.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history,
                                size: 64, color: Colors.white24),
                            SizedBox(height: 12),
                            Text(
                              'এখনো কোনো শুনানির রেকর্ড নেই',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
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
                      ),
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
    );
  }
}
