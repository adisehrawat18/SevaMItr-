import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/data/models/patient_profile_model.dart';
import 'package:dementia_ner_care/ui/components/neo_widgets.dart';

/// SevaMitr Neo-Brutalist Patient Setup & Registration Screen
/// High-contrast, tactile, dementia-safe registration and onboarding form.
class PatientSetupScreen extends StatefulWidget {
  final PatientProfile? profile;
  final ValueChanged<PatientProfile> onSaved;

  const PatientSetupScreen({
    super.key,
    this.profile,
    required this.onSaved,
  });

  @override
  State<PatientSetupScreen> createState() => _PatientSetupScreenState();
}

class _PatientSetupScreenState extends State<PatientSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullName;
  late final TextEditingController _preferredName;
  late final TextEditingController _age;
  late final TextEditingController _region;
  late final TextEditingController _emergencyContact;
  late final TextEditingController _caregiverName;
  late final TextEditingController _careNotes;
  late final TextEditingController _kioskIdentifier;
  late final TextEditingController _kioskPin;

  String _gender = 'Female';
  String _primaryLanguage = 'en';
  String _dementiaStage = 'Mild';
  bool _enableKiosk = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _fullName = TextEditingController(text: p?.fullName ?? '');
    _preferredName = TextEditingController(text: p?.preferredName ?? '');
    _age = TextEditingController(text: p?.age != null ? p!.age.toString() : '72');
    _region = TextEditingController(text: p?.region ?? 'Kamrup Rural, Assam');
    _emergencyContact = TextEditingController(
      text: p?.emergencyContact.isNotEmpty == true
          ? p!.emergencyContact
          : (p?.caregiverPhone ?? '+91 94350 12345'),
    );
    _caregiverName = TextEditingController(
      text: p?.caregiverName ?? 'Primary Caregiver',
    );
    _careNotes = TextEditingController(text: p?.careNotes ?? '');
    _kioskIdentifier = TextEditingController(text: p?.kioskIdentifier ?? '');
    _kioskPin = TextEditingController(text: p?.kioskPin ?? '');

    if (p != null) {
      _gender = p.gender;
      _primaryLanguage = p.primaryLanguage;
      _dementiaStage = p.dementiaStage;
      _enableKiosk = p.enableKiosk;
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _preferredName.dispose();
    _age.dispose();
    _region.dispose();
    _emergencyContact.dispose();
    _caregiverName.dispose();
    _careNotes.dispose();
    _kioskIdentifier.dispose();
    _kioskPin.dispose();
    super.dispose();
  }

  void _handlePrefillSample() {
    setState(() {
      _fullName.text = 'Bhaben Baruah';
      _preferredName.text = 'Bhaben';
      _age.text = '74';
      _gender = 'Male';
      _region.text = 'Tezpur, Sonitpur, Assam';
      _primaryLanguage = 'as';
      _dementiaStage = 'Mild';
      _emergencyContact.text = '+91 94350 98765';
      _caregiverName.text = 'Barun Baruah (Son)';
      _careNotes.text = 'Enjoys classical Bihu melodies and morning walks in the courtyard.';
      _enableKiosk = true;
      _kioskIdentifier.text = 'bhaben';
      _kioskPin.text = '1234';
      _errorMessage = null;
    });
  }

  void _submitForm() async {
    setState(() => _errorMessage = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _errorMessage = 'Please complete all required fields marked with *');
      return;
    }

    final parsedAge = int.tryParse(_age.text.trim());
    if (parsedAge == null || parsedAge < 35 || parsedAge > 120) {
      setState(() => _errorMessage = 'Please enter a realistic age between 35 and 120.');
      return;
    }

    setState(() => _isSubmitting = true);

    final prefName = _preferredName.text.trim().isNotEmpty
        ? _preferredName.text.trim()
        : _fullName.text.trim().split(' ').first;

    final updatedProfile = PatientProfile(
      id: widget.profile?.id ?? 1,
      fullName: _fullName.text.trim(),
      preferredName: prefName,
      age: parsedAge,
      gender: _gender,
      region: _region.text.trim().isNotEmpty
          ? _region.text.trim()
          : 'Assam, North Eastern Region',
      primaryLanguage: _primaryLanguage,
      dementiaStage: _dementiaStage,
      emergencyContact: _emergencyContact.text.trim(),
      caregiverName: _caregiverName.text.trim().isNotEmpty
          ? _caregiverName.text.trim()
          : 'Primary Caregiver',
      caregiverPhone: _emergencyContact.text.trim(),
      careNotes: _careNotes.text.trim(),
      enableKiosk: _enableKiosk,
      kioskIdentifier: _enableKiosk ? _kioskIdentifier.text.trim() : '',
      kioskPin: _enableKiosk ? _kioskPin.text.trim() : '',
      serverPatientId: widget.profile?.serverPatientId ?? '',
      serverSyncedAt: widget.profile?.serverSyncedAt ?? 0,
      createdAt: widget.profile?.createdAt ?? DateTime.now(),
    );

    // Short simulated haptic delay for crisp tactile feedback
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    widget.onSaved(updatedProfile);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.profile != null;

    return Scaffold(
      backgroundColor: DementiaColors.paleSageBg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // Top Bar for editing mode
              if (isEditing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: DementiaColors.borderCharcoal,
                              width: DementiaDimensions.borderWidthThick,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: DementiaColors.borderCharcoal,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, size: 18, color: DementiaColors.borderCharcoal),
                              SizedBox(width: 4),
                              Text(
                                'BACK',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: DementiaColors.borderCharcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Spaced-out Header Icon & Badge Pair (Section 5.D of DESIGN_SYSTEM.md)
              NeoHeaderBadgePair(
                icon: isEditing ? Icons.manage_accounts : Icons.person_add_alt_1,
                badgeText: isEditing ? 'UPDATE PATIENT CARE' : 'PATIENT REGISTRATION REQUIRED',
                iconBg: DementiaColors.primaryMintSoft,
                iconColor: DementiaColors.primaryKazirangaForest,
                badgeBg: DementiaColors.primaryKazirangaForest,
                badgeColor: Colors.white,
              ),
              const SizedBox(height: 18),

              // Page Title & Subtitle Card
              NeoCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                child: Column(
                  children: [
                    Text(
                      isEditing ? 'UPDATE PATIENT PROFILE' : 'ADD A PATIENT TO START GAMES',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: DementiaColors.borderCharcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEditing
                          ? 'Modify cognitive settings, caregiver supervision contacts, and regional localization preferences.'
                          : 'Register the elder or loved one under your care to calibrate difficulty thresholds, clinical telemetry, and voice prompts.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: DementiaColors.textMutedSlate,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Main Master Form Card
              NeoCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Sub-Header Bar with Prefill sample button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PATIENT DETAILS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: DementiaColors.borderCharcoal,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Stored securely & available 100% offline',
                              style: TextStyle(
                                fontSize: 12,
                                color: DementiaColors.textDimStone,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _handlePrefillSample,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: DementiaColors.amberMugaLight,
                              borderRadius: BorderRadius.circular(DementiaDimensions.pillCornerRadius),
                              border: Border.all(
                                color: DementiaColors.borderCharcoal,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: DementiaColors.borderCharcoal,
                                  offset: Offset(1.5, 1.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: 14, color: Color(0xFF92400E)),
                                SizedBox(width: 4),
                                Text(
                                  'SAMPLE (ASSAM)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF92400E),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: DementiaColors.borderSubtle, thickness: 1.5),
                    const SizedBox(height: 18),

                    // Error Notification Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: DementiaColors.gentleRose,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: DementiaColors.gentleRoseDark,
                            width: DementiaDimensions.borderWidthThick,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: DementiaColors.gentleRoseDark, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: DementiaColors.gentleRoseDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // SECTION 1: Patient Demographics
                    _buildSectionHeader('1. PATIENT DEMOGRAPHICS'),
                    const SizedBox(height: 12),

                    _buildField(
                      controller: _fullName,
                      label: 'Full Name *',
                      hint: 'e.g. Bhaben Baruah or Nilima Devi',
                      icon: Icons.badge_outlined,
                      isRequired: true,
                    ),

                    _buildField(
                      controller: _preferredName,
                      label: 'Preferred Name in App',
                      hint: 'e.g. Bhaben or Aita (Grandmother)',
                      icon: Icons.favorite_border,
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Age Field
                        Expanded(
                          flex: 1,
                          child: _buildField(
                            controller: _age,
                            label: 'Age (Years) *',
                            hint: '72',
                            icon: Icons.cake_outlined,
                            keyboard: TextInputType.number,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Gender 3-Way Switcher (Section 5.E of DESIGN_SYSTEM.md)
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GENDER',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: DementiaColors.borderCharcoal,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              NeoSegmentedToggle<String>(
                                items: const ['Female', 'Male', 'Other'],
                                selectedItem: _gender,
                                onSelected: (val) => setState(() => _gender = val),
                                labelBuilder: (val) => val,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildField(
                      controller: _region,
                      label: 'Region / District (NER)',
                      hint: 'e.g. Tezpur, Sonitpur, Assam',
                      icon: Icons.location_on_outlined,
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: DementiaColors.borderSubtle, thickness: 1.5),
                    const SizedBox(height: 18),

                    // SECTION 2: Clinical & Language Profile
                    _buildSectionHeader('2. CLINICAL & LANGUAGE PROFILE'),
                    const SizedBox(height: 14),

                    // Primary Language 2x2 Grid
                    const Text(
                      'PRIMARY LANGUAGE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: DementiaColors.borderCharcoal,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLanguageGrid(),
                    const SizedBox(height: 18),

                    // Dementia Stage Assessment 3-Way Selector
                    const Text(
                      'DEMENTIA STAGE / COGNITIVE ASSESSMENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: DementiaColors.borderCharcoal,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    NeoSegmentedToggle<String>(
                      items: const ['MCI', 'Mild', 'Moderate'],
                      selectedItem: _dementiaStage,
                      onSelected: (val) => setState(() => _dementiaStage = val),
                      labelBuilder: (val) => val,
                      subLabelBuilder: (val) {
                        switch (val) {
                          case 'MCI':
                            return 'Early Signs';
                          case 'Mild':
                            return 'Recommended';
                          case 'Moderate':
                            return 'Assisted';
                          default:
                            return '';
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    _buildField(
                      controller: _emergencyContact,
                      label: 'Emergency / Caregiver Phone *',
                      hint: '+91 94350 12345',
                      icon: Icons.phone_outlined,
                      keyboard: TextInputType.phone,
                      isRequired: true,
                    ),

                    _buildField(
                      controller: _caregiverName,
                      label: 'Supervising Family Member / Caregiver',
                      hint: 'e.g. Barun Baruah (Son)',
                      icon: Icons.people_outline,
                    ),

                    _buildField(
                      controller: _careNotes,
                      label: 'Helpful Care Notes (Optional)',
                      hint: 'Routine triggers, favorite memories, sundowning tendencies...',
                      icon: Icons.notes_outlined,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: DementiaColors.borderSubtle, thickness: 1.5),
                    const SizedBox(height: 16),

                    // SECTION 3: Tablet / Kiosk Login Mode
                    _buildKioskSection(),

                    const SizedBox(height: 16),

                    // Supervising Caregiver Callout Box
                    NeoSupervisorCallout(caregiverName: _caregiverName.text.trim()),

                    const SizedBox(height: 24),

                    // Tactile Primary Action Button (Section 5.C of DESIGN_SYSTEM.md)
                    NeoButton(
                      text: isEditing ? 'SAVE CHANGES' : 'SAVE PATIENT & START GAMES',
                      icon: isEditing ? Icons.check_circle_outline : Icons.arrow_forward,
                      isLoading: _isSubmitting,
                      onPressed: _submitForm,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: DementiaColors.primaryKazirangaForest,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: DementiaColors.borderCharcoal,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboard,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: DementiaColors.borderCharcoal,
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: DementiaColors.borderCharcoal, size: 20),
            ),
            validator: (val) {
              if (isRequired && (val == null || val.trim().isEmpty)) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageGrid() {
    final languages = [
      {'code': 'en', 'label': 'English', 'native': 'English'},
      {'code': 'as', 'label': 'Assamese', 'native': 'অসমীয়া'},
      {'code': 'bn', 'label': 'Bengali', 'native': 'বাংলা'},
      {'code': 'hi', 'label': 'Hindi', 'native': 'हिन्दी'},
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.7,
      children: languages.map((lang) {
        final isSelected = _primaryLanguage == lang['code'];
        return GestureDetector(
          onTap: () => setState(() => _primaryLanguage = lang['code']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? DementiaColors.primaryKazirangaForest
                  : DementiaColors.pureSurfaceWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DementiaColors.borderCharcoal,
                width: DementiaDimensions.borderWidthThick,
              ),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: DementiaColors.borderCharcoal,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: 18,
                  color: isSelected ? Colors.white : DementiaColors.borderCharcoal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang['native']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : DementiaColors.borderCharcoal,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        lang['label']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : DementiaColors.textDimStone,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKioskSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _enableKiosk = !_enableKiosk),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _enableKiosk,
                          activeColor: DementiaColors.primaryKazirangaForest,
                          onChanged: (v) => setState(() => _enableKiosk = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'ENABLE TABLET / KIOSK LOGIN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: DementiaColors.borderCharcoal,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.key, color: DementiaColors.textDimStone, size: 20),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 32, top: 4),
            child: Text(
              'Allows the elder to log in on household or clinic tablets without caregiver account.',
              style: TextStyle(
                fontSize: 11,
                color: DementiaColors.textDimStone,
                height: 1.3,
              ),
            ),
          ),
          if (_enableKiosk) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _kioskIdentifier,
                    label: 'Patient ID',
                    hint: 'e.g. bhaben',
                    icon: Icons.person_pin,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _kioskPin,
                    label: 'Simple PIN',
                    hint: 'e.g. 1234',
                    icon: Icons.lock_outline,
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
