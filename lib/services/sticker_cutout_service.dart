import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class StickerCutoutService {
  static final SelfieSegmenter _segmenter = SelfieSegmenter(
    mode: SegmenterMode.single,
    enableRawSizeMask: true,
  );

  /// Main entry point to process an image and return the sticker bytes
  static Future<Uint8List?> generateSticker(String imagePath, {bool applyPaperTheme = true}) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final mask = await _segmenter.processImage(inputImage);
      
      if (mask == null) {
        throw Exception("Failed to segment image or no person found.");
      }

      // Run heavy pixel manipulation in an isolate
      final processedBytes = await compute(_processPixels, {
        'imagePath': imagePath,
        'maskConfidences': mask.confidences, // This is Float32List
        'maskWidth': mask.width,
        'maskHeight': mask.height,
        'applyPaperTheme': applyPaperTheme,
      });

      if (processedBytes != null) {
        // Cache the processed bytes
        final tempDir = await getApplicationDocumentsDirectory();
        final fileName = "sticker_${imagePath.hashCode}.png";
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(processedBytes);
      }

      return processedBytes;
    } catch (e) {
      debugPrint("Error generating sticker: $e");
      return null;
    }
  }

  static Future<Uint8List?> _processPixels(Map<String, dynamic> params) async {
    final String imagePath = params['imagePath'];
    final dynamic maskConfidences = params['maskConfidences'];
    final int maskWidth = params['maskWidth'];
    final int maskHeight = params['maskHeight'];
    final bool applyPaperTheme = params['applyPaperTheme'] ?? true;

    // 1. Decode original image at full resolution
    final File imageFile = File(imagePath);
    final img.Image? originalImage = img.decodeImage(imageFile.readAsBytesSync());
    if (originalImage == null) return null;

    final int origW = originalImage.width;
    final int origH = originalImage.height;

    // Create cutout at original image resolution (RGBA)
    final img.Image cutout = img.Image(width: origW, height: origH, numChannels: 4);

    // Track bounding box of the subject
    int minX = origW;
    int minY = origH;
    int maxX = 0;
    int maxY = 0;
    bool foundSubject = false;

    // Scale factors to map original image coords → mask coords
    final double invScaleX = maskWidth / origW;
    final double invScaleY = maskHeight / origH;

    // Iterate over EVERY pixel of the original image and sample its alpha from the mask.
    // This ensures no pixel is left unwritten (which happened when iterating mask→original).
    for (int oy = 0; oy < origH; oy++) {
      for (int ox = 0; ox < origW; ox++) {
        // Map this original pixel to the corresponding mask pixel
        final int mx = (ox * invScaleX).round().clamp(0, maskWidth - 1);
        final int my = (oy * invScaleY).round().clamp(0, maskHeight - 1);

        final int index = my * maskWidth + mx;
        final double confidence = (maskConfidences[index] as num).toDouble();
        final int alpha = (confidence * 255).clamp(0, 255).toInt();

        if (alpha > 20) {
          foundSubject = true;
          if (ox < minX) minX = ox;
          if (ox > maxX) maxX = ox;
          if (oy < minY) minY = oy;
          if (oy > maxY) maxY = oy;
        }

        final pixel = originalImage.getPixel(ox, oy);
        cutout.setPixelRgba(ox, oy, pixel.r, pixel.g, pixel.b, alpha);
      }
    }

    if (!foundSubject) return null; // No person detected

    // Crop to subject bounding box — still at full original resolution
    final img.Image croppedCutout = img.copyCrop(
      cutout,
      x: minX,
      y: minY,
      width: (maxX - minX + 1).clamp(1, origW),
      height: (maxY - minY + 1).clamp(1, origH),
    );

    if (!applyPaperTheme) {
      // Return the full-resolution transparent PNG — no quality loss
      return img.encodePng(croppedCutout);
    }

    // 2. Generate White Border
    final int borderWidth = 12;
    final int padding = borderWidth + 16;

    img.Image paddedMask = img.Image(width: croppedCutout.width + padding * 2, height: croppedCutout.height + padding * 2, numChannels: 1);

    for (int y = 0; y < croppedCutout.height; y++) {
      for (int x = 0; x < croppedCutout.width; x++) {
        final pixel = croppedCutout.getPixel(x, y);
        if (pixel.a > 20) {
          paddedMask.setPixelRgba(x + padding, y + padding, 255, 255, 255, 255);
        }
      }
    }

    // Dilate (naive 4-way neighbor iterative)
    img.Image dilatedMask = paddedMask.clone();
    for (int i = 0; i < borderWidth; i++) {
      img.Image temp = dilatedMask.clone();
      for (int y = 1; y < temp.height - 1; y++) {
        for (int x = 1; x < temp.width - 1; x++) {
          if (dilatedMask.getPixel(x, y).a == 0) {
            if (dilatedMask.getPixel(x - 1, y).a > 0 ||
                dilatedMask.getPixel(x + 1, y).a > 0 ||
                dilatedMask.getPixel(x, y - 1).a > 0 ||
                dilatedMask.getPixel(x, y + 1).a > 0) {
              temp.setPixelRgba(x, y, 255, 255, 255, 255);
            }
          }
        }
      }
      dilatedMask = temp;
    }

    // 3. Drop Shadow
    img.Image finalImage = img.Image(width: dilatedMask.width, height: dilatedMask.height, numChannels: 4);
    final int shadowOffsetX = 6;
    final int shadowOffsetY = 6;

    for (int y = 0; y < dilatedMask.height; y++) {
      for (int x = 0; x < dilatedMask.width; x++) {
        if (dilatedMask.getPixel(x, y).a > 0) {
          int sy = y + shadowOffsetY;
          int sx = x + shadowOffsetX;
          if (sx < finalImage.width && sy < finalImage.height) {
            finalImage.setPixelRgba(sx, sy, 0, 0, 0, 80);
          }
        }
      }
    }

    // Blur shadow
    finalImage = img.gaussianBlur(finalImage, radius: 8);

    // 4. Composite white border
    for (int y = 0; y < dilatedMask.height; y++) {
      for (int x = 0; x < dilatedMask.width; x++) {
        if (dilatedMask.getPixel(x, y).a > 0) {
          finalImage.setPixelRgba(x, y, 255, 255, 255, 255);
        }
      }
    }

    // 5. Composite original cutout on top
    img.compositeImage(finalImage, croppedCutout, dstX: padding, dstY: padding);

    // Encode to PNG
    return img.encodePng(finalImage);
  }
}
