import 'package:flutter/material.dart';
import '../services/client_service.dart';

class EditClientScreen extends StatefulWidget {
  final Map<String, dynamic> clientData;

  const EditClientScreen({super.key, required this.clientData});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _clientService = ClientService();
  final _formKey = GlobalKey<FormState>();

  // কন্ট্রোলার
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // ✅ প্রি-ফিল করা (বর্তমান ক্লায়েন্ট ডেটা দিয়ে)
    _nameController =
        TextEditingController(text: widget.clientData['name'] ?? '');
    _phoneController =
        TextEditingController(text: widget.clientData['phone'] ?? '');
    _emailController =
        TextEditingController(text: widget.clientData['email'] ?? '');
    _addressController =
        TextEditingController(text: widget.clientData['address'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _clientService.updateClient(
        clientId: widget.clientData['id'],
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ক্লায়েন্ট সফলভাবে আপডেট হয়েছে')),
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
        title: const Text('ক্লায়েন্ট এডিট করুন'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // নাম
              _buildSectionLabel('ক্লায়েন্টের নাম *'),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('ক্লায়েন্টের নাম'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'ক্লায়েন্টের নাম লিখুন'
                    : null,
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

              // ইমেইল
              _buildSectionLabel('ইমেইল'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('ইমেইল (ঐচ্ছিক)'),
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
                  onPressed: _isSaving ? null : _updateClient,
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
