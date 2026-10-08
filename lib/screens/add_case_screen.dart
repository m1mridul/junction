import 'package:flutter/material.dart';
import '../services/case_service.dart';
import '../services/client_service.dart';

class AddCaseScreen extends StatefulWidget {
  const AddCaseScreen({super.key});

  @override
  State<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends State<AddCaseScreen> {
  final _caseService = CaseService();
  final _clientService = ClientService();
  final _formKey = GlobalKey<FormState>();

  // কন্ট্রোলার
  final _caseNumberController = TextEditingController();
  final _caseTitleController = TextEditingController();
  final _courtNameController = TextEditingController();
  final _oppositePartyController = TextEditingController();
  final _notesController = TextEditingController();

  // সিলেক্টেড ভ্যালু
  String? _selectedClientId;
  String _selectedCaseType = 'দেওয়ানি';
  String _selectedStatus = 'Active';
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
        if (_clients.isNotEmpty) {
          _selectedClientId = _clients.first['id'].toString();
        }
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

  // ✅ তারিখ পিকার
  // ✅ তারিখ ও সময় পিকার (একসাথে)
  Future<void> _pickHearingDate() async {
    // তারিখ পিকার
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedNextHearingDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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

    if (pickedDate == null || !mounted) return;

    // সময় পিকার
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedNextHearingDate != null
          ? TimeOfDay(
              hour: _selectedNextHearingDate!.hour,
              minute: _selectedNextHearingDate!.minute,
            )
          : TimeOfDay.now(),
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

    if (pickedTime == null) return;

    // তারিখ ও সময় একসাথে
    setState(() {
      _selectedNextHearingDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  // ✅ সংরক্ষণ
  Future<void> _saveCase() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ক্লায়েন্ট নির্বাচন করুন')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _caseService.addCase(
        clientId: _selectedClientId!,
        caseNumber: _caseNumberController.text.trim(),
        title: _caseTitleController.text.trim(),
        courtName: _courtNameController.text.trim(),
        caseType: _selectedCaseType,
        status: _selectedStatus,
        nextHearingDate: _selectedNextHearingDate,
        oppositeParty: _oppositePartyController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('মামলা সফলভাবে যোগ হয়েছে')),
        );
        Navigator.pop(context, true); // ✅ true পাঠাই, যাতে list refresh হয়
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('মামলা যোগ ব্যর্থ: $e')),
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
        title: const Text('নতুন মামলা যোগ করুন'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingClients
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5B25D)))
          : _clients.isEmpty
              ? _buildNoClientsView()
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ক্লায়েন্ট নির্বাচন
                        _buildSectionLabel('ক্লায়েন্ট নির্বাচন করুন *'),
                        DropdownButtonFormField<String>(
                          value: _selectedClientId,
                          dropdownColor: const Color(0xFF0F2C3E),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('ক্লায়েন্ট *'),
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
                          onChanged: (val) => setState(() =>
                              _selectedCaseType = val ?? _caseTypes.first),
                        ),
                        const SizedBox(height: 20),

                        // আদালত
                        _buildSectionLabel('আদালতের নাম *'),
                        TextFormField(
                          controller: _courtNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              _inputDecoration('যেমন: ঢাকা জেলা জজ আদালত'),
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

                        // মামলার অবস্থা
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

                        // শুনানির তারিখ
                        _buildSectionLabel('পরবর্তী শুনানির তারিখ ও সময়'),
                        InkWell(
                          onTap: _pickHearingDate,
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
                                        ? 'তারিখ ও সময় নির্বাচন করুন'
                                        : '${_selectedNextHearingDate!.day} ${_getBengaliMonth(_selectedNextHearingDate!.month)} ${_selectedNextHearingDate!.year}, ${_selectedNextHearingDate!.hour}:${_selectedNextHearingDate!.minute.toString().padLeft(2, '0')}',
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

                        // সংরক্ষণ বাটন
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
                            onPressed: _isSaving ? null : _saveCase,
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
                                    'সংরক্ষণ করুন',
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

  // ✅ ক্লায়েন্ট না থাকলে এই ভিউ দেখাবে
  Widget _buildNoClientsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'কোনো ক্লায়েন্ট নেই',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'মামলা যোগ করার আগে অন্তত একজন ক্লায়েন্ট যোগ করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5B25D),
                  foregroundColor: const Color(0xFF032836),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // এখানে ClientListScreen-এ নেভিগেট করতে পারেন
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  'ঠিক আছে',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ সেকশন লেবেল
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
