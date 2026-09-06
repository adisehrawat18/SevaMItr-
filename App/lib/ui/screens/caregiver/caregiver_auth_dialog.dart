import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/data/services/caregiver_auth_service.dart';

enum CaregiverAuthTab { login, signup }

class CaregiverAuthDialog extends StatefulWidget {
  final VoidCallback? onAuthSuccess;
  final CaregiverAuthTab initialTab;

  const CaregiverAuthDialog({
    super.key,
    this.onAuthSuccess,
    this.initialTab = CaregiverAuthTab.login,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onAuthSuccess,
    CaregiverAuthTab initialTab = CaregiverAuthTab.login,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(140),
      builder: (_) => CaregiverAuthDialog(
        onAuthSuccess: onAuthSuccess,
        initialTab: initialTab,
      ),
    );
  }

  @override
  State<CaregiverAuthDialog> createState() => _CaregiverAuthDialogState();
}

class _CaregiverAuthDialogState extends State<CaregiverAuthDialog> {
  late CaregiverAuthTab _currentTab;
  final _authService = CaregiverAuthService.instance;

  // Login Form Controllers
  final _loginIdentController = TextEditingController();
  final _loginPassController = TextEditingController();

  // Register Form Controllers
  final _signupNameController = TextEditingController();
  final _signupIdentController = TextEditingController();
  final _signupRegionController = TextEditingController(text: 'Kamrup, Assam');
  final _signupPassController = TextEditingController();

  // Roles matching website dropdown
  static const List<String> _caregiverRoles = [
    'Family Member / Primary Caregiver',
    'ASHA / Anganwadi Community Health Worker',
    'Clinical Doctor / Medical Officer',
  ];
  String _selectedRole = 'Family Member / Primary Caregiver';

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureLoginPass = true;
  bool _obscureSignupPass = true;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  void dispose() {
    _loginIdentController.dispose();
    _loginPassController.dispose();
    _signupNameController.dispose();
    _signupIdentController.dispose();
    _signupRegionController.dispose();
    _signupPassController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final ident = _loginIdentController.text.trim();
    final pass = _loginPassController.text;

    if (ident.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Please enter both phone/username and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _authService.login(
      identifier: ident,
      password: pass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      widget.onAuthSuccess?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: DementiaColors.primaryKazirangaForest,
        ),
      );
    } else {
      setState(() => _errorMessage = res.message);
    }
  }

  Future<void> _handleSignup() async {
    final name = _signupNameController.text.trim();
    final ident = _signupIdentController.text.trim();
    final region = _signupRegionController.text.trim();
    final pass = _signupPassController.text;

    if (name.isEmpty || ident.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Mirror website logic: role is DOCTOR for doctors, CAREGIVER for family/ASHA
    final role = _selectedRole == 'Clinical Doctor / Medical Officer' ? 'DOCTOR' : 'CAREGIVER';
    final formattedRegion = region.isNotEmpty ? '$region ($_selectedRole)' : _selectedRole;

    final res = await _authService.signUp(
      fullName: name,
      identifier: ident,
      password: pass,
      region: formattedRegion,
      role: role,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      widget.onAuthSuccess?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: DementiaColors.primaryKazirangaForest,
        ),
      );
    } else {
      setState(() => _errorMessage = res.message);
    }
  }

  Future<void> _handleDemoLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _authService.useDemoAccount();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      widget.onAuthSuccess?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged in as Demo Caregiver Anuradha Baruah!'),
          backgroundColor: DementiaColors.primaryKazirangaForest,
        ),
      );
    } else {
      setState(() => _errorMessage = res.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            decoration: BoxDecoration(
              color: DementiaColors.pureSurfaceWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: DementiaColors.borderCharcoal, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: DementiaColors.borderCharcoal,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Dismiss Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, color: DementiaColors.borderCharcoal, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),

                // Brand Header: matches sevamitr/src/app/page.tsx
                _buildBrandHeader(),
                const SizedBox(height: 18),

                // Segmented Pill Tab Switcher: matches sevamitr/src/app/page.tsx
                _buildSegmentedPills(),
                const SizedBox(height: 16),

                // Error Banner
                if (_errorMessage != null) ...[
                  _buildErrorBanner(_errorMessage!),
                  const SizedBox(height: 14),
                ],

                // Active Tab Content
                if (_currentTab == CaregiverAuthTab.login)
                  _buildLoginForm()
                else
                  _buildRegisterForm(),

                const SizedBox(height: 16),
                const Divider(color: DementiaColors.borderSubtle, thickness: 1.5),
                const SizedBox(height: 12),

                // Hackathon Quick Demo Button
                _buildDemoButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Brand Header identical to the website
  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: DementiaColors.pureSurfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
            boxShadow: const [
              BoxShadow(
                color: DementiaColors.borderCharcoal,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(6),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "SEVA",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: DementiaColors.borderCharcoal,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "MITR",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: DementiaColors.primaryKazirangaForest,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Cognitive health & circadian memory care platform.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            color: DementiaColors.textMutedSlate,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Segmented Pill Tab Switcher matching web (#f4f7f4, 9999px radius, 2px solid #1c1b1b)
  Widget _buildSegmentedPills() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DementiaColors.paleSageBg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              tab: CaregiverAuthTab.login,
              icon: Icons.login_rounded,
              label: "LOG IN",
            ),
          ),
          Expanded(
            child: _buildTabButton(
              tab: CaregiverAuthTab.signup,
              icon: Icons.person_add_alt_1_rounded,
              label: "REGISTER",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required CaregiverAuthTab tab,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = tab;
          _errorMessage = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? DementiaColors.primaryKazirangaForest : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : DementiaColors.borderCharcoal,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : DementiaColors.borderCharcoal,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error banner matching web (#fee2e2, border 2px solid #991b1b)
  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: DementiaColors.gentleRose,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DementiaColors.gentleRoseDark, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: DementiaColors.gentleRoseDark, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DementiaColors.gentleRoseDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 1: Log In Form
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Micro-caps Label
        _buildMicroLabel("PHONE / USERNAME"),
        const SizedBox(height: 5),
        _buildTextField(
          controller: _loginIdentController,
          hintText: "+919876543210 or dadi",
          keyboardType: TextInputType.text,
          prefixIcon: Icons.phone_android_rounded,
        ),
        const SizedBox(height: 14),

        _buildMicroLabel("PASSWORD"),
        const SizedBox(height: 5),
        _buildTextField(
          controller: _loginPassController,
          hintText: "Enter your password",
          obscureText: _obscureLoginPass,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureLoginPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 19,
              color: DementiaColors.textMutedSlate,
            ),
            onPressed: () => setState(() => _obscureLoginPass = !_obscureLoginPass),
          ),
        ),
        const SizedBox(height: 18),

        // Action Button: Sign In
        _buildPrimaryButton(
          label: _isLoading ? "SIGNING IN..." : "SIGN IN",
          onPressed: _isLoading ? null : _handleLogin,
          icon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }

  /// Tab 2: Register Form
  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full Name
        _buildMicroLabel("FULL NAME"),
        const SizedBox(height: 5),
        _buildTextField(
          controller: _signupNameController,
          hintText: "e.g. Dadi Ji (Prabha Sharma)",
          keyboardType: TextInputType.name,
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),

        // Caregiver Registration Banner (#e8f5e9, border 1.5px solid #214935)
        _buildCaregiverBanner(),
        const SizedBox(height: 12),

        // Caregiver Designation Dropdown
        _buildMicroLabel("CAREGIVER DESIGNATION"),
        const SizedBox(height: 5),
        _buildDesignationDropdown(),
        const SizedBox(height: 12),

        // 2-Column Grid for Phone / ID and Region
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMicroLabel("PHONE / ID"),
                  const SizedBox(height: 5),
                  _buildTextField(
                    controller: _signupIdentController,
                    hintText: "+919...",
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_android_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMicroLabel("REGION"),
                  const SizedBox(height: 5),
                  _buildTextField(
                    controller: _signupRegionController,
                    hintText: "e.g. Kamrup",
                    keyboardType: TextInputType.text,
                    prefixIcon: Icons.location_on_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Password
        _buildMicroLabel("PASSWORD"),
        const SizedBox(height: 5),
        _buildTextField(
          controller: _signupPassController,
          hintText: "Create a password",
          obscureText: _obscureSignupPass,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSignupPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 19,
              color: DementiaColors.textMutedSlate,
            ),
            onPressed: () => setState(() => _obscureSignupPass = !_obscureSignupPass),
          ),
        ),
        const SizedBox(height: 18),

        // Action Button: Create Account
        _buildPrimaryButton(
          label: _isLoading ? "CREATING..." : "CREATE ACCOUNT",
          onPressed: _isLoading ? null : _handleSignup,
          icon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }

  /// Informational banner with stethoscope icon mirroring web
  Widget _buildCaregiverBanner() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: DementiaColors.primaryMintSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DementiaColors.primaryKazirangaForest, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.medical_services_outlined,
            color: DementiaColors.primaryKazirangaForest,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              const TextSpan(
                style: TextStyle(
                  fontSize: 11.5,
                  color: DementiaColors.borderCharcoal,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: "Caregiver Registration: ",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text:
                        "Patients cannot self-register directly. Once signed up, you can register and oversee elderly patients securely from your Caregiver Dashboard.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dropdown for Caregiver Designation
  Widget _buildDesignationDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: DementiaColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: DementiaColors.borderCharcoal),
          dropdownColor: DementiaColors.pureSurfaceWhite,
          style: const TextStyle(
            fontSize: 13,
            color: DementiaColors.borderCharcoal,
            fontWeight: FontWeight.w600,
          ),
          items: _caregiverRoles.map((role) {
            return DropdownMenuItem<String>(
              value: role,
              child: Text(
                role,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedRole = val);
            }
          },
        ),
      ),
    );
  }

  /// Standard Neo-Brutalist Micro-caps Label
  Widget _buildMicroLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: DementiaColors.borderCharcoal,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Neo-Brutalist Input Field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DementiaColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 13.5,
          color: DementiaColors.borderCharcoal,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 18, color: DementiaColors.borderCharcoal)
              : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
      ),
    );
  }

  /// Neo-Brutalist Primary Action Button (#214935, 3px 3px 0px #1c1b1b shadow)
  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: DementiaColors.borderCharcoal,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DementiaColors.primaryKazirangaForest,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DementiaColors.primaryKazirangaForest.withAlpha(160),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          side: const BorderSide(color: DementiaColors.borderCharcoal, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 17),
                ],
              ),
      ),
    );
  }

  /// Hackathon Demo Account Quick Login
  Widget _buildDemoButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleDemoLogin,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: DementiaColors.pureSurfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DementiaColors.borderCharcoal, width: 2),
          boxShadow: const [
            BoxShadow(
              color: DementiaColors.borderCharcoal,
              offset: Offset(2.5, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: DementiaColors.amberMugaLight,
                shape: BoxShape.circle,
                border: Border.all(color: DementiaColors.borderCharcoal, width: 1.5),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: DementiaColors.terracottaDark,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Use Hackathon Demo Account",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: DementiaColors.borderCharcoal,
                    ),
                  ),
                  Text(
                    "Anuradha Baruah (Paired with patient Bhaben Baruah)",
                    style: TextStyle(
                      fontSize: 11,
                      color: DementiaColors.textMutedSlate,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: DementiaColors.borderCharcoal),
          ],
        ),
      ),
    );
  }
}
