import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/sticker_cutout_service.dart';
import '../theme/app_colors.dart';
import 'sketchy_button.dart';
import 'sticker_reveal.dart';

class ProfilePhotoPicker extends StatefulWidget {
  final VoidCallback onPhotoSet;
  final bool allowBackgroundRemoval;
  final double width;
  final double height;
  final bool showChooseAnotherButton;
  final bool isBorderless;

  const ProfilePhotoPicker({
    super.key, 
    required this.onPhotoSet,
    this.allowBackgroundRemoval = true,
    this.width = 240,
    this.height = 320,
    this.showChooseAnotherButton = true,
    this.isBorderless = false,
  });

  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  final ImagePicker _picker = ImagePicker();
  
  String? _originalImagePath;
  Uint8List? _processedBytes;
  bool _isProcessing = false;
  
  // To re-trigger animation when updated
  Key _stickerKey = UniqueKey();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: AppColors.cream,
            toolbarWidgetColor: AppColors.inkBlack,
            activeControlsWidgetColor: AppColors.textColor2,
            initAspectRatio: CropAspectRatioPreset.ratio4x3,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return;

      setState(() {
        _originalImagePath = croppedFile.path;
        _processedBytes = null; // Clear previous processed
        _stickerKey = UniqueKey();
      });

      if (widget.allowBackgroundRemoval) {
        // Show options dialog immediately after picking and cropping
        _showProcessingOptionsDialog(croppedFile.path);
      } else {
        widget.onPhotoSet();
      }
    } catch (e) {
      debugPrint("Error picking/cropping image: $e");
    }
  }

  Future<void> _showProcessingOptionsDialog(String imagePath) async {
    bool? removeBg = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.lineBlack, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Remove Background?', style: TextStyle(color: AppColors.textColor2, fontWeight: FontWeight.bold)),
        content: const Text('Would you like to magically remove the background from your photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: AppColors.lineBlack)),
          ),
          SketchyButton(
            text: 'Yes',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (removeBg == null || !removeBg) {
      widget.onPhotoSet();
      return;
    }

    if (!mounted) return;
    
    // Paper theme dialog commented out for now — only BG removal is active
    // bool? paperTheme = await showDialog<bool>(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (context) => AlertDialog(
    //     backgroundColor: AppColors.cream,
    //     shape: RoundedRectangleBorder(
    //       side: const BorderSide(color: AppColors.lineBlack, width: 2),
    //       borderRadius: BorderRadius.circular(16),
    //     ),
    //     title: Text('Apply Paper Theme?', style: TextStyle(color: AppColors.textColor2, fontWeight: FontWeight.bold)),
    //     content: const Text('Would you like to turn your photo into a paper sticker?'),
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.pop(context, false),
    //         child: const Text('No', style: TextStyle(color: AppColors.lineBlack)),
    //       ),
    //       SketchyButton(
    //         text: 'Yes',
    //         onPressed: () => Navigator.pop(context, true),
    //       ),
    //     ],
    //   ),
    // );
    // paperTheme ??= false;
    const bool paperTheme = false; // Paper theme disabled for now

    // Now start processing
    setState(() {
      _isProcessing = true;
    });

    final bytes = await StickerCutoutService.generateSticker(
      imagePath,
      applyPaperTheme: paperTheme,
    );

    setState(() {
      _isProcessing = false;
      if (bytes != null) {
        _processedBytes = bytes;
        _stickerKey = UniqueKey();
        widget.onPhotoSet();
      } else {
        // Fallback or show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Could not detect a person in the photo. Try another one!"),
            backgroundColor: AppColors.textColor2,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = GestureDetector(
      onTap: _isProcessing ? null : _pickImage,
      child: Container(
        width: widget.width,
        height: widget.height == double.infinity ? null : widget.height,
        decoration: widget.isBorderless
          ? BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
            )
          : BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lineBlack, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.lineBlack,
                  offset: Offset(4, 4),
                )
              ],
            ),
        child: _buildImageContent(),
      ),
    );

    if (widget.height == double.infinity) {
      imageWidget = Expanded(child: imageWidget);
    }

    return Column(
      mainAxisSize: widget.height == double.infinity ? MainAxisSize.max : MainAxisSize.min,
      children: [
        imageWidget,
        if (widget.showChooseAnotherButton && !_isProcessing && _originalImagePath != null) ...[
          const SizedBox(height: 24),
          SketchyButton(
            text: 'CHOOSE ANOTHER',
            onPressed: _pickImage,
          ),
        ]
      ],
    );
  }

  Widget _buildImageContent() {
    if (_isProcessing) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textColor2),
        ),
      );
    }

    if (_processedBytes != null) {
      return StickerReveal(
        key: _stickerKey,
        child: Image.memory(
          _processedBytes!,
          fit: BoxFit.contain,
        ),
      );
    }

    if (_originalImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.isBorderless ? 16 : 14),
        child: Image.file(
          File(_originalImagePath!),
          fit: BoxFit.cover,
        ),
      );
    }

    // Placeholder
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo, size: 48, color: AppColors.lineBlack),
          SizedBox(height: 12),
          Text(
            'TAP TO UPLOAD',
            style: TextStyle(
              color: AppColors.lineBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
