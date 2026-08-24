import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_colors.dart';

class ManageDeliveryMenScreen extends StatefulWidget {
  const ManageDeliveryMenScreen({Key? key}) : super(key: key);

  @override
  State<ManageDeliveryMenScreen> createState() => _ManageDeliveryMenScreenState();
}

class _ManageDeliveryMenScreenState extends State<ManageDeliveryMenScreen> {
  bool _isLoading = true;
  List<dynamic> _deliveryMen = [];

  @override
  void initState() {
    super.initState();
    _fetchDeliveryMen();
  }

  Future<void> _fetchDeliveryMen() async {
    setState(() => _isLoading = true);
    final data = await ApiService.get('/suppliers/delivery-men');
    if (mounted) {
      setState(() {
        _deliveryMen = data ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_add_rounded, color: AppColors.primaryTeal),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Add Delivery Man',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Form Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildModernLabel('Full Name'),
                            const SizedBox(height: 8),
                            _buildModernTextField(
                              controller: nameController,
                              hintText: 'e.g. John Doe',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 20),
                            
                            _buildModernLabel('Phone Number'),
                            const SizedBox(height: 8),
                            _buildModernTextField(
                              controller: phoneController,
                              hintText: 'e.g. 017...',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 20),
                            
                            _buildModernLabel('Temporary Password'),
                            const SizedBox(height: 8),
                            _buildModernTextField(
                              controller: passwordController,
                              hintText: 'Create a password',
                              icon: Icons.lock_outline,
                              obscureText: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Footer Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              foregroundColor: AppColors.textSecondary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final name = nameController.text.trim();
                                    final phone = phoneController.text.trim();
                                    final pass = passwordController.text.trim();
                                    
                                    if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('All fields are required'),
                                          backgroundColor: AppColors.cancelled,
                                        ),
                                      );
                                      return;
                                    }

                                    setDialogState(() => isSubmitting = true);
                                    final res = await ApiService.post('/suppliers/delivery-men', body: {
                                      'fullName': name,
                                      'phoneNumber': phone,
                                      'password': pass,
                                    });
                                    setDialogState(() => isSubmitting = false);
                                    
                                    if (res != null) {
                                      Navigator.pop(context);
                                      _fetchDeliveryMen();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Delivery man added successfully!'),
                                          backgroundColor: AppColors.primaryTeal,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to add delivery man or phone already exists'),
                                          backgroundColor: AppColors.cancelled,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSubmitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Delivery Men'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : _deliveryMen.isEmpty
              ? const Center(child: Text('No delivery men added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _deliveryMen.length,
                  itemBuilder: (context, index) {
                    final dm = _deliveryMen[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                          child: const Icon(Icons.delivery_dining, color: AppColors.primaryTeal),
                        ),
                        title: Text(dm['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(dm['phone_number'] ?? ''),
                        trailing: dm['force_password_reset'] == true 
                            ? const Tooltip(
                                message: 'Waiting for password reset',
                                child: Icon(Icons.pending_actions, color: Colors.orange))
                            : const Icon(Icons.check_circle, color: Colors.green),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
