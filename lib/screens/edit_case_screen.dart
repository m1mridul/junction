import 'package:flutter/material.dart';
import '../services/case_service.dart';
import '../services/client_service.dart';

class EditCaseScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;

  const EditCaseScreen({super.key, required this.caseData});

  @override
  State<EditCaseScreen> createState() => _EditCaseScreenState();
}

class _EditCaseScreenState extends State<EditCaseScreen> {
  final _caseService = CaseService();
  final _clientService = ClientService();
  final _formKey = GlobalKey<FormState>();

  // কন্ট্রোলার
  late TextEditingController _caseNumberController;
  late TextEditingController _caseTitleController;
  late TextEditingController _courtNameController;
  late TextEditingController _oppositePartyController;
  late TextEditingController _notesController;

  // সিলেক্টেড ভ্যালু
  String? _selectedClientId;
  late String _selectedCaseType;
  late String _selectedStatus;

  // ✅ কেস ফাইলিং ডেট
  DateTime? _selectedFilingDate;

  // ✅ পরবর্তী শুনানির তারিখ
  DateTime? _selectedNextHearingDate;

  // ডেটা
  List<Map<String, dynamic>> _clients = [];
  bool _isLoadingClients = true;
  bool _isSaving = false;

  // অপশন লিস্ট
  final List<String> _caseTypes = [
    'দেওয়ানি',
    'ফৌজদারি',
    'পারিবারিক',
    'জমি সংক্রান্ত',
    'অন্যান্য',
  ];

  final List<Map<String, String>> _statusOptions = [
    {'value': 'Active', 'label': 'চলমান'},
    {'value': 'Pending', 'label': 'বিচারাধীন'},
    {'value': 'Disposed', 'label': 'নিষ্পত্তি'},
    {'value': 'Closed', 'label': 'বন্ধ'},
    {'value': 'Appealed', 'label': 'আপিলকৃত'},
  ];

  @override
  void initState() {
    super.initState();

    // ✅ প্রি-ফিল করা (বর্তমান কেস ডেটা দিয়ে)
    _caseNumberController =
        TextEditingController(text: widget.caseData['case_number'] ?? '');
    _caseTitleController =
        TextEditingController(text: widget.caseData['title'] ?? '');
    _courtNameController =
        TextEditingController(text: widget.caseData['court_name'] ?? '');
    _oppositePartyController =
        TextEditingController(text: widget.caseData['opposite_party'] ?? '');
    _notesController =
        TextEditingController(text: widget.caseData['notes'] ?? '');

    _selectedClientId = widget.caseData['client_id']?.toString();
    _selectedCaseType = widget.caseData['case_type'] ?? 'দেওয়ানি';
    _selectedStatus = widget.caseData['status'] ?? 'Active';

    // ✅ কেস ফাইলিং ডেট পার্স
    if (widget.caseData['filing_date'] != null) {
      try {
        _selectedFilingDate =
            DateTime.parse(widget.caseData['filing_date']).toLocal();
      } catch (_) {
        _selectedFilingDate = null;
      }
    }

    // ✅ পরবর্তী শুনানির তারিখ পার্স
    if (widget.caseData['next_hearing_date'] != null) {
      try {
        _selectedNextHearingDate =
            DateTime.parse(widget.caseData['next_hearing_date']).toLocal();
      } catch (_) {
        _selectedNextHearingDate = null;
      }
    }

    _fetchClients();
  }

  @override
  void dispose() {
    _caseNumberController.dispose();
    _caseTitleController.dispose();
    _courtNameController.dispose();
    _oppositePartyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
    setState(() => _isLoadingClients = true);
    try {
      final data = await _clientService.getClients();
      setState(() {
        _clients = data;
        _isLoadingClients = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ক্লায়েন্ট লোড ব্যর্থ: $e')),
        );
      }
      setState(() => _isLoadingClients = false);
    }
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

  // ✅ কেস ফাইলিং ডেট পিকার (অতীতের তারিখও সিলেক্ট করা যাবে)
  Future<void> _pickFilingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilingDate ?? DateTime.now(),
      firstDate: DateTime(2000), // ✅ অতীতের তারিখও সিলেক্ট করা যাবে
      lastDate: DateTime.now(), // ✅ ভবিষ্যতের তারিখ সিলেক্ট করা যাবে না
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE5B25D),
              onPrimary: Color(0xFF032836),
              surface: Color(0xFF0F2C3E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedFilingDate = picked);
    }
  }

  // ✅ পরবর্তী শুনানির তারিখ পিকার (ভবিষ্যতের তারিখ)
  Future<void> _pickNextHearingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedNextHearingDate ?? DateTime.now(),
      firstDate: DateTime.now(), // ✅ ভবিষ্যতের তারিখ
      lastDate: DateTime(2035),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE5B25D),
              onPrimary: Color(0xFF032836),
              surface: Color(0xFF0F2C3E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedNextHearingDate = picked);
    }
  }

  Future<void> _updateCase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _caseService.updateCase(
        caseId: widget.caseData['id'],
        clientId: _selectedClientId,
        caseNumber: _caseNumberController.text.trim(),
        title: _caseTitleController.text.trim(),
        courtName: _courtNameController.text.trim(),
        caseType: _selectedCaseType,
        status: _selectedStatus,
        nextHearingDate: _selectedNextHearingDate,
        filingDate: _selectedFilingDate, // ✅ নতুন
        oppositeParty: _oppositePartyController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('মামলা সফলভাবে আপডেট হয়েছে')),
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
        title: const Text('মামলা এডিট করুন'),
      ),
      body: _isLoadingClients
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5B25D)))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ক্লায়েন্ট
                    _buildSectionLabel('ক্লায়েন্ট নির্বাচন করুন *'),
                    DropdownButtonFormField<String>(
                      value: _selectedClientId,
                      dropdownColor: const Color(0xFF0F2C3E),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('ক্লায়েন্ট'),
                      items: _clients.map((client) {
                        return DropdownMenuItem<String>(
                          value: client['id'].toString(),
                          child: Text(client['name'] ?? 'নাম নেই'),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedClientId = val),
                    ),
                    const SizedBox(height: 20),

                    // মামলা নম্বর
                    _buildSectionLabel('মামলা নম্বর *'),
                    TextFormField(
                      controller: _caseNumberController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('যেমন: ১২৩/২০২৬'),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'মামলা নম্বর লিখুন'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // মামলার বিবরণ
                    _buildSectionLabel('মামলার বিবরণ *'),
                    TextFormField(
                      controller: _caseTitleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('মামলার শিরোনাম'),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'মামলার বিবরণ লিখুন'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // মামলার ধরন
                    _buildSectionLabel('মামলার ধরন *'),
                    DropdownButtonFormField<String>(
                      value: _selectedCaseType,
                      dropdownColor: const Color(0xFF0F2C3E),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('মামলার ধরন'),
                      items: _caseTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (val) => setState(
                          () => _selectedCaseType = val ?? _caseTypes.first),
                    ),
                    const SizedBox(height: 20),

                    // আদালত
                    _buildSectionLabel('আদালতের নাম *'),
                    TextFormField(
                      controller: _courtNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('যেমন: ঢাকা জেলা জজ আদালত'),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'আদালতের নাম লিখুন'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // বিপক্ষ
                    _buildSectionLabel('বিপক্ষের নাম'),
                    TextFormField(
                      controller: _oppositePartyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('বিপক্ষের নাম (ঐচ্ছিক)'),
                    ),
                    const SizedBox(height: 20),

                    // অবস্থা
                    _buildSectionLabel('মামলার অবস্থা *'),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      dropdownColor: const Color(0xFF0F2C3E),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('অবস্থা'),
                      items: _statusOptions.map((opt) {
                        return DropdownMenuItem<String>(
                          value: opt['value']!,
                          child: Text(opt['label']!),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedStatus = val ?? 'Active'),
                    ),
                    const SizedBox(height: 20),

                    // ✅ কেস ফাইলিং ডেট
                    _buildSectionLabel('কেস ফাইলিং ডেট *'),
                    InkWell(
                      onTap: _pickFilingDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description,
                                color: Color(0xFFE5B25D), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedFilingDate == null
                                    ? 'তারিখ নির্বাচন করুন'
                                    : '${_selectedFilingDate!.day} ${_getBengaliMonth(_selectedFilingDate!.month)} ${_selectedFilingDate!.year}',
                                style: TextStyle(
                                  color: _selectedFilingDate == null
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
                    const SizedBox(height: 20),

                    // পরবর্তী শুনানির তারিখ
                    _buildSectionLabel('পরবর্তী শুনানির তারিখ'),
                    InkWell(
                      onTap: _pickNextHearingDate,
                      borderRadius: BorderRadius.circular(14),
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
                                _selectedNextHearingDate == null
                                    ? 'তারিখ নির্বাচন করুন'
                                    : '${_selectedNextHearingDate!.day} ${_getBengaliMonth(_selectedNextHearingDate!.month)} ${_selectedNextHearingDate!.year}',
                                style: TextStyle(
                                  color: _selectedNextHearingDate == null
                                      ? Colors.white54
                                      : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (_selectedNextHearingDate != null)
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white54, size: 18),
                                onPressed: () => setState(
                                    () => _selectedNextHearingDate = null),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // নোট
                    _buildSectionLabel('নোট (ঐচ্ছিক)'),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('অতিরিক্ত তথ্য...'),
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
                              borderRadius: BorderRadius.circular(26)),
                        ),
                        onPressed: _isSaving ? null : _updateCase,
                        child: _isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF032836)),
                              )
                            : const Text('আপডেট করুন',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
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
            color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white30)),
      focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE5B25D))),
      errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent)),
    );
  }
}
