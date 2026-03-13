import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _currentStep = 0; // 0: Email, 1: Security Questions, 2: New Password
  
  DateTime? _selectedDate;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _handleVerifyEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.verifySecurityQuestions(
        email: _emailController.text.trim(),
      );
      
      setState(() => _isLoading = false);
      
      if (success) {
        setState(() => _currentStep = 1);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifySecurity() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.verifySecurityAnswers(
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _dobController.text,
      );
      
      setState(() => _isLoading = false);
      
      if (success) {
        setState(() => _currentStep = 2);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.resetPassword(
        email: _emailController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      
      setState(() => _isLoading = false);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully! Please login with your new password.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Indicator
                _buildProgressIndicator(),
                
                const SizedBox(height: 32),
                
                // Step Content
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentStep == 0 
                    ? _buildEmailStep() 
                    : _currentStep == 1 
                      ? _buildSecurityQuestionsStep() 
                      : _buildNewPasswordStep(),
                ),
                
                // Error Message
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.errorColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  auth.error!,
                                  style: const TextStyle(color: AppTheme.errorColor),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: auth.clearError,
                                color: AppTheme.errorColor,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStepCircle(0, 'Email', Icons.email_outlined),
        Expanded(child: Container(height: 2, color: _currentStep > 0 ? AppTheme.primaryColor : Colors.grey.shade300)),
        _buildStepCircle(1, 'Verify', Icons.security),
        Expanded(child: Container(height: 2, color: _currentStep > 1 ? AppTheme.primaryColor : Colors.grey.shade300)),
        _buildStepCircle(2, 'Reset', Icons.lock_reset),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppTheme.primaryColor : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey('email_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: AppTheme.primaryColor.withOpacity(0.7),
        ).animate().fadeIn(duration: 400.ms).scale(),
        
        const SizedBox(height: 24),
        
        Text(
          'Enter your email',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'We\'ll verify your identity using your registered details',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your registered email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
        
        const SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: _isLoading ? null : _handleVerifyEmail,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
          child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Continue'),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSecurityQuestionsStep() {
    return Column(
      key: const ValueKey('security_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 64,
          color: AppTheme.primaryColor.withOpacity(0.7),
        ).animate().fadeIn(duration: 400.ms).scale(),
        
        const SizedBox(height: 24),
        
        Text(
          'Verify your identity',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Please provide your full name and date of birth as registered',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        TextFormField(
          controller: _fullNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
        
        const SizedBox(height: 20),
        
        TextFormField(
          controller: _dobController,
          readOnly: true,
          onTap: () => _selectDate(context),
          decoration: const InputDecoration(
            labelText: 'Date of Birth',
            hintText: 'Select your date of birth',
            prefixIcon: Icon(Icons.calendar_today_outlined),
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your date of birth';
            }
            return null;
          },
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
        
        const SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: _isLoading ? null : _handleVerifySecurity,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
          child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Verify'),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildNewPasswordStep() {
    return Column(
      key: const ValueKey('password_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.lock_reset,
          size: 64,
          color: AppTheme.primaryColor.withOpacity(0.7),
        ).animate().fadeIn(duration: 400.ms).scale(),
        
        const SizedBox(height: 24),
        
        Text(
          'Create new password',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Your identity has been verified. Set your new password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'New Password',
            hintText: 'Enter new password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
        
        const SizedBox(height: 20),
        
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleResetPassword(),
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Confirm new password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _newPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
        
        const SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: _isLoading ? null : _handleResetPassword,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
          child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Reset Password'),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}
