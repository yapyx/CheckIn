import 'package:flutter/material.dart';

import '../models/signup_form_data.dart';
import '../widgets/brand_header.dart';
import '../widgets/screen_frame.dart';
import '../widgets/text_entry.dart';
import '../widgets/trust_footer.dart';

enum RegistrationKind { senior, caregiver }

class SignupScreen extends StatefulWidget {
  const SignupScreen.senior({
    required this.onCreate,
    required this.onCancel,
    super.key,
  }) : kind = RegistrationKind.senior;

  const SignupScreen.caregiver({
    required this.onCreate,
    required this.onCancel,
    super.key,
  }) : kind = RegistrationKind.caregiver;

  final RegistrationKind kind;
  final Future<void> Function(SignupFormData data) onCreate;
  final VoidCallback onCancel;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _specializationsController =
      TextEditingController();
  bool _passwordVisible = false;
  bool _agreed = false;
  bool _isSubmitting = false;
  String? _errorText;
  String _occupation = 'Nurse';

  bool get _isSenior => widget.kind == RegistrationKind.senior;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _ageController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    _specializationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      backgroundColor: const Color(0xFFF5F6F8),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const BrandHeader(),
          const SizedBox(height: 24),
          Text(_isSenior ? 'Join CheckIn' : 'Create Caregiver Account',
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  height: 1.2)),
          const SizedBox(height: 8),
          Text(
            _isSenior
                ? 'Set up your account so trusted people can support your daily care.'
                : 'Set up your care team account to support someone safely.',
            style: const TextStyle(
                fontSize: 17, color: Color(0xFF6B7280), height: 1.35),
          ),
          const SizedBox(height: 24),
          if (_isSenior) ..._seniorFields() else ..._caregiverFields(),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_errorText!,
                  style: const TextStyle(
                      color: Color(0xFFB42318), fontSize: 15, height: 1.3)),
            ),
          const SizedBox(height: 8),
          _PrimaryFormButton(
            label: _isSubmitting ? 'Creating...' : 'Create',
            onPressed: _isSubmitting ? null : _submit,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: widget.onCancel,
            child: Text(_isSenior ? '← Go Back' : 'Cancel'),
          ),
          const TrustFooter(),
        ],
      ),
    );
  }

  List<Widget> _seniorFields() {
    return [
      TextEntry(
          label: 'User ID',
          placeholder: 'e.g. senior-mary',
          controller: _userIdController),
      TextEntry(
        label: 'Create Password',
        placeholder: 'Choose a safe password',
        controller: _passwordController,
        obscureText: !_passwordVisible,
        suffixIcon: _PasswordToggle(
          visible: _passwordVisible,
          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
        ),
      ),
      TextEntry(
          label: 'Display Name',
          placeholder: 'e.g. Mary Tan',
          controller: _displayNameController),
      TextEntry(
          label: 'Age',
          placeholder: 'e.g. 75',
          controller: _ageController,
          keyboardType: TextInputType.number),
      TextEntry(
          label: 'Health Conditions',
          placeholder: 'e.g. Hypertension, Diabetes',
          controller: _conditionsController),
      TextEntry(
          label: 'Routine / Other Information',
          placeholder: 'e.g. Lives alone, morning medication at 8am',
          controller: _notesController),
    ];
  }

  List<Widget> _caregiverFields() {
    return [
      TextEntry(
          label: 'User ID',
          placeholder: 'e.g. caregiver-sarah',
          controller: _userIdController),
      TextEntry(
        label: 'Create Password',
        placeholder: 'Minimum 12 characters',
        controller: _passwordController,
        obscureText: !_passwordVisible,
        suffixIcon: _PasswordToggle(
          visible: _passwordVisible,
          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
        ),
      ),
      TextEntry(
          label: 'Display Name',
          placeholder: 'e.g. Sarah Lim',
          controller: _displayNameController),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<String>(
          initialValue: _occupation,
          decoration: InputDecoration(
            labelText: 'Occupation',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  const BorderSide(color: Color(0xFF0B63C9), width: 1.4),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
          items: const [
            DropdownMenuItem(value: 'Nurse', child: Text('Nurse')),
            DropdownMenuItem(value: 'Doctor', child: Text('Doctor')),
            DropdownMenuItem(value: 'Caregiver', child: Text('Caregiver')),
            DropdownMenuItem(
                value: 'Social Worker', child: Text('Social Worker')),
            DropdownMenuItem(value: 'Volunteer', child: Text('Volunteer')),
            DropdownMenuItem(
                value: 'Family Member', child: Text('Family Member')),
            DropdownMenuItem(value: 'Other', child: Text('Other')),
          ],
          onChanged: (value) =>
              setState(() => _occupation = value ?? _occupation),
        ),
      ),
      TextEntry(
          label: 'Others/Specializations',
          placeholder: 'List relationship or certifications',
          controller: _specializationsController),
      CheckboxListTile(
        value: _agreed,
        onChanged: (value) => setState(() => _agreed = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        activeColor: const Color(0xFF0B63C9),
        title: const Text(
            'I agree to the Data Processing Agreement and Terms of Conduct.',
            style: TextStyle(
                fontSize: 15, color: Color(0xFF4B5563), height: 1.35)),
      ),
    ];
  }

  Future<void> _submit() async {
    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();
    if (userId.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Please enter a User ID and Password.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorText = 'Password must be at least 8 characters.');
      return;
    }
    if (!_isSenior && !_agreed) {
      setState(
          () => _errorText = 'Please agree to the Data Processing Agreement.');
      return;
    }

    final contextParts = [
      if (_ageController.text.trim().isNotEmpty)
        'Age: ${_ageController.text.trim()}',
      if (_conditionsController.text.trim().isNotEmpty)
        'Health conditions: ${_conditionsController.text.trim()}',
      if (_notesController.text.trim().isNotEmpty) _notesController.text.trim(),
    ];

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await widget.onCreate(
        SignupFormData(
          userId: userId,
          password: password,
          displayName: _displayNameController.text.trim(),
          profileContext: contextParts.join('. '),
          occupation: _isSenior
              ? ''
              : [_occupation, _specializationsController.text.trim()]
                  .where((item) => item.isNotEmpty)
                  .join(' - '),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorText = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _PasswordToggle extends StatelessWidget {
  const _PasswordToggle({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
      color: const Color(0xFF6B7280),
      tooltip: visible ? 'Hide password' : 'Show password',
    );
  }
}

class _PrimaryFormButton extends StatelessWidget {
  const _PrimaryFormButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0B63C9),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(58),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
      ),
      child: Text(label),
    );
  }
}
