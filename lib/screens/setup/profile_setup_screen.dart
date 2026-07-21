import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/profile_photo_picker.dart';
import '../../widgets/sketchy_progress_bar.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  final List<String> _availableHobbies = [
    'Gaming', 'Anime', 'Coding', 'Hiking', 'Music', 'Art', 'Coffee', 'Movies',
    'Reading', 'Photography', 'Sports', 'Travel'
  ];
  final Set<String> _selectedHobbies = {};

  final List<String> _availableSkills = ['JavaScript', 'Python', 'Dart', 'Figma', 'UI/UX', 'Writing', 'Music', 'Public Speaking'];
  final Set<String> _selectedSkills = {};

  final List<String?> _photoPaths = List.filled(4, null);
  final List<Uint8List?> _photoBytes = List.filled(4, null);

  bool _smoke = false;
  bool _drink = false;
  bool _pets = false;

  String? _selectedLookingFor;
  String? _selectedSexualOrientation;
  bool _isSaving = false;

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
          Text('USERNAME', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _usernameController,
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'newusername', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 24),
          Text('NAME', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'John Updated', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
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
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: '21', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 24),
          Text('BIO', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'New bio text', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 24),
          Text('SCHOOL', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _schoolController,
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Adamas University', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 24),
          Text('COURSE', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _courseController,
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'CSE', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
            ),
          ),
          const SizedBox(height: 24),
          Text('HEIGHT (cm)', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 8),
          SketchyContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: '175', hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))),
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
          Text('HOBBIES', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
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
          Text('SKILLS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
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
          Text('TAGS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
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
            text: 'NEXT STEP',
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

  Widget _buildPreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('WHAT ARE YOU LOOKING FOR?', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _selectedLookingFor = 'dating'),
            child: SketchyContainer(
              padding: const EdgeInsets.all(24),
              backgroundColor: _selectedLookingFor == 'dating' ? AppColors.textColor2.withOpacity(0.1) : AppColors.cream,
              child: Row(
                children: [
                  Icon(Icons.favorite_border, size: 32, color: _selectedLookingFor == 'dating' ? AppColors.textColor2 : AppColors.inkBlack),
                  const SizedBox(width: 16),
                  Text('DATING', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _selectedLookingFor == 'dating' ? AppColors.textColor2 : AppColors.inkBlack
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
              backgroundColor: _selectedLookingFor == 'friends' ? AppColors.textColor2.withOpacity(0.1) : AppColors.cream,
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 32, color: _selectedLookingFor == 'friends' ? AppColors.textColor2 : AppColors.inkBlack),
                  const SizedBox(width: 16),
                  Text('FRIENDS ONLY', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _selectedLookingFor == 'friends' ? AppColors.textColor2 : AppColors.inkBlack
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('SEXUAL ORIENTATION', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
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
          if (_isSaving)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textColor2),
              ),
            )
          else
            SketchyButton(
              text: 'ENTER WORLD',
              onPressed: () async {
                setState(() {
                  _isSaving = true;
                });

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

                // Construct schema payload
                final data = {
                  "username": _usernameController.text.trim(),
                  "name": _nameController.text.trim(),
                  "age": int.tryParse(_ageController.text.trim()) ?? 18,
                  "bio": _bioController.text.trim(),
                  "school": _schoolController.text.trim(),
                  "course": _courseController.text.trim(),
                  "height": int.tryParse(_heightController.text.trim()) ?? 170,
                  "hobbies": _selectedHobbies.toList(),
                  "skills": _selectedSkills.toList(),
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
                
                bool success = await AuthService.updateProfile(data);
                
                if (mounted) {
                  setState(() {
                    _isSaving = false;
                  });
                  if (success) {
                    Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
                  }
                }
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
