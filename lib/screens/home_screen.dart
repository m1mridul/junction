import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'client_list_screen.dart';
import 'case_list_screen.dart';

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
  int _pendingCases = 0;
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

        final pendingResp = await _supabase
            .from('cases')
            .select('id')
            .eq('user_id', userId)
            .eq('status', 'Pending');

        final disposedResp = await _supabase
            .from('cases')
            .select('id')
            .eq('user_id', userId)
            .eq('status', 'Disposed');

        final closedResp = await _supabase
            .from('cases')
            .select('id')
            .eq('user_id', userId)
            .eq('status', 'Closed');

        final appealedResp = await _supabase
            .from('cases')
            .select('id')
            .eq('user_id', userId)
            .eq('status', 'Appealed');

        if (mounted) {
          setState(() {
            _clientCount = (clientsResp as List).length;
            _activeCases = (activeResp as List).length;
            _pendingCases = (pendingResp as List).length;
            _disposedCases = (disposedResp as List).length;
            _totalCases = _activeCases +
                _pendingCases +
                _disposedCases +
                (closedResp as List).length +
                (appealedResp as List).length;

            if (profileResp != null) {
              _userName = profileResp['full_name'] ?? 'Advocate';
              _userAddress = profileResp['address'] ?? '';
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching dashboard stats: $e");
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
      appBar: AppBar(
        title: const Text('Law Junction'),
      ),
      body: _isLoading
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
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildTotalCasesCard(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Clients',
                            count: '$_clientCount',
                            icon: Icons.people_alt,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildQuickActions(),
                    const SizedBox(height: 28),
                    _buildRecentCases(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF0F2C3E),
          child: _avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    _avatarUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.person,
                      color: Color(0xFFE5B25D),
                      size: 32,
                    ),
                  ),
                )
              : const Icon(
                  Icons.person,
                  color: Color(0xFFE5B25D),
                  size: 32,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'স্বাগতম, $_userName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFFE5B25D),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _userAddress.isNotEmpty
                          ? _userAddress
                          : 'ঠিকানা যোগ করুন',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2C3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCasesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2C3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5B25D).withValues(alpha: 0.3),
          width: 1.5,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5B25D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_special,
                  color: Color(0xFFE5B25D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'মোট মামলা',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$_totalCases টি',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5B25D),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.white12,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusChip(
                label: 'চলমান',
                count: _activeCases,
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 16),
              _buildStatusChip(
                label: 'নিষ্পত্তি',
                count: _disposedCases,
                color: Colors.blueAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count টি',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'দ্রুত সেবা',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE5B25D),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'সব দেখুন',
                style: TextStyle(
                  color: Color(0xFFE5B25D),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                    builder: (context) => const CaseListScreen(),
                  ),
                );
                if (mounted) {
                  _fetchStats();
                  _fetchRecentCases();
                }
              },
            ),
            _buildQuickActionItem(
              icon: Icons.folder_open,
              label: 'আমার মামলা\nসমূহ',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CaseListScreen(),
                  ),
                );
                if (mounted) {
                  _fetchStats();
                  _fetchRecentCases();
                }
              },
            ),
            _buildQuickActionItem(
              icon: Icons.calendar_month,
              label: 'শুনানির তারিখ\nও সময়',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('ক্যালেন্ডার স্ক্রিন শীঘ্রই আসছে')),
                );
              },
            ),
            _buildQuickActionItem(
              icon: Icons.menu_book,
              label: 'আইনকোষ /\nপ্রোফাইল',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('আইনকোষ শীঘ্রই আসছে')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2C3E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5B25D).withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFE5B25D),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCases() {
    if (_recentCases.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'সাম্প্রতিক মামলা',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE5B25D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2C3E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Center(
              child: Text(
                'এখনো কোনো মামলা যোগ করা হয়নি',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
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
            const Text(
              'সাম্প্রতিক মামলা',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE5B25D),
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CaseListScreen(),
                  ),
                );
                if (mounted) {
                  _fetchStats();
                  _fetchRecentCases();
                }
              },
              child: const Text(
                'সব দেখুন',
                style: TextStyle(color: Color(0xFFE5B25D), fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentCases.map((caseData) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildCaseCard(caseData),
            )),
      ],
    );
  }

  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    final caseType = caseData['case_type'] ?? 'অন্যান্য';
    final caseNumber = caseData['case_number'] ?? '';
    final title = caseData['title'] ?? '';
    final courtName = caseData['court_name'] ?? '';
    final nextHearing = caseData['next_hearing_date'];
    final status = caseData['status'] ?? 'Active';

    final icon = _getCaseIcon(caseType);
    final iconColor = _getCaseColor(caseType);
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(14),
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
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
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
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
        ],
      ),
    );
  }
}
