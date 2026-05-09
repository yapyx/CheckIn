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
  final ValueChanged<SignupFormData> onCreate;
  final VoidCallback onCancel;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _healthController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _specializationsController =
      TextEditingController();
  bool _passwordVisible = false;
  bool _agreed = false;
  String _occupation = 'Nurse';

  bool get _isSenior => widget.kind == RegistrationKind.senior;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _healthController.dispose();
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
          const SizedBox(height: 8),
          _PrimaryFormButton(onPressed: _submit),
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
        controller: _userIdController,
        label: 'User ID',
        placeholder: 'Enter your unique ID',
      ),
      TextEntry(
        controller: _passwordController,
        label: 'Create Password',
        placeholder: 'Choose a safe password',
        obscureText: !_passwordVisible,
        suffixIcon: _PasswordToggle(
          visible: _passwordVisible,
          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
        ),
      ),
      TextEntry(
        controller: _ageController,
        label: 'Age',
        placeholder: 'e.g. 75',
        keyboardType: TextInputType.number,
      ),
      TextEntry(
        controller: _healthController,
        label: 'Health Conditions',
        placeholder: 'e.g. Hypertension, Diabetes',
      ),
      TextEntry(
        controller: _notesController,
        label: 'Notes / Other Information',
        placeholder: 'Anything else we should know?',
      ),
    ];
  }

  List<Widget> _caregiverFields() {
    return [
      TextEntry(
        controller: _userIdController,
        label: 'User ID',
        placeholder: 'Enter your official staff ID',
      ),
      TextEntry(
        controller: _passwordController,
        label: 'Create Password',
        placeholder: 'Minimum 12 characters',
        obscureText: !_passwordVisible,
        suffixIcon: _PasswordToggle(
          visible: _passwordVisible,
          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
        ),
      ),
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
        controller: _specializationsController,
        label: 'Others/Specializations',
        placeholder: 'List certifications (e.g., Dementia Care)',
      ),
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

  void _submit() {
    final profileParts = <String>[
      if (_ageController.text.trim().isNotEmpty)
        'Age: ${_ageController.text.trim()}',
      if (_healthController.text.trim().isNotEmpty)
        'Health conditions: ${_healthController.text.trim()}',
      if (_notesController.text.trim().isNotEmpty)
        'Notes: ${_notesController.text.trim()}',
    ];
    widget.onCreate(SignupFormData(
      userId: _userIdController.text.trim(),
      password: _passwordController.text.trim(),
      displayName: _userIdController.text.trim(),
      profileContext: profileParts.join('\n'),
      occupation: _isSenior
          ? ''
          : '$_occupation ${_specializationsController.text.trim()}'.trim(),
    ));
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
  const _PrimaryFormButton({required this.onPressed});

  final VoidCallback onPressed;

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
      child: const Text('Create'),
    );
  }
}
