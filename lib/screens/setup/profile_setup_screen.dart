import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/profile_photo_picker.dart';
import '../../widgets/sketchy_progress_bar.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_service.dart';
import '../../config/dev_config.dart';
import 'profile_created_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  bool _isLoadingConfig = true;
  List<dynamic> _segments = [];
  List<dynamic> _sections = [];
  final Set<String> _expandedSegments = {};
  
  @override
  void initState() {
    super.initState();

    _loadOnboardingConfig();
    
    // Add listeners to rebuild UI when text changes for validation
    void updateState() => setState(() {});
    _usernameController.addListener(updateState);
    _nameController.addListener(updateState);
    _ageController.addListener(updateState);
    _bioController.addListener(updateState);
    _schoolController.addListener(updateState);
    _courseController.addListener(updateState);
    _heightController.addListener(updateState);
    _religionController.addListener(updateState);

    // Default college to Adamas University
    _schoolController.text = 'Adamas University';
    
    // Default height to 5 ft 8 in (~173 cm) and age from DOB
    _updateAgeFromDob();
    _updateHeightCm();
  }

  Future<void> _loadOnboardingConfig() async {
    final config = await OnboardingService.fetchConfig();
    if (config != null && mounted) {
      setState(() {
        _segments = config['segments'] ?? [];
        _sections = config['sections'] ?? [];
        _isLoadingConfig = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoadingConfig = false;
      });
    }
  }

  String _selectedCollegeOption = 'Adamas University';
  String? _selectedCourseOption;
  String? _selectedReligionOption;
  int _selectedFeet = 5;
  int _selectedInches = 8;
  int? _selectedMonth = 1;
  int? _selectedDay = 15;
  int? _selectedYear = DateTime.now().year - 18;

  final List<String> kMonths = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  void _updateAgeFromDob() {
    if (_selectedYear == null || _selectedMonth == null || _selectedDay == null) return;
    final today = DateTime.now();
    int age = today.year - _selectedYear!;
    if (today.month < _selectedMonth! ||
        (today.month == _selectedMonth! && today.day < _selectedDay!)) {
      age--;
    }
    if (age < 0) age = 0;
    _ageController.text = age.toString();
  }

  void _updateHeightCm() {
    final totalInches = (_selectedFeet * 12) + _selectedInches;
    final cm = (totalInches * 2.54).round();
    _heightController.text = cm.toString();
  }

  int _getWordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _religionController = TextEditingController();

  final List<String> kAvailableReligions = const [
    'Hindu',
    'Muslim',
    'Christian',
    'Sikh',
    'Buddhist',
    'Jain',
    'Parsi (Zoroastrian)',
    'Jewish',
    'Baháʼí',
    'Tribal / Indigenous Religion',
    'Atheist',
    'Agnostic',
    'No Religion',
    'Spiritual but Not Religious',
    'Prefer Not to Say',
    'Other',
  ];

  final List<String> kAvailableCourses = const [
    'BA (Hons)',
    'BA LL.B (Hons)',
    'BBA',
    'BBA LL.B (Hons)',
    'BCA',
    'B.Com (Hons)',
    'B.Ed',
    'B.Pharm',
    'B.Sc (Hons) / B.Sc',
    'B.Tech',
    'Bachelor of Optometry',
    'D.Pharm',
    'Diploma',
    'LL.M',
    'MA',
    'MBA',
    'MCA',
    'M.Com',
    'M.Pharm',
    'M.Sc',
    'M.Tech',
    'P.G.D',
    'Ph.D.',
    'Other',
  ];

  final List<String> _availableHobbies = [
    'Gaming', 'Anime', 'Coding', 'Hiking', 'Music', 'Art', 'Coffee', 'Movies',
    'Reading', 'Photography', 'Sports', 'Travel'
  ];
  final Set<String> _selectedHobbies = {};

  final List<String> _availableSkills = ['JavaScript', 'Python', 'Dart', 'Figma', 'UI/UX', 'Writing', 'Music', 'Public Speaking'];
  final Set<String> _selectedSkills = {};

  final Set<String> _selectedInterests = {};
  
  // Mapping of promptId to answer string
  final Map<String, String> _promptAnswers = {};
  final Set<String> _activePromptIds = {};
  final Map<String, FocusNode> _promptFocusNodes = {};

  final List<String?> _photoPaths = List.filled(4, null);
  final List<Uint8List?> _photoBytes = List.filled(4, null);

  bool _smoke = false;
  bool _drink = false;
  bool _pets = false;

  String? _selectedGender;
  String? _selectedLookingFor;
  String? _selectedSexualOrientation;
  bool _isSaving = false;

  bool get _isStep1Valid {
    if (DevConfig.bypassProfileValidation) return true;
    return _usernameController.text.trim().isNotEmpty &&
           _nameController.text.trim().isNotEmpty &&
           _ageController.text.trim().isNotEmpty &&
           _selectedGender != null &&
           _bioController.text.trim().isNotEmpty;
  }

  bool get _isStep2Valid {
    if (DevConfig.bypassProfileValidation) return true;
    return _schoolController.text.trim().isNotEmpty &&
           _courseController.text.trim().isNotEmpty &&
           _heightController.text.trim().isNotEmpty &&
           _religionController.text.trim().isNotEmpty;
  }

  bool get _isStep3Valid {
    if (DevConfig.bypassProfileValidation) return true;
    return _photoPaths.any((p) => p != null) || _photoBytes.any((b) => b != null);
  }

  bool get _isStep4Valid {
    return true; // Step 4 (Interests) can be skipped or submitted
  }

  bool get _isStep5Valid {
    if (DevConfig.bypassProfileValidation) return true;
    final validAnswersCount = _promptAnswers.values.where((ans) => ans.trim().isNotEmpty).length;
    return validAnswersCount == 3;
  }

  bool get _isStep6Valid {
    if (DevConfig.bypassProfileValidation) return true;
    return _selectedLookingFor != null && 
           _selectedSexualOrientation != null;
  }

  /// Fine-grained completion from 0.0 to 1.0, updated live as the user fills
  /// in individual fields. Each field below is worth a share of 100 points.
  double get _completionProgress {
    int score = 0;

    // ── Step 1: Basic Info (30 pts total) ─────────────────────────────────────
    if (_usernameController.text.trim().isNotEmpty) score += 5;
    if (_nameController.text.trim().isNotEmpty) score += 5;
    if (_ageController.text.trim().isNotEmpty) score += 5;
    if (_selectedGender != null) score += 5;
    final bioWords = _getWordCount(_bioController.text);
    if (bioWords >= 5) score += 10;
    else if (bioWords > 0) score += 5;

    // ── Step 2: About You (20 pts total) ──────────────────────────────────────
    if (_schoolController.text.trim().isNotEmpty) score += 5;
    if (_courseController.text.trim().isNotEmpty) score += 5;
    if (_heightController.text.trim().isNotEmpty) score += 5;
    if (_religionController.text.trim().isNotEmpty) score += 5;

    // ── Step 3: Photos (15 pts total) ─────────────────────────────────────────
    final photoCount = _photoBytes.where((b) => b != null).length;
    score += (photoCount * 4).clamp(0, 15); // 4 pts per photo, cap at 15

    // ── Step 4: Interests (10 pts total) ──────────────────────────────────────
    final interestCount = _selectedInterests.length + _selectedHobbies.length + _selectedSkills.length;
    if (interestCount >= 5) score += 10;
    else score += (interestCount * 2).clamp(0, 10);

    // ── Step 5: Prompts (15 pts total) ────────────────────────────────────────
    final answeredPrompts = _promptAnswers.values.where((a) => a.trim().isNotEmpty).length;
    score += (answeredPrompts * 5).clamp(0, 15);

    // ── Step 6: Preferences (10 pts total) ────────────────────────────────────
    if (_selectedLookingFor != null) score += 5;
    if (_selectedSexualOrientation != null) score += 5;

    return (score / 100.0).clamp(0.0, 1.0);
  }

  int get _completionPercent => (_completionProgress * 100).round();

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _schoolController.dispose();
    _courseController.dispose();
    _heightController.dispose();
    _religionController.dispose();
    for (var node in _promptFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentIndex < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    }
  }

  void _previousStep() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = _completionProgress;
    String leftLabel = '$_completionPercent%';
    String stepLabel = 'STEP ${_currentIndex + 1}/7';
    
    final titles = [
      'BASIC INFO',
      'ABOUT YOU',
      'PROFILE PHOTOS',
      'INTERESTS',
      'PROMPTS',
      'PREFERENCES',
      'PROFILE CARD'
    ];
    
    final rightLabels = [
      'PERSONAL',
      'DETAILS',
      'VISUALS',
      'INTERESTS',
      'QUESTIONS',
      'GOALS',
      'READY!'
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex > 0) {
          if (!_pageController.position.isScrollingNotifier.value) {
            _previousStep();
          }
        } else {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isLoadingConfig ? const Text('LOADING...') : Text(titles[_currentIndex]),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_currentIndex > 0) {
                _previousStep();
              } else {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
          actions: [
            if (_currentIndex == 2 || _currentIndex == 3)
              TextButton(
                onPressed: _nextStep,
                child: Text(
                  (_currentIndex == 3 && (_selectedInterests.isNotEmpty || _selectedHobbies.isNotEmpty || _selectedSkills.isNotEmpty)) ||
                  (_currentIndex == 2 && _photoPaths.any((p) => p != null))
                      ? 'NEXT'
                      : 'SKIP',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor2,
                    fontSize: 14,
                  ),
                ),
              ),
            if (_currentIndex == 4)
              Builder(
                builder: (context) {
                  final answeredCount = _promptAnswers.values.where((v) => v.trim().isNotEmpty).length;
                  if (answeredCount >= 3) {
                    return TextButton(
                      onPressed: _nextStep,
                      child: Text('NEXT', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textColor2, fontSize: 14)),
                    );
                  } else {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Text('$answeredCount/3', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textColor2, fontSize: 14)),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
        body: SafeArea(
          child: _isLoadingConfig 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
                child: SketchyProgressBar(
                  progress: progress,
                  leftLabel: leftLabel,
                  rightLabel: stepLabel,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: [
                    _buildBasicInfoStep(),
                    _buildAboutYouStep(),
                    _buildUploadPhotosStep(),
                    _buildInterestsStep(),
                    _buildPromptsStep(),
                    _buildPreferencesStep(),
                    _buildProfilePreviewStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeading(context, 'USERNAME'),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _usernameController,
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'newusername', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeading(context, 'NAME'),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Enter you name', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'DATE OF BIRTH',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor2,
                    ),
              ),
              const SizedBox(width: 8),
              if (_ageController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textColor2.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_ageController.text} yrs old',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Month Dropdown
              Expanded(
                flex: 3,
                child: SketchyContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      isExpanded: true,
                      dropdownColor: AppColors.cream,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textColor2),
                      hint: Text('Month', style: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
                      items: List.generate(12, (index) => index + 1).map((int m) {
                        return DropdownMenuItem<int>(
                          value: m,
                          child: Text(
                            kMonths[m - 1],
                            style: GoogleFonts.inter(
                              color: AppColors.textColor2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newMonth) {
                        if (newMonth == null) return;
                        setState(() {
                          _selectedMonth = newMonth;
                          final maxDays = DateTime(_selectedYear ?? DateTime.now().year - 18, newMonth + 1, 0).day;
                          if ((_selectedDay ?? 1) > maxDays) {
                            _selectedDay = maxDays;
                          }
                          _updateAgeFromDob();
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Day Dropdown
              Expanded(
                flex: 2,
                child: SketchyContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedDay,
                      isExpanded: true,
                      dropdownColor: AppColors.cream,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textColor2),
                      hint: Text('Day', style: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
                      items: List.generate(
                        DateTime(_selectedYear ?? DateTime.now().year - 18, (_selectedMonth ?? 1) + 1, 0).day,
                        (index) => index + 1,
                      ).map((int day) {
                        return DropdownMenuItem<int>(
                          value: day,
                          child: Text(
                            '$day',
                            style: GoogleFonts.inter(
                              color: AppColors.textColor2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newDay) {
                        if (newDay == null) return;
                        setState(() {
                          _selectedDay = newDay;
                          _updateAgeFromDob();
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Year Dropdown
              Expanded(
                flex: 3,
                child: SketchyContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isExpanded: true,
                      dropdownColor: AppColors.cream,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textColor2),
                      hint: Text('Year', style: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
                      items: List.generate(
                        60,
                        (index) => (DateTime.now().year - 18) - index,
                      ).map((int yr) {
                        return DropdownMenuItem<int>(
                          value: yr,
                          child: Text(
                            '$yr',
                            style: GoogleFonts.inter(
                              color: AppColors.textColor2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newYear) {
                        if (newYear == null) return;
                        setState(() {
                          _selectedYear = newYear;
                          final maxDays = DateTime(newYear, (_selectedMonth ?? 1) + 1, 0).day;
                          if ((_selectedDay ?? 1) > maxDays) {
                            _selectedDay = maxDays;
                          }
                          _updateAgeFromDob();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeading(context, 'GENDER'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ['male', 'female', 'non-binary'].map((e) {
              final isSelected = _selectedGender == e;
              return GestureDetector(
                onTap: () => setState(() => _selectedGender = e),
                child: SketchyContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  borderRadius: 999,
                  backgroundColor: isSelected ? AppColors.textColor2 : AppColors.cream,
                  child: Text(e.toUpperCase(), style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? AppColors.cream : AppColors.textColor2,
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSectionHeading(context, 'BIO'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textColor2.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_getWordCount(_bioController.text)}/150 words',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getWordCount(_bioController.text) >= 150
                        ? Colors.red
                        : AppColors.textColor2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _bioController,
              maxLines: 3,
              onChanged: (text) {
                final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
                if (words.length > 150) {
                  final truncated = words.take(150).join(' ');
                  _bioController.text = truncated;
                  _bioController.selection = TextSelection.fromPosition(
                    TextPosition(offset: truncated.length),
                  );
                }
                setState(() {});
              },
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Some lines about you',
                hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SketchyButton(
            text: 'NEXT STEP',
            onPressed: _isStep1Valid ? _nextStep : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAboutYouStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeading(context, 'COLLEGE'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ['Adamas University', 'Other'].map((option) {
              final isSelected = _selectedCollegeOption == option;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCollegeOption = option;
                    if (option == 'Adamas University') {
                      _schoolController.text = 'Adamas University';
                    } else {
                      _schoolController.clear();
                    }
                  });
                },
                child: SketchyContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  borderRadius: 999,
                  backgroundColor: isSelected ? AppColors.textColor2 : AppColors.cream,
                  child: Text(
                    option.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isSelected ? AppColors.cream : AppColors.textColor2,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedCollegeOption == 'Other') ...[
            const SizedBox(height: 12),
            SketchyContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: _schoolController,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Enter your college name',
                  hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildSectionHeading(context, 'COURSE'),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: kAvailableCourses.contains(_selectedCourseOption)
                    ? _selectedCourseOption
                    : (_selectedCourseOption == null ? null : 'Other'),
                hint: Text(
                  'Select your course',
                  style: TextStyle(color: AppColors.textColor1.withOpacity(0.5)),
                ),
                isExpanded: true,
                dropdownColor: AppColors.cream,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textColor2),
                items: kAvailableCourses.map((String course) {
                  return DropdownMenuItem<String>(
                    value: course,
                    child: Text(
                      course,
                      style: GoogleFonts.inter(
                        color: AppColors.textColor2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue == null) return;
                  setState(() {
                    _selectedCourseOption = newValue;
                    if (newValue != 'Other') {
                      _courseController.text = newValue;
                    } else {
                      _courseController.clear();
                    }
                  });
                },
              ),
            ),
          ),
          if (_selectedCourseOption == 'Other') ...[
            const SizedBox(height: 12),
            SketchyContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: _courseController,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Enter your course name',
                  hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'HEIGHT',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor2,
                    ),
              ),
              const SizedBox(width: 8),
              if (_heightController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textColor2.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '~${_heightController.text} cm',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Feet Dropdown
              Expanded(
                child: SketchyContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedFeet,
                      isExpanded: true,
                      dropdownColor: AppColors.cream,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textColor2),
                      items: [4, 5, 6, 7].map((int ft) {
                        return DropdownMenuItem<int>(
                          value: ft,
                          child: Text(
                            '$ft ft',
                            style: GoogleFonts.inter(
                              color: AppColors.textColor2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newFt) {
                        if (newFt == null) return;
                        setState(() {
                          _selectedFeet = newFt;
                          _updateHeightCm();
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Inches Dropdown
              Expanded(
                child: SketchyContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedInches,
                      isExpanded: true,
                      dropdownColor: AppColors.cream,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textColor2),
                      items: List.generate(12, (index) => index).map((int inch) {
                        return DropdownMenuItem<int>(
                          value: inch,
                          child: Text(
                            '$inch in',
                            style: GoogleFonts.inter(
                              color: AppColors.textColor2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newInch) {
                        if (newInch == null) return;
                        setState(() {
                          _selectedInches = newInch;
                          _updateHeightCm();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeading(context, 'RELIGION'),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: kAvailableReligions.contains(_selectedReligionOption)
                    ? _selectedReligionOption
                    : null,
                hint: Text(
                  'Select your religion / belief',
                  style: TextStyle(color: AppColors.textColor1.withOpacity(0.5)),
                ),
                isExpanded: true,
                dropdownColor: AppColors.cream,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textColor2),
                items: kAvailableReligions.map((String religion) {
                  return DropdownMenuItem<String>(
                    value: religion,
                    child: Text(
                      religion,
                      style: GoogleFonts.inter(
                        color: AppColors.textColor2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue == null) return;
                  setState(() {
                    _selectedReligionOption = newValue;
                    _religionController.text = newValue;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          SketchyButton(
            text: 'NEXT STEP',
            onPressed: _isStep2Valid ? _nextStep : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUploadPhotosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeading(context, 'PROFILE PHOTOS'),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              final angles = [-0.02, 0.04, 0.03, -0.05];
              return Transform.rotate(
                angle: angles[index],
                child: ProfilePhotoPicker(
                  initialImagePath: _photoPaths[index],
                  initialProcessedBytes: _photoBytes[index],
                  onPhotosSet: (paths, bytesList) {
                    setState(() {
                      int imgIdx = 0;
                      for (int j = 0; j < 4 && imgIdx < paths.length; j++) {
                        int slot = (index + j) % 4;
                        _photoPaths[slot] = paths[imgIdx];
                        _photoBytes[slot] = bytesList[imgIdx];
                        imgIdx++;
                      }
                    });
                  },
                  allowBackgroundRemoval: true,
                  showChooseAnotherButton: false,
                  isBorderless: false,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          SketchyButton(
            text: 'NEXT STEP',
            onPressed: _isStep3Valid ? _nextStep : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          const SizedBox(height: 16),
          if (_segments.isNotEmpty)
            ..._segments.map((segment) {
              final segmentName = segment['name'] ?? 'INTERESTS';
              final interestsList = segment['interests'] as List<dynamic>? ?? [];
              
              final segmentId = segment['id'] as String? ?? segmentName.toString();
              final isExpanded = _expandedSegments.contains(segmentId);
              final int initialVisibleCount = 6;
              
              final visibleInterests = isExpanded 
                  ? interestsList 
                  : interestsList.take(initialVisibleCount).toList();
              final hiddenCount = interestsList.length - visibleInterests.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeading(context, segmentName.toString().toUpperCase()),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ...visibleInterests.map((interest) {
                        final interestId = interest['id'] as String;
                        final label = interest['label'] as String;
                        final emoji = interest['emoji'] as String? ?? '';
                        final isSelected = _selectedInterests.contains(interestId);
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedInterests.remove(interestId);
                              } else {
                                if (_selectedInterests.length < 10) {
                                  _selectedInterests.add(interestId);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only select up to 10 interests')));
                                }
                              }
                            });
                          },
                          child: SketchyContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            borderRadius: 999,
                            backgroundColor: isSelected ? AppColors.textColor2 : AppColors.cream,
                            child: Text('$emoji $label'.trim(), style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: isSelected ? AppColors.cream : AppColors.textColor2,
                            )),
                          ),
                        );
                      }),
                      if (hiddenCount > 0)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _expandedSegments.add(segmentId);
                            });
                          },
                          child: SketchyContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            borderRadius: 999,
                            backgroundColor: AppColors.inkBlack,
                            child: Text('+ $hiddenCount more', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.white,
                            )),
                          ),
                        ),
                      if (isExpanded && interestsList.length > initialVisibleCount)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _expandedSegments.remove(segmentId);
                            });
                          },
                          child: SketchyContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            borderRadius: 999,
                            backgroundColor: AppColors.inkBlack,
                            child: Text('Show less', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.white,
                            )),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              );
            }).toList()
          else ...[
            _buildSectionHeading(context, 'HOBBIES'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableHobbies.map((e) {
                final isSelected = _selectedHobbies.contains(e);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedHobbies.remove(e);
                      } else {
                        _selectedHobbies.add(e);
                      }
                    });
                  },
                  child: SketchyContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    borderRadius: 999,
                    backgroundColor: isSelected ? AppColors.textColor2 : AppColors.cream,
                    child: Text(e, style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected ? AppColors.cream : AppColors.textColor2,
                    )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            _buildSectionHeading(context, 'SKILLS'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableSkills.map((e) {
                final isSelected = _selectedSkills.contains(e);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSkills.remove(e);
                      } else {
                        _selectedSkills.add(e);
                      }
                    });
                  },
                  child: SketchyContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    borderRadius: 999,
                    backgroundColor: isSelected ? AppColors.textColor2 : AppColors.cream,
                    child: Text(e, style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected ? AppColors.cream : AppColors.textColor2,
                    )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
          
          _buildSectionHeading(context, 'TAGS'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTagToggle('Smoke', _smoke, (v) => setState(() => _smoke = v)),
              _buildTagToggle('Drink', _drink, (v) => setState(() => _drink = v)),
              _buildTagToggle('Pets', _pets, (v) => setState(() => _pets = v)),
            ],
          ),
          const SizedBox(height: 48),

          SketchyButton(
            text: (_selectedInterests.isNotEmpty || _selectedHobbies.isNotEmpty || _selectedSkills.isNotEmpty)
                ? 'NEXT STEP'
                : 'SKIP',
            onPressed: _nextStep,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTagToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Column(
        children: [
          SketchyContainer(
            padding: const EdgeInsets.all(12),
            borderRadius: 999,
            backgroundColor: value ? AppColors.textColor2 : AppColors.cream,
            child: Icon(
              value ? Icons.check : Icons.close,
              color: value ? AppColors.cream : AppColors.textColor2,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _buildPromptsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_sections.isNotEmpty)
            ..._sections.map((section) {
              final sectionName = section['name'] ?? 'PROMPTS';
              final sectionDesc = section['description'] ?? '';
              final promptsList = section['prompts'] as List<dynamic>? ?? [];

              final sectionId = section['id'] as String? ?? sectionName.toString();
              final isExpanded = _expandedSegments.contains(sectionId);

              final activePrompts = promptsList.where((p) {
                final id = p['id'] as String;
                return _activePromptIds.contains(id) || (_promptAnswers[id]?.isNotEmpty ?? false);
              }).toList();
              final inactivePrompts = promptsList.where((p) {
                final id = p['id'] as String;
                return !(_activePromptIds.contains(id) || (_promptAnswers[id]?.isNotEmpty ?? false));
              }).toList();

              final int initialVisibleInactiveCount = 3;
              final visibleInactivePrompts = isExpanded 
                  ? inactivePrompts 
                  : inactivePrompts.take(initialVisibleInactiveCount).toList();
                  
              final hiddenCount = inactivePrompts.length - visibleInactivePrompts.length;
              final visiblePrompts = [...activePrompts, ...visibleInactivePrompts];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeading(context, sectionName.toString().toUpperCase()),
                  if (sectionDesc.toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(sectionDesc.toString(), style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 16),
                  ...visiblePrompts.map((prompt) {
                    final promptId = prompt['id'] as String;
                    final text = prompt['text'] as String;
                    final isActive = _activePromptIds.contains(promptId) || (_promptAnswers[promptId]?.isNotEmpty ?? false);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ),
                              if (!isActive)
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppColors.textColor2),
                                  onPressed: () {
                                    setState(() {
                                      if (_activePromptIds.length < 3) {
                                        _activePromptIds.add(promptId);
                                        _promptFocusNodes[promptId] ??= FocusNode();
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          _promptFocusNodes[promptId]?.requestFocus();
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only select up to 3 prompts')));
                                      }
                                    });
                                  },
                                ),
                              if (isActive)
                                IconButton(
                                  icon: Icon(Icons.close, color: AppColors.textColor1.withOpacity(0.5), size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _activePromptIds.remove(promptId);
                                      _promptAnswers.remove(promptId);
                                    });
                                  },
                                ),
                            ],
                          ),
                          if (isActive) ...[
                            const SizedBox(height: 8),
                            SketchyContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: TextField(
                                focusNode: _promptFocusNodes.putIfAbsent(promptId, () => FocusNode()),
                                maxLines: 3,
                                minLines: 1,
                                onChanged: (val) {
                                  setState(() {
                                    _promptAnswers[promptId] = val;
                                  });
                                },
                                controller: TextEditingController(text: _promptAnswers[promptId])..selection = TextSelection.collapsed(offset: _promptAnswers[promptId]?.length ?? 0),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Write your answer...',
                                  isDense: true,
                                  suffixIcon: (_promptAnswers[promptId]?.isNotEmpty ?? false)
                                      ? IconButton(
                                          icon: const Icon(Icons.check, color: AppColors.textColor2),
                                          onPressed: () {
                                            _promptFocusNodes[promptId]?.unfocus();
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  if (hiddenCount > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedSegments.add(sectionId);
                          });
                        },
                        child: SketchyContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          borderRadius: 999,
                          backgroundColor: AppColors.inkBlack,
                          child: Text('+ $hiddenCount more', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.white,
                          )),
                        ),
                      ),
                    ),
                  if (isExpanded && inactivePrompts.length > initialVisibleInactiveCount)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedSegments.remove(sectionId);
                          });
                        },
                        child: SketchyContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          borderRadius: 999,
                          backgroundColor: AppColors.inkBlack,
                          child: Text('Show less', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.white,
                          )),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList()
          else
            const Center(child: Text('No prompts available.')),
          
          const SizedBox(height: 32),
          SketchyButton(
            text: 'NEXT STEP',
            onPressed: _isStep5Valid ? _nextStep : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeading(context, 'WHAT ARE YOU LOOKING FOR?'),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _selectedLookingFor = 'dating'),
            child: SketchyContainer(
              padding: const EdgeInsets.all(24),
              backgroundColor: _selectedLookingFor == 'dating' ? AppColors.textColor2 : AppColors.cream,
              child: Row(
                children: [
                  Icon(Icons.favorite_border, size: 32, color: _selectedLookingFor == 'dating' ? AppColors.cream : AppColors.inkBlack),
                  const SizedBox(width: 16),
                  Text('DATING', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _selectedLookingFor == 'dating' ? AppColors.cream : AppColors.inkBlack
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _selectedLookingFor = 'friends'),
            child: SketchyContainer(
              padding: const EdgeInsets.all(24),
              backgroundColor: _selectedLookingFor == 'friends' ? AppColors.textColor2 : AppColors.cream,
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 32, color: _selectedLookingFor == 'friends' ? AppColors.cream : AppColors.inkBlack),
                  const SizedBox(width: 16),
                  Text('FRIENDS ONLY', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _selectedLookingFor == 'friends' ? AppColors.cream : AppColors.inkBlack
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeading(context, 'SEXUAL ORIENTATION'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ['straight', 'gay', 'bisexual', 'other'].map((e) {
              final isSelected = _selectedSexualOrientation == e;
              return GestureDetector(
                onTap: () => setState(() => _selectedSexualOrientation = e),
                child: SketchyContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  borderRadius: 999,
                  backgroundColor: isSelected ? AppColors.textColor2 : AppColors.cream,
                  child: Text(e.toUpperCase(), style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? AppColors.cream : AppColors.textColor2,
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
          SketchyButton(
            text: 'NEXT STEP',
            onPressed: _isStep6Valid ? _nextStep : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<bool> _createProfile() async {
    // Upload images first
    List<Map<String, dynamic>> uploadedPictures = [];
    for (int i = 0; i < 4; i++) {
      if (_photoBytes[i] != null) {
        final picData = await AuthService.uploadPicture(
            _photoBytes[i]!, 'profile_pic_$i.jpg');
        if (picData != null) {
          uploadedPictures.add(picData);
        }
      }
    }

    final promptsList = _promptAnswers.entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => {"promptId": e.key, "answer": e.value.trim()})
        .toList();

    // Construct schema payload
    final data = {
      "username": _usernameController.text.trim(),
      "name": _nameController.text.trim(),
      "age": int.tryParse(_ageController.text.trim()) ?? 18,
      "bio": _bioController.text.trim(),
      "school": _schoolController.text.trim(),
      "course": _courseController.text.trim(),
      "height": int.tryParse(_heightController.text.trim()) ?? 170,
      "religion": _religionController.text.trim(),
      "gender": _selectedGender ?? 'other',
      "hobbies": _selectedHobbies.toList(),
      "skills": _selectedSkills.toList(),
      "interests": _selectedInterests.toList(),
      "prompts": promptsList,
      "lookingFor": _selectedLookingFor ?? 'dating',
      "sexualOrientation": _selectedSexualOrientation ?? 'straight',
      "tags": {
        "smoke": _smoke,
        "drink": _drink,
        "pets": _pets,
      },
      "pictures": uploadedPictures.isNotEmpty 
          ? uploadedPictures 
          : [ { "url": "https://dummyimage.com/600x800", "fileId": "dummy" } ]
    };
    
    return await AuthService.updateProfile(data);
  }

  Widget _buildProfilePreviewStep() {
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Your Name';
    final age = _ageController.text.trim().isNotEmpty ? _ageController.text.trim() : '21';
    final school = _schoolController.text.trim().isNotEmpty ? _schoolController.text.trim() : 'School';
    final course = _courseController.text.trim().isNotEmpty ? _courseController.text.trim() : 'Course';
    final bio = _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : 'Write something interesting about yourself...';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sleek Profile Card Design
          Container(
            height: 480,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.lineBlack,
                  offset: Offset(4, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Background Photo
                  ProfilePhotoPicker(
                    initialImagePath: _photoPaths[0],
                    initialProcessedBytes: _photoBytes[0],
                    onPhotosSet: (paths, bytesList) {
                      if (paths.isNotEmpty) {
                        setState(() {
                          _photoPaths[0] = paths[0];
                          _photoBytes[0] = bytesList[0];
                        });
                      }
                    },
                    allowBackgroundRemoval: false,
                    width: double.infinity,
                    height: double.infinity,
                    showChooseAnotherButton: false,
                    isBorderless: true,
                  ),
                  
                  // 2. Gradient Overlay for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 250,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.9),
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Info Overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name & Age
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                '$name, $age',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Department & Year
                        Row(
                          children: [
                            const Icon(Icons.school_outlined, size: 20, color: Colors.white70),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$school • $course',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                        
                        // Tags
                        if (_selectedHobbies.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedHobbies.take(3).map((e) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white30, width: 1),
                              ),
                              child: Text(
                                e, 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)
                              ),
                            )).toList(),
                          ),
                        ],
                        
                        // Bio
                        const SizedBox(height: 16),
                        Text(
                          '"$bio"',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Preference
                        if (_selectedLookingFor != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                _selectedLookingFor == 'dating' ? Icons.favorite : Icons.people, 
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Looking for ${_selectedLookingFor}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          SketchyButton(
            text: 'ENTER WORLD',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileCreatedScreen(saveFuture: _createProfile()),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.textColor2,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        )),
    );
  }
}
