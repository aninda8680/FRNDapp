import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/profile_photo_picker.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_service.dart';
import 'profile_updated_screen.dart';

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

  String? _selectedLookingFor;
  String? _selectedSexualOrientation;
  String? _selectedGender;
  
  final List<String?> _photoPaths = List.filled(4, null);
  final List<Uint8List?> _photoBytes = List.filled(4, null);
  final List<Map<String, dynamic>> _existingPictures = [];
  
  bool _isLoading = true;
  bool _isLoadingConfig = true;
  bool _isSaving = false;

  List<dynamic> _segments = [];
  List<dynamic> _sections = [];
  
  final Set<String> _selectedInterests = {};
  final Map<String, String> _promptAnswers = {};
  final Set<String> _activePromptIds = {};

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
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final config = await OnboardingService.fetchConfig();
    final data = await AuthService.getProfile();
    
    if (mounted) {
      setState(() {
        if (config != null) {
          _segments = config['segments'] ?? [];
          _sections = config['sections'] ?? [];
        }

        if (data != null) {
          _usernameController.text = data['username'] ?? '';
          _nameController.text = data['name'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _bioController.text = data['bio'] ?? '';
          _schoolController.text = data['school'] ?? '';
          _courseController.text = data['course'] ?? '';
          _heightController.text = data['height']?.toString() ?? '';
          _selectedLookingFor = data['lookingFor'];
          _selectedSexualOrientation = data['sexualOrientation'];
          _selectedGender = data['gender'];
          
          final hobbies = data['hobbies'] as List<dynamic>?;
          if (hobbies != null) _selectedHobbies.addAll(hobbies.map((e) => e.toString()));
          
          final skills = data['skills'] as List<dynamic>?;
          if (skills != null) _selectedSkills.addAll(skills.map((e) => e.toString()));
          
          final interests = data['interests'] as List<dynamic>?;
          if (interests != null) {
            _selectedInterests.addAll(interests.map((i) {
               if (i is Map) return i['interestId']?.toString() ?? i['id']?.toString() ?? '';
               return i.toString();
            }).where((s) => s.isNotEmpty));
          }

          final prompts = data['prompts'] as List<dynamic>?;
          if (prompts != null) {
             for (var p in prompts) {
               if (p is Map && p['promptId'] != null) {
                 _promptAnswers[p['promptId']] = p['answer']?.toString() ?? '';
               }
             }
          }
          
          final pictures = data['pictures'] as List<dynamic>?;
          if (pictures != null) {
            for (int i = 0; i < pictures.length && i < 4; i++) {
              _existingPictures.add(pictures[i] as Map<String, dynamic>);
              _photoPaths[i] = pictures[i]['url'] as String?;
            }
          }
        }
        
        _isLoading = false;
        _isLoadingConfig = false;
      });
      
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile data.')),
        );
      }
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
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
        const SizedBox(height: 8),
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
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EDIT PROFILE')),
      bottomNavigationBar: !_isLoading
          ? Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 16.0),
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
                  
                  _buildTextField('USERNAME', _usernameController),
                  _buildTextField('NAME', _nameController),
                  _buildTextField('AGE', _ageController, keyboardType: TextInputType.number),
                  
                  Text('GENDER', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
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

                  _buildTextField('BIO', _bioController, maxLines: 3),
                  _buildTextField('SCHOOL', _schoolController),
                  _buildTextField('COURSE', _courseController),
                  _buildTextField('HEIGHT (cm)', _heightController, keyboardType: TextInputType.number),
                  
                  const SizedBox(height: 16),
                  _buildInterestsSection(),
                  const SizedBox(height: 24),
                  _buildPromptsSection(),
                  const SizedBox(height: 16),

                  Text('WHAT ARE YOU LOOKING FOR?', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedLookingFor = 'dating'),
                          child: SketchyContainer(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _selectedLookingFor == 'dating' ? AppColors.textColor2.withOpacity(0.2) : AppColors.cream,
                            child: const Center(child: Text('DATING', style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedLookingFor = 'friends'),
                          child: SketchyContainer(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _selectedLookingFor == 'friends' ? AppColors.textColor2.withOpacity(0.2) : AppColors.cream,
                            child: const Center(child: Text('FRIENDS ONLY', style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
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
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(segmentName.toString().toUpperCase(), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: interestsList.map((interest) {
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
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList()
        else ...[
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
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(sectionName.toString().toUpperCase(), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textColor2)),
                if (sectionDesc.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(sectionDesc.toString(), style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                ...promptsList.map((prompt) {
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
                          const SizedBox(height: 8),
                          SketchyContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: TextField(
                              maxLines: 3,
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Your answer...',
                                hintStyle: TextStyle(color: AppColors.textColor1.withOpacity(0.5)),
                              ),
                              onChanged: (val) {
                                _promptAnswers[promptId] = val;
                              },
                              controller: TextEditingController(text: _promptAnswers[promptId] ?? '')..selection = TextSelection.collapsed(offset: (_promptAnswers[promptId] ?? '').length),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          }).toList(),
      ],
    );
  }
}
