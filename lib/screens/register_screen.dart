import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';

  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _picker = ImagePicker();
  File? _faceImage;
  final _auth = AuthService();
  bool _busy = false;

  late AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  final List<Color> _colors = [
    Colors.blue.shade100,
    Colors.purple.shade100,
    Colors.cyan.shade100,
    Colors.teal.shade100,
    Colors.indigo.shade100,
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _setAnimations();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _setAnimations();
        _controller.forward();
      }
    });
    _controller.forward();
  }

  void _setAnimations() {
    final random = Random();
    final i = random.nextInt(_colors.length);
    final j = random.nextInt(_colors.length);
    _color1 = ColorTween(begin: _colors[i], end: _colors[j]).animate(_controller);
    _color2 = ColorTween(begin: _colors[j], end: _colors[i]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _employeeIdCtl.dispose();
    _passwordCtl.dispose();
    _nameCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  Future<void> _captureFace() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera);
    if (img != null) {
      setState(() => _faceImage = File(img.path));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_faceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture your face photo.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final success = await _auth.register(
        employeeId: _employeeIdCtl.text.trim(),
        password: _passwordCtl.text.trim(),
        name: _nameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        faceImage: _faceImage,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during registration: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_color1.value!, _color2.value!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Icon(Icons.person_add_alt,
                          size: 80, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 16),
                      _field(_employeeIdCtl, 'Employee ID', Icons.badge),
                      const SizedBox(height: 16),
                      _field(_nameCtl, 'Full Name', Icons.person),
                      const SizedBox(height: 16),
                      _field(
                        _emailCtl,
                        'Email',
                        Icons.email,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        _passwordCtl,
                        'Password',
                        Icons.lock,
                        obscure: true,
                        validator: (v) => v == null || v.length < 6
                            ? 'Min 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      _faceImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_faceImage!, height: 150),
                      )
                          : Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: const Center(child: Text('No face captured')),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _busy ? null : _captureFace,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Capture Face Photo'),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : _register,
                          icon: _busy
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                              : const Icon(Icons.app_registration),
                          label: Text(_busy ? 'Registering...' : 'Register'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field(
      TextEditingController ctl,
      String label,
      IconData icon, {
        bool obscure = false,
        TextInputType keyboard = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: ctl,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator ?? (v) => v == null || v.isEmpty ? 'Please enter $label' : null,
    );
  }
}
