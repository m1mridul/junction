import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'case_list_screen.dart';
import 'client_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  int _clientCount = 0;
  int _totalCases = 0;
  int _activeCases = 0;
  int _disposedCases = 0;
  bool _isLoading = true;

  List<Map<String, dynamic>> _recentCases = [];

  String _userName = 'Advocate';
  String _userAddress = '';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchRecentCases();
  }

  Future<void> _fetchStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final profileResp = await _supabase
            .from('profiles')
            .select('full_name, address')
            .eq('id', userId)
            .maybeSingle();

        final clientsResp =
            await _supabase.from('clients').select('id').eq('user_id', userId);

        final activeResp = await _supabase
            .from('cases')
            .select('id')
            .eq('user_id', userId)
            .eq('status', 'Active');

        final disposedResp = await _supabase
            .from('cases')
            .select('id')
            .eq('user_id', userId)
            .eq('status', 'Disposed');

        if (mounted) {
          setState(() {
            _clientCount = (clientsResp as List).length;
            _activeCases = (activeResp as List).length;
            _disposedCases = (disposedResp as List).length;
            _totalCases = _activeCases + _disposedCases;

            if (profileResp != null) {
              _userName = profileResp['full_name'] ?? 'Advocate';
              _userAddress = profileResp['address'] ?? '';
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRecentCases() async {
    if (!mounted) return;
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final resp = await _supabase
            .from('cases')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(3);

        if (mounted) {
          setState(() {
            _recentCases = List<Map<String, dynamic>>.from(resp);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching recent cases: $e");
    }
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

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'নির্ধারিত হয়নি';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day} ${_getBengaliMonth(dt.month)} ${dt.year}';
    } catch (_) {
      return 'নির্ধারিত হয়নি';
    }
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      return '${hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ AppBar সরানো হয়েছে
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE5B25D)))
            : RefreshIndicator(
                onRefresh: () async {
                  await _fetchStats();
                  await _fetchRecentCases();
                },
                color: const Color(0xFFE5B25D),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildTotalCasesCard(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildRecentCases(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ✅ হেডার (গ্যাভেল ইমেজসহ ডিজাইনের মতো)
  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // গ্যাভেল ইমেজ (ডানদিকে, ব্লেন্ড করা)
        Positioned(
          right: -20,
          top: -20,
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Colors.black], // বাম থেকে ডানে ফেড
                stops: [0.4, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              'assets/images/home_bg.png',
              height: 110,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        ),
        // প্রোফাইল ইনফো
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF07384A),
              child: _avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        _avatarUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person,
                            color: Color(0xFFE5B25D), size: 34),
                      ),
                    )
                  : const Icon(Icons.person,
                      color: Color(0xFFE5B25D), size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'স্বাগতম, $_userName',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFFE5B25D), size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _userAddress.isNotEmpty
                              ? _userAddress
                              : 'ঠিকানা যোগ করুন',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ মোট মামলা কার্ড (ডিজাইনের মতো)
  Widget _buildTotalCasesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2C3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5B25D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5B25D).withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          // আইকন
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE5B25D).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_special,
                color: Color(0xFFE5B25D), size: 28),
          ),
          const SizedBox(width: 16),
          // তথ্য
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('মোট মামলা',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70)),
                const SizedBox(height: 4),
                Text('$_totalCases টি',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5B25D))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusChip(
                        label: 'চলমান',
                        count: _activeCases,
                        color: Colors.greenAccent),
                    const SizedBox(width: 16),
                    _buildStatusChip(
                        label: 'নিষ্পত্তি',
                        count: _disposedCases,
                        color: Colors.blueAccent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
      {required String label, required int count, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: $count টি',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // ✅ দ্রুত সেবা (৪টি আইকন)
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('দ্রুত সেবা',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE5B25D))),
            TextButton(
                onPressed: () {},
                child: const Text('সব দেখুন',
                    style: TextStyle(color: Color(0xFFE5B25D), fontSize: 13))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionItem(
                icon: Icons.add_circle_outline,
                label: 'নতুন মামলা\nযোগ করুন',
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CaseListScreen()));
                  if (mounted) {
                    _fetchStats();
                    _fetchRecentCases();
                  }
                }),
            _buildQuickActionItem(
                icon: Icons.folder_open,
                label: 'আমার মামলা\nসমূহ',
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CaseListScreen()));
                  if (mounted) {
                    _fetchStats();
                    _fetchRecentCases();
                  }
                }),
            _buildQuickActionItem(
                icon: Icons.calendar_month,
                label: 'শুনানির তারিখ\nও সময়',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('ক্যালেন্ডার স্ক্রিন শীঘ্রই আসছে')));
                }),
            _buildQuickActionItem(
                icon: Icons.menu_book,
                label: 'আইনকোষ /\nপ্রোফাইল',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('আইনকোষ শীঘ্রই আসছে')));
                }),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2C3E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFE5B25D).withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: const Color(0xFFE5B25D), size: 24),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11, height: 1.3)),
          ],
        ),
      ),
    );
  }

  // ✅ সাম্প্রতিক মামলা
  Widget _buildRecentCases() {
    if (_recentCases.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('সাম্প্রতিক মামলা',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE5B25D))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xFF0F2C3E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12)),
            child: const Center(
                child: Text('এখনো কোনো মামলা যোগ করা হয়নি',
                    style: TextStyle(color: Colors.white54, fontSize: 13))),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('সাম্প্রতিক মামলা',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE5B25D))),
            TextButton(
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CaseListScreen()));
                  if (mounted) {
                    _fetchStats();
                    _fetchRecentCases();
                  }
                },
                child: const Text('সব দেখুন',
                    style: TextStyle(color: Color(0xFFE5B25D), fontSize: 13))),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentCases.map((caseData) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCaseCard(caseData))),
      ],
    );
  }

  // ✅ কেস কার্ড (ডিজাইনের মতো বিস্তারিত)
  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    final caseType = caseData['case_type'] ?? 'অন্যান্য';
    final caseNumber = caseData['case_number'] ?? '';
    final courtName = caseData['court_name'] ?? '';
    final nextHearing = caseData['next_hearing_date'];
    final status = caseData['status'] ?? 'Active';

    final icon = _getCaseIcon(caseType);
    final iconColor = _getCaseColor(caseType);
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2C3E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('$caseType মামলা নং $caseNumber',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_city,
                        color: Colors.white38, size: 11),
                    const SizedBox(width: 3),
                    Expanded(
                        child: Text(courtName,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10),
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white38, size: 11),
                    const SizedBox(width: 3),
                    Text('শুনানির তারিখ: ${_formatDate(nextHearing)}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.white38, size: 11),
                    const SizedBox(width: 3),
                    Text('সময়: ${_formatTime(nextHearing)}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 12),
        ],
      ),
    );
  }
}
