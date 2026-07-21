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
  final void Function(List<String> imagePaths, List<Uint8List?> processedBytes) onPhotosSet;
  final bool allowBackgroundRemoval;
  final double width;
  final double height;
  final bool showChooseAnotherButton;
  final bool isBorderless;
  final String? initialImagePath;
  final Uint8List? initialProcessedBytes;
  final bool isSmall;

  const ProfilePhotoPicker({
    super.key, 
    required this.onPhotosSet,
    this.allowBackgroundRemoval = true,
    this.width = 240,
    this.height = 320,
    this.showChooseAnotherButton = true,
    this.isBorderless = false,
    this.initialImagePath,
    this.initialProcessedBytes,
    this.isSmall = false,
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

  @override
  void initState() {
    super.initState();
    _originalImagePath = widget.initialImagePath;
    _processedBytes = widget.initialProcessedBytes;
  }

  @override
  void didUpdateWidget(ProfilePhotoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImagePath != oldWidget.initialImagePath || 
        widget.initialProcessedBytes != oldWidget.initialProcessedBytes) {
      _originalImagePath = widget.initialImagePath;
      _processedBytes = widget.initialProcessedBytes;
    }
  }

  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(limit: 4);
      if (images.isEmpty) return;

      setState(() {
        _isProcessing = true;
      });

      List<String> finalPaths = [];
      List<Uint8List?> finalBytes = [];

      for (int i = 0; i < images.length && i < 4; i++) {
        final XFile image = images[i];
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo ${i + 1}',
              toolbarColor: AppColors.cream,
              toolbarWidgetColor: AppColors.inkBlack,
              activeControlsWidgetColor: AppColors.textColor2,
              initAspectRatio: CropAspectRatioPreset.ratio4x3,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Photo ${i + 1}',
              aspectRatioLockEnabled: false,
            ),
          ],
        );

        if (croppedFile == null) continue;

        final bytes = await File(croppedFile.path).readAsBytes();
        finalPaths.add(croppedFile.path);
        finalBytes.add(bytes);
      }

      setState(() {
        if (finalPaths.isNotEmpty) {
          _originalImagePath = finalPaths[0];
          _processedBytes = finalBytes[0];
          _stickerKey = UniqueKey();
        }
        _isProcessing = false;
      });

      if (finalPaths.isNotEmpty) {
        widget.onPhotosSet(finalPaths, finalBytes);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      setState(() {
        _isProcessing = false;
      });
    }
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageContent(),
            if ((_originalImagePath != null || _processedBytes != null) && !_isProcessing)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(widget.isSmall ? 4 : 8),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lineBlack, width: 2),
                  ),
                  child: Icon(Icons.refresh, size: widget.isSmall ? 16 : 20, color: AppColors.inkBlack),
                ),
              ),
          ],
        ),
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
      final isNetworkUrl = _originalImagePath!.startsWith('http');
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.isBorderless ? 16 : 14),
        child: isNetworkUrl
            ? Image.network(
                _originalImagePath!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textColor2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: AppColors.lineBlack, size: 40),
                ),
              )
            : Image.file(
                File(_originalImagePath!),
                fit: BoxFit.cover,
              ),
      );
    }

    // Placeholder
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo, size: widget.isSmall ? 28 : 48, color: AppColors.lineBlack),
          if (!widget.isSmall) ...[
            const SizedBox(height: 12),
            const Text(
              'TAP TO UPLOAD',
              style: TextStyle(
                color: AppColors.lineBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
