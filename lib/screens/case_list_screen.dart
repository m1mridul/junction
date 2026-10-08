import 'package:flutter/material.dart';
import '../services/case_service.dart';
import '../services/client_service.dart';
import 'case_detail_screen.dart';
import 'client_list_screen.dart';
import 'add_case_screen.dart';

class CaseListScreen extends StatefulWidget {
  const CaseListScreen({super.key});

  @override
  State<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends State<CaseListScreen> {
  final CaseService _caseService = CaseService();
  final ClientService _clientService = ClientService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _cases = [];
  List<Map<String, dynamic>> _filteredCases = [];
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;

  // ✅ ডেটাবেসের মান অনুযায়ী
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
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final caseData = await _caseService.getCases();
      final clientData = await _clientService.getClients();
      setState(() {
        _cases = caseData;
        _filteredCases = caseData;
        _clients = clientData;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('মামলা লোড ব্যর্থ: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // ✅ সার্চ ফিল্টার
  void _filterCases(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCases = _cases;
      } else {
        _filteredCases = _cases.where((c) {
          final title = (c['title'] ?? '').toString().toLowerCase();
          final caseNumber = (c['case_number'] ?? '').toString().toLowerCase();
          final court = (c['court_name'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return title.contains(q) ||
              caseNumber.contains(q) ||
              court.contains(q);
        }).toList();
      }
    });
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

  // ✅ স্ট্যাটাস লেবেল
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

  // ✅ স্ট্যাটাস কালার
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

  // ✅ নতুন স্ক্রিনে নেভিগেট
  void _navigateToAddCase() async {
    // ক্লায়েন্ট না থাকলে ক্লায়েন্ট স্ক্রিনে পাঠান
    if (_clients.isEmpty) {
      final goToClients = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F2C3E),
          title: const Text(
            'ক্লায়েন্ট প্রয়োজন',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'মামলা যোগ করার আগে অন্তত একজন ক্লায়েন্ট যোগ করুন।',
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
                'ক্লায়েন্ট যোগ করুন',
                style: TextStyle(color: Color(0xFFE5B25D)),
              ),
            ),
          ],
        ),
      );

      if (goToClients == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClientListScreen()),
        );
        _fetchData(); // ক্লায়েন্ট যোগের পর কেস লিস্ট রিফ্রেশ
      }
      return;
    }

    // ✅ AddCaseScreen-এ নেভিগেট
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCaseScreen()),
    );

    // ✅ কেস সেভ হলে লিস্ট রিফ্রেশ
    if (result == true) {
      _fetchData();
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('মামলাসমূহ'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5B25D)))
          : Column(
              children: [
                // ✅ সার্চ বার
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterCases,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'মামলা খুঁজুন...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFFE5B25D)),
                      filled: true,
                      fillColor: const Color(0xFF0F2C3E),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // ✅ কেস লিস্ট
                Expanded(
                  child: _filteredCases.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.folder_open,
                                  size: 64, color: Colors.white24),
                              const SizedBox(height: 12),
                              Text(
                                _cases.isEmpty
                                    ? 'এখনো কোনো মামলা যোগ করা হয়নি'
                                    : 'কোনো মামলা পাওয়া যায়নি',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchData,
                          color: const Color(0xFFE5B25D),
                          child: ListView.builder(
                            itemCount: _filteredCases.length,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemBuilder: (ctx, index) {
                              final item = _filteredCases[index];
                              return _buildCaseCard(item);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE5B25D),
        onPressed: _navigateToAddCase,
        child: const Icon(Icons.add, color: Color(0xFF032836)),
      ),
    );
  }

  // ✅ ডিজাইনের মতো কেস কার্ড
  Widget _buildCaseCard(Map<String, dynamic> item) {
    final caseType = item['case_type'] ?? 'অন্যান্য';
    final caseNumber = item['case_number'] ?? '';
    final title = item['title'] ?? '';
    final courtName = item['court_name'] ?? '';
    final status = item['status'] ?? 'Active';
    final nextHearing = item['next_hearing_date'];
    final clientName =
        item['clients'] != null ? item['clients']['name'] : 'ক্লায়েন্ট নেই';

    final icon = _getCaseIcon(caseType);
    final iconColor = _getCaseColor(caseType);
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF0F2C3E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        // ✅ এখানে পরিবর্তন: if (result == true) শর্ত সরিয়ে ফেলা হয়েছে
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaseDetailScreen(caseData: item),
            ),
          );
          // ✅ সবসময় লিস্ট রিফ্রেশ করো (এডিট, ডিলিট, শুনানি যোগ হলেও)
          _fetchData();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // আইকন
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),

              // তথ্য
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            clientName,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'শুনানি: ${_formatDate(nextHearing)}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
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
