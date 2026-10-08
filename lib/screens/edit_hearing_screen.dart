import 'package:flutter/material.dart';
import '../services/hearing_service.dart';

class EditHearingScreen extends StatefulWidget {
  final Map<String, dynamic> hearingData;

  const EditHearingScreen({super.key, required this.hearingData});

  @override
  State<EditHearingScreen> createState() => _EditHearingScreenState();
}

class _EditHearingScreenState extends State<EditHearingScreen> {
  final _hearingService = HearingService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _stageNoteController;
  late TextEditingController _courtOrderController;

  // ✅ শুনানির তারিখ ও সময়
  DateTime? _selectedHearingDate;
  DateTime? _selectedNextDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _stageNoteController =
        TextEditingController(text: widget.hearingData['stage_note'] ?? '');
    _courtOrderController =
        TextEditingController(text: widget.hearingData['court_order'] ?? '');

    // শুনানির তারিখ পার্স
    if (widget.hearingData['hearing_date'] != null) {
      try {
        _selectedHearingDate =
            DateTime.parse(widget.hearingData['hearing_date']).toLocal();
      } catch (_) {}
    }

    // পরবর্তী তারিখ পার্স
    if (widget.hearingData['next_date'] != null) {
      try {
        _selectedNextDate =
            DateTime.parse(widget.hearingData['next_date']).toLocal();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _stageNoteController.dispose();
    _courtOrderController.dispose();
    super.dispose();
  }

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

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'টায়' : 'টায়';
    return '${dt.day} ${_getBengaliMonth(dt.month)} ${dt.year}, $hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  // ✅ তারিখ ও সময় পিকার
  Future<void> _pickDateTime({required bool isHearing}) async {
    final current = isHearing ? _selectedHearingDate : _selectedNextDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
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
      initialTime: TimeOfDay.fromDateTime(current ?? DateTime.now()),
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

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isHearing) {
        _selectedHearingDate = combined;
      } else {
        _selectedNextDate = combined;
      }
    });
  }

  Future<void> _updateHearing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _hearingService.updateHearing(
        hearingId: widget.hearingData['id'],
        stageNote: _stageNoteController.text.trim(),
        courtOrder: _courtOrderController.text.trim(),
        nextDate: _selectedNextDate,
        hearingDate: _selectedHearingDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('শুনানি সফলভাবে আপডেট হয়েছে')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('আপডেট ব্যর্থ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('শুনানি এডিট করুন'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ শুনানির তারিখ ও সময় (এডিটযোগ্য)
              _buildSectionLabel('শুনানির তারিখ ও সময় *'),
              InkWell(
                onTap: () => _pickDateTime(isHearing: true),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          _selectedHearingDate == null
                              ? 'তারিখ ও সময় নির্বাচন করুন'
                              : _formatDateTime(_selectedHearingDate!),
                          style: TextStyle(
                            color: _selectedHearingDate == null
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

              // স্টেজ / নোট
              _buildSectionLabel('স্টেজ / নোট *'),
              TextFormField(
                controller: _stageNoteController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('যেমন: চার্জ গঠন'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'স্টেজ বা নোট লিখুন'
                    : null,
              ),
              const SizedBox(height: 20),

              // কোর্ট অর্ডার
              _buildSectionLabel('আদালতের আদেশ'),
              TextFormField(
                controller: _courtOrderController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('আদালতের আদেশ (ঐচ্ছিক)'),
              ),
              const SizedBox(height: 20),

              // পরবর্তী তারিখ
              _buildSectionLabel('পরবর্তী শুনানির তারিখ'),
              InkWell(
                onTap: () => _pickDateTime(isHearing: false),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          _selectedNextDate == null
                              ? 'তারিখ ও সময় নির্বাচন করুন'
                              : _formatDateTime(_selectedNextDate!),
                          style: TextStyle(
                            color: _selectedNextDate == null
                                ? Colors.white54
                                : Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_selectedNextDate != null)
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white54, size: 18),
                          onPressed: () =>
                              setState(() => _selectedNextDate = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // আপডেট বাটন
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5B25D),
                    foregroundColor: const Color(0xFF032836),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _isSaving ? null : _updateHearing,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF032836),
                          ),
                        )
                      : const Text(
                          'আপডেট করুন',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
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
}
