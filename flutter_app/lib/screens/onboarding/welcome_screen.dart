import 'package:flutter/material.dart';

import '../../models/role.dart';
import '../../models/signup_form_data.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/screen_frame.dart';

enum _AuthTab { signUp, signIn }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    required this.onCreateAccount,
    required this.onSignIn,
    super.key,
  });

  final ValueChanged<Role> onCreateAccount;
  final ValueChanged<LoginFormData> onSignIn;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _loginUserIdController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  _AuthTab _selectedTab = _AuthTab.signUp;
  Role? _selectedRole;
  Role _signInRole = Role.caregiver;
  bool _showRoleValidation = false;
  bool _showLoginValidation = false;
  bool _loginPasswordVisible = false;

  @override
  void dispose() {
    _loginUserIdController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      backgroundColor: const Color(0xFFF5F6F8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          children: [
            const BrandHeader(),
            const SizedBox(height: 12),
            const _HeroCard(),
            const SizedBox(height: 14),
            _WelcomeTabs(
              selectedTab: _selectedTab,
              onChanged: (tab) {
                setState(() {
                  _selectedTab = tab;
                  _showRoleValidation = false;
                  _showLoginValidation = false;
                });
              },
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _selectedTab == _AuthTab.signUp
                  ? _buildSignUpContent()
                  : _buildSignInContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpContent() {
    return Column(
      key: const ValueKey('sign-up'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Tell us who you are',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                height: 1.25)),
        const SizedBox(height: 14),
        _RoleCard(
          role: Role.senior,
          selectedRole: _selectedRole,
          icon: Icons.elderly_rounded,
          title: 'I am a Senior',
          subtitle: 'I want support with daily care',
          onTap: (role) => setState(() {
            _selectedRole = role;
            _showRoleValidation = false;
          }),
        ),
        const SizedBox(height: 10),
        _RoleCard(
          role: Role.caregiver,
          selectedRole: _selectedRole,
          icon: Icons.support_agent_rounded,
          title: 'I am a Caregiver',
          subtitle: 'I am here to support someone',
          onTap: (role) => setState(() {
            _selectedRole = role;
            _showRoleValidation = false;
          }),
        ),
        if (_showRoleValidation) ...[
          const SizedBox(height: 8),
          const Text('Please choose Senior or Caregiver to continue.',
              style: TextStyle(
                  color: Color(0xFFB42318), fontSize: 13, height: 1.3)),
        ],
        const SizedBox(height: 18),
        _PrimaryWelcomeButton(
          label: 'Create New Account',
          onPressed: () {
            final role = _selectedRole;
            if (role == null) {
              setState(() => _showRoleValidation = true);
              return;
            }
            widget.onCreateAccount(role);
          },
        ),
      ],
    );
  }

  Widget _buildSignInContent() {
    return Column(
      key: const ValueKey('sign-in'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Text('Welcome Back',
            style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                height: 1.2)),
        const SizedBox(height: 4),
        const Text('Sign in to continue your care journey.',
            style: TextStyle(
                fontSize: 14, color: Color(0xFF6B7280), height: 1.25)),
        const SizedBox(height: 12),
        const Text('Sign in as',
            style: TextStyle(
                fontSize: 14,
                color: Color(0xFF0B1F33),
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        _SignInRoleSelector(
          selectedRole: _signInRole,
          onChanged: (role) => setState(() => _signInRole = role),
        ),
        const SizedBox(height: 10),
        _AuthTextField(
          controller: _loginUserIdController,
          label: 'User ID',
          placeholder: 'Enter your User ID',
        ),
        _AuthTextField(
          controller: _loginPasswordController,
          label: 'Password',
          placeholder: 'Enter your password',
          obscureText: !_loginPasswordVisible,
          suffixIcon: IconButton(
            onPressed: () =>
                setState(() => _loginPasswordVisible = !_loginPasswordVisible),
            icon: Icon(_loginPasswordVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
            color: const Color(0xFF6B7280),
            tooltip: _loginPasswordVisible ? 'Hide password' : 'Show password',
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text('Forgot password?',
                style: TextStyle(
                    color: Color(0xFF0B63C9), fontWeight: FontWeight.w600)),
          ),
        ),
        if (_showLoginValidation)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Please enter both User ID and Password.',
                style: TextStyle(
                    color: Color(0xFFB42318), fontSize: 15, height: 1.3)),
          ),
        _PrimaryWelcomeButton(
          label: 'Sign In',
          onPressed: () {
            final userId = _loginUserIdController.text.trim();
            final password = _loginPasswordController.text.trim();
            if (userId.isEmpty || password.isEmpty) {
              setState(() => _showLoginValidation = true);
              return;
            }
            widget.onSignIn(LoginFormData(
              role: _signInRole,
              userId: userId,
              password: password,
            ));
          },
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _selectedTab = _AuthTab.signUp;
              _showLoginValidation = false;
            }),
            child: const Text('New to CheckIn? Create an account',
                style: TextStyle(
                    color: Color(0xFF0B63C9), fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _SignInRoleSelector extends StatelessWidget {
  const _SignInRoleSelector(
      {required this.selectedRole, required this.onChanged});

  final Role selectedRole;
  final ValueChanged<Role> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          _RoleSegment(
              label: 'Senior',
              selected: selectedRole == Role.senior,
              onTap: () => onChanged(Role.senior)),
          _RoleSegment(
              label: 'Caregiver',
              selected: selectedRole == Role.caregiver,
              onTap: () => onChanged(Role.caregiver)),
        ],
      ),
    );
  }
}

class _RoleSegment extends StatelessWidget {
  const _RoleSegment(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: selected
                ? const [
                    BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 8,
                        offset: Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected ? const Color(0xFF0B63C9) : const Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeTabs extends StatelessWidget {
  const _WelcomeTabs({required this.selectedTab, required this.onChanged});

  final _AuthTab selectedTab;
  final ValueChanged<_AuthTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          _TabOption(
              label: 'Sign Up',
              selected: selectedTab == _AuthTab.signUp,
              onTap: () => onChanged(_AuthTab.signUp)),
          _TabOption(
              label: 'Sign In',
              selected: selectedTab == _AuthTab.signIn,
              onTap: () => onChanged(_AuthTab.signIn)),
        ],
      ),
    );
  }
}

class _TabOption extends StatelessWidget {
  const _TabOption(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: selected
                ? const [
                    BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected ? const Color(0xFF0B63C9) : const Color(0xFF4B5563),
              fontWeight: FontWeight.w600,
              fontSize: 14,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Image.asset(
          'assets/home page.png',
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selectedRole,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Role role;
  final Role? selectedRole;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<Role> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = role == selectedRole;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: const Color(0x0F000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onTap(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF3FF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? const Color(0xFF0B63C9)
                    : const Color(0xFFE5E7EB),
                width: selected ? 1.6 : 1.1),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFEAF3FF),
                  child: Icon(icon, color: const Color(0xFF0B63C9), size: 23)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1A1A1A),
                            height: 1.22)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                            fontWeight: FontWeight.w400,
                            height: 1.28)),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: selected ? 1 : 0,
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF0B63C9), size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryWelcomeButton extends StatelessWidget {
  const _PrimaryWelcomeButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
              color: Color(0x2A0B63C9), blurRadius: 9, offset: Offset(0, 4))
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B63C9),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(60),
          fixedSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, height: 1.15),
        ),
        child: Text(label),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.placeholder,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String placeholder;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF0B63C9), width: 1.4),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}
