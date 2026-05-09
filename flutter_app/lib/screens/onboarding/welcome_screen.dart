import 'package:flutter/material.dart';

import '../../models/role.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/screen_frame.dart';
import '../../widgets/trust_footer.dart';

enum _AuthTab { signUp, signIn }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    required this.onCreateAccount,
    required this.onSignIn,
    this.isLoading = false,
    this.errorText,
    super.key,
  });

  final ValueChanged<Role> onCreateAccount;
  final Future<void> Function(String userId, String password) onSignIn;
  final bool isLoading;
  final String? errorText;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _loginUserIdController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  _AuthTab _selectedTab = _AuthTab.signUp;
  Role? _selectedRole;
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 40),
        children: [
          const BrandHeader(),
          const SizedBox(height: 36),
          const _HeroCard(),
          const SizedBox(height: 38),
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
          const TrustFooter(),
        ],
      ),
    );
  }

  Widget _buildSignUpContent() {
    return Column(
      key: const ValueKey('sign-up'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text('Tell us who you are',
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                height: 1.25)),
        const SizedBox(height: 24),
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
        const SizedBox(height: 16),
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
          const SizedBox(height: 12),
          const Text('Please choose Senior or Caregiver to continue.',
              style: TextStyle(
                  color: Color(0xFFB42318), fontSize: 15, height: 1.3)),
        ],
        const SizedBox(height: 32),
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
        const SizedBox(height: 38),
        const Text('Welcome Back',
            style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                height: 1.2)),
        const SizedBox(height: 8),
        const Text('Sign in to continue your care journey.',
            style: TextStyle(
                fontSize: 17, color: Color(0xFF6B7280), height: 1.35)),
        const SizedBox(height: 24),
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
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(widget.errorText!,
                style: const TextStyle(
                    color: Color(0xFFB42318), fontSize: 15, height: 1.3)),
          ),
        _PrimaryWelcomeButton(
          label: widget.isLoading ? 'Signing In...' : 'Sign In',
          onPressed: widget.isLoading
              ? null
              : () async {
                  final userId = _loginUserIdController.text.trim();
                  final password = _loginPasswordController.text.trim();
                  if (userId.isEmpty || password.isEmpty) {
                    setState(() => _showLoginValidation = true);
                    return;
                  }
                  setState(() => _showLoginValidation = false);
                  await widget.onSignIn(userId, password);
                },
        ),
        const SizedBox(height: 12),
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

class _WelcomeTabs extends StatelessWidget {
  const _WelcomeTabs({required this.selectedTab, required this.onChanged});

  final _AuthTab selectedTab;
  final ValueChanged<_AuthTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 50,
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
      height: 350,
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
      child: const Padding(
        padding: EdgeInsets.fromLTRB(8, 28, 8, 22),
        child: CustomPaint(
          painter: _CareIllustrationPainter(),
          child: SizedBox.expand(),
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
          constraints: const BoxConstraints(minHeight: 109),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
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
                  radius: 28,
                  backgroundColor: const Color(0xFFEAF3FF),
                  child: Icon(icon, color: const Color(0xFF0B63C9), size: 28)),
              const SizedBox(width: 23),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1A1A1A),
                            height: 1.22)),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 17,
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
  final VoidCallback? onPressed;

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(
              fontSize: 23, fontWeight: FontWeight.w600, height: 1.15),
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
      padding: const EdgeInsets.only(bottom: 16),
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
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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

class _CareIllustrationPainter extends CustomPainter {
  const _CareIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final stroke = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF1F2937);

    final w = size.width;
    final h = size.height;
    final groundY = h * .77;

    final blob = Path()
      ..moveTo(w * .13, h * .56)
      ..cubicTo(w * .18, h * .22, w * .40, h * .27, w * .47, h * .29)
      ..cubicTo(w * .64, h * .32, w * .78, h * .18, w * .91, h * .30)
      ..cubicTo(w * 1.02, h * .40, w * .95, h * .69, w * .91, h * .76)
      ..lineTo(w * .08, h * .76)
      ..cubicTo(-w * .02, h * .71, w * .04, h * .63, w * .13, h * .56)
      ..close();
    paint.color = const Color(0xFF9CCDF3);
    canvas.drawPath(blob, paint);

    _drawPlant(canvas, size, stroke);
    _drawSofa(canvas, size, stroke);
    _drawCaregiver(canvas, size, stroke);
    _drawElder(canvas, size, stroke);

    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE5E7EB);
    canvas.drawRect(Rect.fromLTWH(w * .08, groundY, w * .84, 1.2), paint);
  }

  void _drawSofa(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..isAntiAlias = true;
    final sofa = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .18, h * .54, w * .70, h * .25),
        const Radius.circular(18));
    paint.color = const Color(0xFFAA9B90);
    canvas.drawRRect(sofa, paint);
    canvas.drawRRect(sofa, stroke);

    paint.color = const Color(0xFFC0B2A6);
    final leftCushion = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .22, h * .58, w * .25, h * .18),
        const Radius.circular(12));
    final rightCushion = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .52, h * .58, w * .27, h * .18),
        const Radius.circular(12));
    canvas.drawRRect(leftCushion, paint);
    canvas.drawRRect(rightCushion, paint);
    canvas.drawRRect(leftCushion, stroke);
    canvas.drawRRect(rightCushion, stroke);

    paint.color = const Color(0xFF8F8179);
    final leftArm = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .14, h * .61, w * .13, h * .18),
        const Radius.circular(12));
    final rightArm = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .78, h * .59, w * .13, h * .20),
        const Radius.circular(12));
    canvas.drawRRect(leftArm, paint);
    canvas.drawRRect(rightArm, paint);
    canvas.drawRRect(leftArm, stroke);
    canvas.drawRRect(rightArm, stroke);
  }

  void _drawPlant(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..isAntiAlias = true;
    final stem = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF2F6B4F);

    final baseX = w * .13;
    final baseY = h * .70;
    canvas.drawLine(Offset(baseX, baseY), Offset(baseX, h * .38), stem);
    for (final leaf in [
      Rect.fromLTWH(w * .08, h * .47, w * .08, h * .04),
      Rect.fromLTWH(w * .12, h * .42, w * .08, h * .04),
      Rect.fromLTWH(w * .06, h * .56, w * .09, h * .04),
      Rect.fromLTWH(w * .14, h * .53, w * .09, h * .04),
      Rect.fromLTWH(w * .09, h * .36, w * .08, h * .04),
    ]) {
      paint.color = const Color(0xFF5EA47D);
      canvas.drawOval(leaf, paint);
      canvas.drawOval(leaf, stroke);
    }

    paint.color = const Color(0xFFD7DBE2);
    final pot = Path()
      ..moveTo(w * .08, h * .69)
      ..lineTo(w * .18, h * .69)
      ..lineTo(w * .16, h * .77)
      ..lineTo(w * .10, h * .77)
      ..close();
    canvas.drawPath(pot, paint);
    canvas.drawPath(pot, stroke);
  }

  void _drawCaregiver(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..isAntiAlias = true;

    paint.color = const Color(0xFF4A2B28);
    canvas.drawOval(Rect.fromLTWH(w * .36, h * .33, w * .12, h * .15), paint);
    canvas.drawOval(Rect.fromLTWH(w * .31, h * .38, w * .14, h * .16), paint);

    paint.color = const Color(0xFFE9B28F);
    canvas.drawOval(Rect.fromLTWH(w * .34, h * .36, w * .12, h * .13), paint);
    canvas.drawOval(Rect.fromLTWH(w * .34, h * .36, w * .12, h * .13), stroke);

    paint.color = const Color(0xFF2E3B4E);
    final jacket = Path()
      ..moveTo(w * .26, h * .55)
      ..lineTo(w * .33, h * .46)
      ..lineTo(w * .48, h * .48)
      ..lineTo(w * .55, h * .76)
      ..lineTo(w * .28, h * .76)
      ..close();
    canvas.drawPath(jacket, paint);
    canvas.drawPath(jacket, stroke);

    paint.color = const Color(0xFF6FA8CF);
    final shirt = Path()
      ..moveTo(w * .36, h * .48)
      ..lineTo(w * .45, h * .48)
      ..lineTo(w * .47, h * .76)
      ..lineTo(w * .36, h * .76)
      ..close();
    canvas.drawPath(shirt, paint);
    canvas.drawPath(shirt, stroke);

    paint.color = const Color(0xFFE9B28F);
    canvas.drawCircle(Offset(w * .44, h * .58), w * .018, paint);
    canvas.drawCircle(Offset(w * .44, h * .58), w * .018, stroke);
    canvas.drawLine(Offset(w * .49, h * .52), Offset(w * .55, h * .47), stroke);
    canvas.drawLine(Offset(w * .34, h * .51), Offset(w * .29, h * .64), stroke);
    _drawFace(canvas, Offset(w * .395, h * .415), w * .017, stroke);
  }

  void _drawElder(Canvas canvas, Size size, Paint stroke) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..isAntiAlias = true;

    paint.color = const Color(0xFFE5E7EB);
    canvas.drawOval(Rect.fromLTWH(w * .55, h * .32, w * .13, h * .13), paint);
    canvas.drawOval(Rect.fromLTWH(w * .55, h * .32, w * .13, h * .13), stroke);

    paint.color = const Color(0xFFF1C8AA);
    canvas.drawOval(Rect.fromLTWH(w * .56, h * .36, w * .12, h * .13), paint);
    canvas.drawOval(Rect.fromLTWH(w * .56, h * .36, w * .12, h * .13), stroke);

    paint.color = const Color(0xFF768B82);
    final sweater = Path()
      ..moveTo(w * .51, h * .52)
      ..lineTo(w * .57, h * .47)
      ..lineTo(w * .70, h * .47)
      ..lineTo(w * .78, h * .76)
      ..lineTo(w * .54, h * .76)
      ..close();
    canvas.drawPath(sweater, paint);
    canvas.drawPath(sweater, stroke);

    paint.color = const Color(0xFFF1C8AA);
    canvas.drawCircle(Offset(w * .58, h * .60), w * .021, paint);
    canvas.drawCircle(Offset(w * .66, h * .59), w * .021, paint);
    canvas.drawLine(Offset(w * .57, h * .55), Offset(w * .60, h * .62), stroke);
    canvas.drawLine(Offset(w * .68, h * .55), Offset(w * .64, h * .62), stroke);

    paint.color = const Color(0xFFE5E7EB);
    final phone = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .60, h * .56, w * .08, h * .11),
        const Radius.circular(5));
    canvas.drawRRect(phone, paint);
    canvas.drawRRect(phone, stroke);
    _drawFace(canvas, Offset(w * .615, h * .418), w * .016, stroke);
    canvas.drawCircle(Offset(w * .58, h * .41), w * .012, stroke);
    canvas.drawCircle(Offset(w * .64, h * .41), w * .012, stroke);
    canvas.drawLine(
        Offset(w * .592, h * .41), Offset(w * .628, h * .41), stroke);
  }

  void _drawFace(Canvas canvas, Offset center, double unit, Paint stroke) {
    canvas.drawCircle(center.translate(-unit, -unit * .25), unit * .18, stroke);
    canvas.drawCircle(center.translate(unit, -unit * .25), unit * .18, stroke);
    canvas.drawArc(
        Rect.fromCenter(
            center: center.translate(0, unit * .75),
            width: unit * 1.4,
            height: unit),
        0,
        3.14,
        false,
        stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
