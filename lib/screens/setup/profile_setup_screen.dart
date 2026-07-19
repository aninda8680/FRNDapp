import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/profile_photo_picker.dart';
import '../../widgets/sketchy_progress_bar.dart';
import '../../theme/app_colors.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  final List<String> _availableInterests = [
    'Gaming', 'Anime', 'Coding', 'Hiking', 'Music', 'Art', 'Coffee', 'Movies',
    'Reading', 'Photography', 'Sports', 'Travel'
  ];
  final Set<String> _selectedInterests = {};
  String? _selectedPreference;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _deptController.dispose();
    _yearController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentIndex < 4) {
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
    double progress = (_currentIndex + 1) * 0.2;
    String leftLabel = 'STEP ${_currentIndex + 1}';
    
    final titles = [
      'CREATE PROFILE',
      'PROFILE PHOTOS',
      'SKILLS',
      'HOBBIES',
      'PROFILE CARD'
    ];
    
    final rightLabels = [
      'BASIC INFO',
      'VISUALS',
      'INTERESTS',
      'GOALS',
      'READY!'
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex > 0) {
          _previousStep();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[_currentIndex]),
          leading: _currentIndex > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousStep,
                )
              : null,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
                child: SketchyProgressBar(
                  progress: progress,
                  leftLabel: leftLabel,
                  rightLabel: rightLabels[_currentIndex],
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
                    _buildUploadPhotosStep(),
                    _buildInterestsStep(),
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
          Text('WHAT IS YOUR NAME?', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Name', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 24),
          Text('AGE', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _ageController,
              keyboardType: TextInputType.number, 
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: '18', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 24),
          Text('Department', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _deptController,
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Computer Science', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 24),
          Text('YEAR', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _yearController,
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: '1st, 2nd, 3rd, 4th ...', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 24),
          SketchyButton(
            text: 'NEXT STEP',
            onPressed: _nextStep,
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
          Text('PROFILE PHOTOS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
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
              return SketchyContainer(
                padding: EdgeInsets.zero,
                child: Center(
                  child: Icon(Icons.add_a_photo_outlined, size: 48, color: AppColors.inkBlack),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          SketchyButton(
            text: 'NEXT STEP',
            onPressed: _nextStep,
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableInterests.map((e) {
              final isSelected = _selectedInterests.contains(e);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(e);
                    } else {
                      _selectedInterests.add(e);
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
          Text('PERSONALITY PROMPT', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 8),
          SketchyContainer(
            child: TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: InputDecoration(border: InputBorder.none, hintText: 'A random fact about me...', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 48),
          SketchyButton(
            text: 'NEXT STEP',
            onPressed: _nextStep,
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
          Text('WHAT ARE YOU LOOKING FOR?', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _selectedPreference = 'Dating'),
            child: SketchyContainer(
              padding: const EdgeInsets.all(24),
              backgroundColor: _selectedPreference == 'Dating' ? AppColors.textColor2.withOpacity(0.1) : AppColors.cream,
              child: Row(
                children: [
                  Icon(Icons.favorite_border, size: 32, color: _selectedPreference == 'Dating' ? AppColors.textColor2 : AppColors.inkBlack),
                  const SizedBox(width: 16),
                  Text('DATING', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _selectedPreference == 'Dating' ? AppColors.textColor2 : AppColors.inkBlack
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _selectedPreference = 'Friends Only'),
            child: SketchyContainer(
              padding: const EdgeInsets.all(24),
              backgroundColor: _selectedPreference == 'Friends Only' ? AppColors.textColor2.withOpacity(0.1) : AppColors.cream,
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 32, color: _selectedPreference == 'Friends Only' ? AppColors.textColor2 : AppColors.inkBlack),
                  const SizedBox(width: 16),
                  Text('FRIENDS ONLY', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _selectedPreference == 'Friends Only' ? AppColors.textColor2 : AppColors.inkBlack
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          SketchyButton(
            text: 'NEXT STEP',
            onPressed: _nextStep,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfilePreviewStep() {
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Your Name';
    final age = _ageController.text.trim().isNotEmpty ? _ageController.text.trim() : '21';
    final dept = _deptController.text.trim().isNotEmpty ? _deptController.text.trim() : 'Department';
    final year = _yearController.text.trim().isNotEmpty ? _yearController.text.trim() : 'Year';
    final prompt = _promptController.text.trim().isNotEmpty ? _promptController.text.trim() : 'Write something interesting about yourself...';

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
                    onPhotoSet: () {},
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
                                '$dept • $year',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                        
                        // Tags
                        if (_selectedInterests.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedInterests.take(3).map((e) => Container(
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
                        
                        // Prompt
                        const SizedBox(height: 16),
                        Text(
                          '"$prompt"',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Preference
                        if (_selectedPreference != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                _selectedPreference == 'Dating' ? Icons.favorite : Icons.people, 
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Looking for ${_selectedPreference}',
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
            onPressed: _nextStep,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
