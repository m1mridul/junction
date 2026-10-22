import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'case_list_screen.dart';
import 'case_detail_screen.dart';

// ───────────────────────── Design tokens ─────────────────────────
class _C {
  static const gold = Color(0xFFE5B25D);
  static const bgTop = Color(0xFF0A4558);
  static const bgBottom = Color(0xFF052C3A);
  static const card = Color(0xFF0E4A5C);
  static const cardBorder = Color(0xFF1F6B7E);
  static const iconCircle = Color(0xFF3B6D7B);
  static const navBg = Color(0xFF0A3B4C);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

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
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_fetchStats(), _fetchRecentCases()]);
  }

  // ───────────────────────── Data ─────────────────────────
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
      debugPrint('Error fetching stats: $e');
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
          setState(() => _recentCases = List<Map<String, dynamic>>.from(resp));
        }
      }
    } catch (e) {
      debugPrint('Error fetching recent cases: $e');
    }
  }

  // ───────────────────────── Helpers ─────────────────────────
  /// Converts any 0-9 digits to Bengali digits (১২৩...)
  String _bn(Object? v) => (v ?? '')
      .toString()
      .replaceAllMapped(RegExp(r'\d'), (m) => '০১২৩৪৫৬৭৮৯'[int.parse(m[0]!)]);

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
      return _bn('${dt.day} ${_getBengaliMonth(dt.month)} ${dt.year}');
    } catch (_) {
      return 'নির্ধারিত হয়নি';
    }
  }

  /// e.g. "সকাল ১০:০০টা", "দুপুর ২:৩০টা"
  String _formatTime(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'নির্ধারিত হয়নি';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final h = dt.hour;
      final hour12 = h % 12 == 0 ? 12 : h % 12;

      String period;
      if (h >= 4 && h < 12) {
        period = 'সকাল';
      } else if (h >= 12 && h < 16) {
        period = 'দুপুর';
      } else if (h >= 16 && h < 18) {
        period = 'বিকাল';
      } else if (h >= 18 && h < 20) {
        period = 'সন্ধ্যা';
      } else {
        period = 'রাত';
      }
      return '$period ${_bn(hour12)}:${_bn(dt.minute.toString().padLeft(2, '0'))}টা';
    } catch (_) {
      return 'নির্ধারিত হয়নি';
    }
  }

  IconData _getCaseIcon(String caseType) {
    switch (caseType) {
      case 'দেওয়ানি':
        return Icons.insert_drive_file_rounded;
      case 'ফৌজদারি':
        return Icons.gavel_rounded;
      case 'পারিবারিক':
        return Icons.family_restroom;
      case 'জমি সংক্রান্ত':
        return Icons.library_books_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  Color _getCaseColor(String caseType) {
    switch (caseType) {
      case 'দেওয়ানি':
        return const Color(0xFFF4A6A0);
      case 'ফৌজদারি':
        return Colors.white;
      case 'পারিবারিক':
        return const Color(0xFFD7B8F5);
      case 'জমি সংক্রান্ত':
        return const Color(0xFFCFE3E8);
      default:
        return _C.gold;
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

  /// (background, text, border)
  (Color, Color, Color) _getStatusStyle(String status) {
    switch (status) {
      case 'Active':
        return (
          const Color(0xFFFFE1E1),
          const Color(0xFFD32F2F),
          const Color(0xFFE57373)
        );
      case 'Pending':
        return (
          const Color(0xFFFFF0B8),
          const Color(0xFF8A6A00),
          const Color(0xFFE5C04B)
        );
      case 'Disposed':
        return (
          const Color(0xFFCDEBD0),
          const Color(0xFF2E7D32),
          const Color(0xFF81C784)
        );
      case 'Appealed':
        return (
          const Color(0xFFD6E6FF),
          const Color(0xFF1E5CB3),
          const Color(0xFF7FAEF0)
        );
      default:
        return (
          const Color(0xFFE0E0E0),
          const Color(0xFF616161),
          const Color(0xFFBDBDBD)
        );
    }
  }

  Future<void> _openCaseList() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CaseListScreen()));
    if (mounted) _loadAll();
  }

  void _soon(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ───────────────────────── Build ─────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgBottom,
      bottomNavigationBar: HomeBottomNav(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 1:
              _openCaseList();
              break;
            case 2:
              _soon('ক্যালেন্ডার স্ক্রিন শীঘ্রই আসছে');
              break;
            case 3:
              _soon('প্রোফাইল শীঘ্রই আসছে');
              break;
          }
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_C.bgTop, _C.bgBottom],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _C.gold))
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  color: _C.gold,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 18),
                        _buildTotalCasesCard(),
                        const SizedBox(height: 26),
                        _buildQuickActions(),
                        const SizedBox(height: 22),
                        _buildRecentCases(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ───────────────────────── Header ─────────────────────────
  Widget _buildHeader() {
    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -16,
            top: -16,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Colors.black],
                stops: [0.1, 0.7],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/home_bg.png',
                height: 115,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.gold.withValues(alpha: 0.6)),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF07384A),
                    backgroundImage:
                        _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null
                        ? const Icon(Icons.person, color: _C.gold, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 90),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'স্বাগতম, $_userName',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: _C.gold, size: 14),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Total cases card ─────────────────────────
  Widget _buildTotalCasesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _C.bgTop.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _C.gold.withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _C.iconCircle.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined,
                color: _C.gold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('মোট মামলা',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text('${_bn(_totalCases)}টি',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _C.gold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('চলমান: ${_bn(_activeCases)}টি',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    Container(
                      width: 1,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: Colors.white38,
                    ),
                    Text('নিষ্পত্তি: ${_bn(_disposedCases)}টি',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Section header ─────────────────────────
  Widget _sectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        InkWell(
          onTap: onSeeAll,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('সব দেখুন',
                    style: TextStyle(
                        color: _C.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, color: _C.gold, size: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Quick actions ─────────────────────────
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('দ্রুত সেবা', () => _soon('শীঘ্রই আসছে')),
        const SizedBox(height: 12),
        Row(
          children: [
            _quickItem(
              icon: Icons.note_add_outlined,
              label: 'নতুন মামলা\nযোগ করুন',
              onTap: _openCaseList,
            ),
            _quickItem(
              icon: Icons.folder_copy_outlined,
              label: 'আমার মামলা\nসমূহ',
              onTap: _openCaseList,
            ),
            _quickItem(
              icon: Icons.edit_calendar_outlined,
              label: 'শুনানির তারিখ\nও সময়',
              onTap: () => _soon('ক্যালেন্ডার স্ক্রিন শীঘ্রই আসছে'),
            ),
            _quickItem(
              icon: Icons.people_outline_rounded,
              label: 'আইনজীবী\nপ্রোফাইল',
              onTap: () => _soon('প্রোফাইল শীঘ্রই আসছে'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickItem(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _C.card.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.cardBorder),
              ),
              child: Icon(icon, color: _C.gold, size: 26),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Recent cases ─────────────────────────
  Widget _buildRecentCases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('সাম্প্রতিক মামলা', _openCaseList),
        const SizedBox(height: 10),
        if (_recentCases.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.cardBorder),
            ),
            child: const Center(
              child: Text('এখনো কোনো মামলা যোগ করা হয়নি',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          )
        else
          ..._recentCases.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCaseCard(c),
              )),
      ],
    );
  }

  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    final caseType = caseData['case_type'] ?? 'অন্যান্য';
    final caseNumber = _bn(caseData['case_number'] ?? '');
    final courtName = caseData['court_name'] ?? '';
    final nextHearing = caseData['next_hearing_date'];
    final status = caseData['status'] ?? 'Active';

    final (badgeBg, badgeText, badgeBorder) = _getStatusStyle(status);

    return InkWell(
      onTap: () async {
        final fullCaseData = await _supabase
            .from('cases')
            .select()
            .eq('id', caseData['id'])
            .maybeSingle();

        if (fullCaseData != null && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CaseDetailScreen(caseData: fullCaseData)),
          );
          if (mounted) _loadAll();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: _C.card.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                  color: _C.iconCircle, shape: BoxShape.circle),
              child: Icon(_getCaseIcon(caseType),
                  color: _getCaseColor(caseType), size: 24),
            ),
            const SizedBox(width: 12),
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeBorder),
                        ),
                        child: Text(_getStatusLabel(status),
                            style: TextStyle(
                                color: badgeText,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(courtName,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  _infoRow(Icons.calendar_month_outlined,
                      'শুনানির তারিখ: ${_formatDate(nextHearing)}'),
                  const SizedBox(height: 3),
                  _infoRow(Icons.access_time, _formatTime(nextHearing)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, color: _C.gold, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 13),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ───────────────────────── Bottom navigation ─────────────────────────
class HomeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HomeBottomNav(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'হোম'),
      (Icons.folder_open_rounded, 'মামলাসমূহ'),
      (Icons.calendar_month_outlined, 'ক্যালেন্ডার'),
      (Icons.person_outline_rounded, 'প্রোফাইল'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _C.navBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.gold.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == currentIndex;
            final color = selected ? _C.gold : Colors.white;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(items[i].$1, color: color, size: 26),
                    const SizedBox(height: 2),
                    Text(items[i].$2,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.w500)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
