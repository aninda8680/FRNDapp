import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../widgets/sketchy_button.dart';
import '../../widgets/sketchy_container.dart';
import '../../widgets/profile_photo_picker.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
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
  
  final List<String?> _photoPaths = List.filled(4, null);
  final List<Uint8List?> _photoBytes = List.filled(4, null);
  final List<Map<String, dynamic>> _existingPictures = [];
  
  bool _isLoading = true;
  bool _isSaving = false;

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
    final data = await AuthService.getProfile();
    if (data != null && mounted) {
      setState(() {
        _usernameController.text = data['username'] ?? '';
        _nameController.text = data['name'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _bioController.text = data['bio'] ?? '';
        _schoolController.text = data['school'] ?? '';
        _courseController.text = data['course'] ?? '';
        _heightController.text = data['height']?.toString() ?? '';
        _selectedLookingFor = data['lookingFor'];
        _selectedSexualOrientation = data['sexualOrientation'];
        
        final pictures = data['pictures'] as List<dynamic>?;
        if (pictures != null) {
          for (int i = 0; i < pictures.length && i < 4; i++) {
            _existingPictures.add(pictures[i] as Map<String, dynamic>);
            _photoPaths[i] = pictures[i]['url'] as String?;
          }
        }
        
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile data.')),
      );
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
                  _buildTextField('BIO', _bioController, maxLines: 3),
                  _buildTextField('SCHOOL', _schoolController),
                  _buildTextField('COURSE', _courseController),
                  _buildTextField('HEIGHT (cm)', _heightController, keyboardType: TextInputType.number),
                  
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
                  
                  SketchyButton(
                    text: 'SAVE CHANGES',
                    onPressed: _saveChanges,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      ),
    );
  }
}
