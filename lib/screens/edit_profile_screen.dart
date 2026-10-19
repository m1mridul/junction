import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfileScreen({super.key, required this.profileData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileData['full_name'] ?? '');
    _phoneController = TextEditingController(text: widget.profileData['phone'] ?? '');
    _addressController = TextEditingController(text: widget.profileData['address'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _profileService.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('প্রোফাইল সফলভাবে আপডেট হয়েছে')),
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
        title: const Text('প্রোফাইল এডিট করুন'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // নাম
              _buildSectionLabel('নাম *'),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('আপনার নাম'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'আপনার নাম লিখুন'
                    : null,
              ),
              const SizedBox(height: 20),

              // ইমেইল (রিড-অনলি, কারণ ইমেইল পরিবর্তন করা যায় না)
              _buildSectionLabel('ইমেইল'),
              TextFormField(
                initialValue: widget.profileData['email'] ?? '',
                enabled: false,
                style: const TextStyle(color: Colors.white54),
                decoration: _inputDecoration('ইমেইল (পরিবর্তনযোগ্য নয়)'),
              ),
              const SizedBox(height: 20),

              // ফোন
              _buildSectionLabel('ফোন নম্বর'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('ফোন নম্বর (ঐচ্ছিক)'),
              ),
              const SizedBox(height: 20),

              // ঠিকানা
              _buildSectionLabel('ঠিকানা'),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('ঠিকানা (ঐচ্ছিক)'),
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
                  onPressed: _isSaving ? null : _updateProfile,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF032836)),
                        )
                      : const Text(
                          'আপডেট করুন',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
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
        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5B25D))),
      disabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
      errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
    );
  }
}