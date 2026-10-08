import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  String _userName = 'অ্যাডভোকেট';
  String _userEmail = '';
  String _userPhone = '';
  String _userAddress = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final resp = await _supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        setState(() {
          if (resp != null) {
            _userName = resp['full_name'] ?? 'অ্যাডভোকেট';
            _userEmail = resp['email'] ?? '';
            _userPhone = resp['phone'] ?? '';
            _userAddress = resp['address'] ?? '';
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5B25D)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // প্রোফাইল কার্ড
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2C3E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(0xFF07384A),
                          child: Icon(Icons.person,
                              size: 48, color: Color(0xFFE5B25D)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on,
                                color: Color(0xFFE5B25D), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _userAddress.isNotEmpty
                                  ? _userAddress
                                  : 'ঠিকানা যোগ করুন',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.email, _userEmail),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.phone, _userPhone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // মেনু আইটেম
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'ব্যক্তিগত তথ্য',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'নিরাপত্তা ও গোপনীয়তা',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.language,
                    title: 'ভাষা',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'সহায়তা ও সাপোর্ট',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'অ্যাপ সম্পর্কে',
                    onTap: () {},
                  ),

                  const SizedBox(height: 20),

                  // লগআউট বাটন
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('লগআউট'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5B25D),
                        foregroundColor: const Color(0xFF032836),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE5B25D), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'যোগ করা হয়নি',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ✅ Card ব্যবহার করা হলো (ওয়ার্নিং ঠিক করার জন্য)
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF0F2C3E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFFE5B25D)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white38, size: 14),
      ),
    );
  }
}
