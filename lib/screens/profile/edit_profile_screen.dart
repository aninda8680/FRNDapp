import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/profile_photo_picker.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_service.dart';
import 'profile_updated_screen.dart';
import '../../utils/responsive_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _religionController = TextEditingController();
  final TextEditingController _beliefsController = TextEditingController();

  String? _selectedLookingFor;
  String? _selectedSexualOrientation;
  String? _selectedGender;
  
  final List<String?> _photoPaths = List.filled(4, null);
  final List<Uint8List?> _photoBytes = List.filled(4, null);
  final List<Map<String, dynamic>> _existingPictures = [];
  
  bool _isLoading = true;
  bool _isLoadingConfig = true;
  bool _isSaving = false;

  bool _smoke = false;
  bool _drink = false;
  bool _pets = false;

  List<dynamic> _segments = [];
  List<dynamic> _sections = [];
  
  final Set<String> _selectedInterests = {};
  final Map<String, String> _promptAnswers = {};
  final Set<String> _activePromptIds = {};
  final Set<String> _expandedSegments = {};

  final List<String> _availableHobbies = [
    'Gaming', 'Anime', 'Coding', 'Hiking', 'Music', 'Art', 'Coffee', 'Movies',
    'Reading', 'Photography', 'Sports', 'Travel'
  ];
  final Set<String> _selectedHobbies = {};

  final List<String> _availableSkills = ['JavaScript', 'Python', 'Dart', 'Figma', 'UI/UX', 'Writing', 'Music', 'Public Speaking'];
  final Set<String> _selectedSkills = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _schoolController.dispose();
    _courseController.dispose();
    _heightController.dispose();
    _religionController.dispose();
    _beliefsController.dispose();
    super.dispose();
  }

  void _populateFields(Map<String, dynamic> data) {
    _usernameController.text = data['username'] ?? '';
    _nameController.text = data['name'] ?? '';
    _ageController.text = data['age']?.toString() ?? '';
    _bioController.text = data['bio'] ?? '';
    _schoolController.text = data['school'] ?? '';
    _courseController.text = data['course'] ?? '';
    _heightController.text = data['height']?.toString() ?? '';
    _religionController.text = data['religion'] ?? '';
    _beliefsController.text = data['beliefs'] ?? '';
    _selectedLookingFor = data['lookingFor'];
    _selectedSexualOrientation = data['sexualOrientation'];
    _selectedGender = data['gender'];
    
    if (data['tags'] != null && data['tags'] is Map) {
      _smoke = data['tags']['smoke'] == true;
      _drink = data['tags']['drink'] == true;
      _pets = data['tags']['pets'] == true;
    } else {
      _smoke = false;
      _drink = false;
      _pets = false;
    }

    _selectedHobbies.clear();
    final hobbies = data['hobbies'] as List<dynamic>?;
    if (hobbies != null) _selectedHobbies.addAll(hobbies.map((e) => e.toString()));

    _selectedSkills.clear();
    final skills = data['skills'] as List<dynamic>?;
    if (skills != null) _selectedSkills.addAll(skills.map((e) => e.toString()));

    _selectedInterests.clear();
    final interests = data['interests'] as List<dynamic>?;
    if (interests != null) {
      _selectedInterests.addAll(interests.map((i) {
        if (i is Map) return i['interestId']?.toString() ?? i['id']?.toString() ?? '';
        return i.toString();
      }).where((s) => s.isNotEmpty));
    }

    _promptAnswers.clear();
    final prompts = data['prompts'] as List<dynamic>?;
    if (prompts != null) {
      for (var p in prompts) {
        if (p is Map && p['promptId'] != null) {
          _promptAnswers[p['promptId']] = p['answer']?.toString() ?? '';
        }
      }
    }

    _existingPictures.clear();
    for (int i = 0; i < 4; i++) _photoPaths[i] = null;
    final pictures = data['pictures'] as List<dynamic>?;
    if (pictures != null) {
      for (int i = 0; i < pictures.length && i < 4; i++) {
        _existingPictures.add(pictures[i] as Map<String, dynamic>);
        _photoPaths[i] = pictures[i]['url'] as String?;
      }
    }
  }

  Future<void> _loadProfileData() async {
    // 1. Populate instantly from in-memory cache — zero network wait
    final cached = AuthService.userProfile;
    if (cached != null && mounted) {
      setState(() {
        _populateFields(cached);
        _isLoading = false;
      });
    }

    // 2. Fetch onboarding config in the background (for interests/prompts pickers)
    final config = await OnboardingService.fetchConfig();
    if (mounted && config != null) {
      setState(() {
        _segments = config['segments'] ?? [];
        _sections = config['sections'] ?? [];
        _isLoadingConfig = false;
      });
    }
  }

  Future<bool> _performSave() async {

    final data = {
      "username": _usernameController.text.trim(),
      "name": _nameController.text.trim(),
      "age": int.tryParse(_ageController.text.trim()) ?? 18,
      "bio": _bioController.text.trim(),
      "school": _schoolController.text.trim(),
      "course": _courseController.text.trim(),
      "height": int.tryParse(_heightController.text.trim()),
      "religion": _religionController.text.trim(),
      "beliefs": _beliefsController.text.trim(),
      "tags": {
        "smoke": _smoke,
        "drink": _drink,
        "pets": _pets,
      },
    };

    if (_selectedLookingFor != null) {
      data["lookingFor"] = _selectedLookingFor!;
    }
    if (_selectedSexualOrientation != null) {
      data["sexualOrientation"] = _selectedSexualOrientation!;
    }
    if (_selectedGender != null) {
      data["gender"] = _selectedGender!;
    }

    final promptsList = _promptAnswers.entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => {"promptId": e.key, "answer": e.value.trim()})
        .toList();

    data["hobbies"] = _selectedHobbies.toList();
    data["skills"] = _selectedSkills.toList();
    data["interests"] = _selectedInterests.toList();
    data["prompts"] = promptsList;

    // Process pictures
    List<Map<String, dynamic>> finalPictures = [];
    for (int i = 0; i < 4; i++) {
      if (_photoBytes[i] != null) {
        // Upload new picture
        final picData = await AuthService.uploadPicture(_photoBytes[i]!, 'profile_pic_$i.jpg');
        if (picData != null) {
          finalPictures.add(picData);
        }
      } else if (_photoPaths[i] != null && _photoPaths[i]!.startsWith('http')) {
        // Existing picture
        final existing = _existingPictures.firstWhere(
            (p) => p['url'] == _photoPaths[i],
            orElse: () => <String, dynamic>{});
        if (existing.isNotEmpty) {
          finalPictures.add(existing);
        } else {
          finalPictures.add({"url": _photoPaths[i], "fileId": "unknown"});
        }
      }
    }
    
    if (finalPictures.isNotEmpty) {
      data["pictures"] = finalPictures;
    }

    // Clean up nulls
    data.removeWhere((key, value) => value == null);

    return await AuthService.updateProfile(data);
  }

  void _saveChanges() {
    final saveFuture = _performSave();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileUpdatedScreen(saveFuture: saveFuture),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(context, label),
        SizedBox(height: context.responsiveHeight(8)),
        SketchyContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              isDense: true, 
              border: InputBorder.none, 
              hintText: 'Enter $label...', 
              hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5))
            ),
          ),
        ),
        SizedBox(height: context.responsiveHeight(24)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EDIT PROFILE'),
        backgroundColor: AppColors.textColor2,
        foregroundColor: AppColors.white,
      ),
      bottomNavigationBar: !_isLoading
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.cream,
                border: Border(top: BorderSide(color: AppColors.textColor2.withOpacity(0.2), width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SketchyButton(
                text: 'SAVE CHANGES',
                onPressed: _saveChanges,
              ),
            )
          : null,
      body: SafeArea(
        child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textColor2),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMainSectionHeading(context, 'PROFILE PHOTOS'),
                  SizedBox(height: context.responsiveHeight(16)),
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
                  SizedBox(height: context.responsiveHeight(32)),
                  
                  _buildMainSectionHeading(context, 'BASIC INFO'),
                  SizedBox(height: context.responsiveHeight(8)),
                  _buildTextField('USERNAME', _usernameController),
                  _buildTextField('NAME', _nameController),
                  _buildTextField('AGE', _ageController, keyboardType: TextInputType.number),
                  
                  _buildSectionHeading(context, 'GENDER'),
                  SizedBox(height: context.responsiveHeight(16)),
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
                            fontWeight: FontWeight.bold,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: context.responsiveHeight(28)),

                  _buildMainSectionHeading(context, 'ABOUT YOU'),
                  SizedBox(height: context.responsiveHeight(8)),
                  _buildTextField('BIO', _bioController, maxLines: 3),
                  _buildTextField('SCHOOL', _schoolController),
                  _buildTextField('COURSE', _courseController),
                  _buildTextField('HEIGHT (cm)', _heightController, keyboardType: TextInputType.number),
                  _buildTextField('RELIGION', _religionController),
                  _buildTextField('BELIEFS', _beliefsController),
                  
                  _buildMainSectionHeading(context, 'INTERESTS'),
                  SizedBox(height: context.responsiveHeight(16)),
                  _buildInterestsSection(),

                  _buildMainSectionHeading(context, 'PROMPTS'),
                  SizedBox(height: context.responsiveHeight(16)),
                  _buildPromptsSection(),

                  _buildMainSectionHeading(context, 'TAGS'),
                  SizedBox(height: context.responsiveHeight(16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTagToggle('Smoke', _smoke, (v) => setState(() => _smoke = v)),
                      _buildTagToggle('Drink', _drink, (v) => setState(() => _drink = v)),
                      _buildTagToggle('Pets', _pets, (v) => setState(() => _pets = v)),
                    ],
                  ),
                  SizedBox(height: context.responsiveHeight(16)),

                  _buildMainSectionHeading(context, 'LOOKING FOR'),
                  SizedBox(height: context.responsiveHeight(16)),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedLookingFor = 'dating'),
                          child: SketchyContainer(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _selectedLookingFor == 'dating' ? AppColors.textColor2 : AppColors.cream,
                            child: Center(child: Text('DATING', style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedLookingFor == 'dating' ? AppColors.cream : AppColors.textColor2,
                            ))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedLookingFor = 'friends'),
                          child: SketchyContainer(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _selectedLookingFor == 'friends' ? AppColors.textColor2 : AppColors.cream,
                            child: Center(child: Text('FRIENDS ONLY', style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedLookingFor == 'friends' ? AppColors.cream : AppColors.textColor2,
                            ))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.responsiveHeight(48)),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildInterestsSection() {
    if (_isLoadingConfig) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(segmentName.toString().toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textColor2, fontWeight: FontWeight.w900)),
                ),
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
                              _selectedInterests.add(interestId);
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
                SizedBox(height: context.responsiveHeight(24)),
              ],
            );
          }).toList()
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('HOBBIES', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textColor2, fontWeight: FontWeight.w900)),
          ),
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
          SizedBox(height: context.responsiveHeight(20)),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('SKILLS', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textColor2, fontWeight: FontWeight.w900)),
          ),
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
          SizedBox(height: context.responsiveHeight(24)),
        ]
      ],
    );
  }

  Widget _buildPromptsSection() {
    if (_isLoadingConfig) return const SizedBox.shrink();

    return Column(
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(sectionName.toString().toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textColor2, fontWeight: FontWeight.w900)),
                ),
                if (sectionDesc.toString().isNotEmpty) ...[
                  SizedBox(height: context.responsiveHeight(4)),
                  Text(sectionDesc.toString(), style: Theme.of(context).textTheme.bodyMedium),
                ],
                SizedBox(height: context.responsiveHeight(16)),
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
                                    _activePromptIds.add(promptId);
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
                          SizedBox(height: context.responsiveHeight(8)),
                          SketchyContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: TextField(
                              maxLines: 3,
                              minLines: 1,
                              onChanged: (val) {
                                _promptAnswers[promptId] = val;
                              },
                              controller: TextEditingController(text: _promptAnswers[promptId])..selection = TextSelection.collapsed(offset: _promptAnswers[promptId]?.length ?? 0),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Write your answer...',
                                isDense: true,
                              ),
                            ),
                          ),
                        ]
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
                SizedBox(height: context.responsiveHeight(16)),
              ],
            );
          }).toList(),
      ],
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
          SizedBox(height: context.responsiveHeight(8)),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _buildMainSectionHeading(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 2,
              color: AppColors.textColor2.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textColor2,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              )),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: AppColors.textColor2.withOpacity(0.3),
            ),
          ),
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
