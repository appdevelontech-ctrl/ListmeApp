import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/profile_controller.dart';
import '../../models/auth/user_model.dart';

// Define the base URL for your API (adjust this based on your backend)
const String baseUrl = 'https://listmein.onrender.com'; // Ensure no trailing slash

class EditProfileView extends StatefulWidget {
  final User user;

  const EditProfileView({super.key, required this.user});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _statenameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  List<String> _coverage = [];
  List<String> _department = [];
  File? _profileImage;
  String _gender = '1'; // Default to '1' (Male)

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.user.username;
    _phoneController.text = widget.user.phone;
    _emailController.text = widget.user.email;
    _pincodeController.text = widget.user.pincode;
    _dobController.text = widget.user.dob;
    _addressController.text = widget.user.address;
    _cityController.text = widget.user.city;
    _stateController.text = widget.user.state;
    _statenameController.text = widget.user.statename;
    _coverage = List.from(widget.user.coverage);
    _department = List.from(widget.user.department);
    _gender = widget.user.status.isNotEmpty && ['1', '2'].contains(widget.user.status)
        ? widget.user.status
        : '1';
    print('Initialized _gender: $_gender, user.status: ${widget.user.status}');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Colors.tealAccent : Colors.teal;
    final cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;

    // Construct the full URL for the profile image
    String? profileUrl = widget.user.profile.isNotEmpty
        ? Uri.parse(baseUrl).resolve(widget.user.profile).toString()
        : null;
    print('Constructed profile URL: $profileUrl'); // Debug log

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Consumer<ProfileController>(
          builder: (context, controller, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      child: child,
                    ),
                    child: CircleAvatar(
                      radius: screenWidth * 0.12,
                      backgroundColor: primaryColor,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : profileUrl != null
                          ? NetworkImage(profileUrl)
                          : null,
                      child: (_profileImage == null && (profileUrl == null || profileUrl.isEmpty))
                          ? Icon(Icons.add_a_photo, size: screenWidth * 0.06, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildTextField(controller: _usernameController, label: 'Username'),
                _buildTextField(controller: _phoneController, label: 'Phone', keyboardType: TextInputType.phone),
                _buildTextField(controller: _emailController, label: 'Email', keyboardType: TextInputType.emailAddress),
                _buildTextField(controller: _pincodeController, label: 'Pincode', keyboardType: TextInputType.number),
                _buildTextField(controller: _dobController, label: 'Date of Birth', hintText: 'YYYY-MM-DD'),
                _buildTextField(controller: _addressController, label: 'Address', maxLines: 2),
                _buildTextField(controller: _cityController, label: 'City'),
                _buildTextField(controller: _stateController, label: 'State ID'),
                _buildTextField(controller: _statenameController, label: 'State Name'),
                _buildTextField(controller: _passwordController, label: 'Password *', obscureText: true),
                _buildTextField(controller: _confirmPasswordController, label: 'Confirm Password *', obscureText: true),

                // Gender Dropdown
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: '1',
                        child: Text('Male'),
                      ),
                      DropdownMenuItem<String>(
                        value: '2',
                        child: Text('Female'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _gender = newValue;
                        });
                      }
                    },
                  ),
                ),

                // Coverage and Department (Simplified as Text Fields for now)
                _buildTextField(controller: TextEditingController(text: _coverage.join(', ')), label: 'Coverage', onChanged: (value) {
                  setState(() {
                    _coverage = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  });
                }),
                _buildTextField(controller: TextEditingController(text: _department.join(', ')), label: 'Department', onChanged: (value) {
                  setState(() {
                    _department = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  });
                }),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: controller.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(controller.isLoading ? 'Saving...' : 'Save Profile', style: const TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: controller.isLoading
                        ? null
                        : () async {
                      // Validate password and confirm password are mandatory and match
                      final password = _passwordController.text.trim();
                      final confirmPassword = _confirmPasswordController.text.trim();
                      if (password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password is required')));
                        return;
                      }
                      if (confirmPassword.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirm Password is required')));
                        return;
                      }
                      if (password != confirmPassword) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                        return;
                      }

                      await controller.updateProfile(
                        username: _usernameController.text,
                        phone: _phoneController.text,
                        email: _emailController.text,
                        password: password,
                        confirmPassword: confirmPassword,
                        pincode: _pincodeController.text,
                        gender: _gender,
                        dob: _dobController.text,
                        address: _addressController.text,
                        coverage: _coverage,
                        department: _department,
                        state: _stateController.text,
                        statename: _statenameController.text,
                        city: _cityController.text,
                        profileImage: _profileImage,
                      );
                      if (controller.errorMessage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}