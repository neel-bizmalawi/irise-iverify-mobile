import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;

class ImageUtils {
  /// Compress image to target size in KB
  /// Default target is 500KB
  static Future<File?> compressImage(
    File file, {
    int targetSizeKB = 500,
    int quality = 85,
  }) async {
    try {
      developer.log('Starting image compression...', name: 'ImageUtils');
      
      // Get file size in KB
      final fileSizeKB = await file.length() / 1024;
      developer.log('Original file size: ${fileSizeKB.toStringAsFixed(2)} KB', name: 'ImageUtils');
      
      // If file is already smaller than target, return original
      if (fileSizeKB <= targetSizeKB) {
        developer.log('File already under target size, skipping compression', name: 'ImageUtils');
        return file;
      }
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}',
      );
      
      // Compress image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1024,
        minHeight: 1024,
      );
      
      if (result == null) {
        developer.log('Compression failed, returning original file', name: 'ImageUtils');
        return file;
      }
      
      // Check compressed file size
      final compressedFile = File(result.path);
      final compressedSizeKB = await compressedFile.length() / 1024;
      developer.log('Compressed file size: ${compressedSizeKB.toStringAsFixed(2)} KB', name: 'ImageUtils');
      
      // If still too large, try with lower quality
      if (compressedSizeKB > targetSizeKB && quality > 50) {
        developer.log('File still too large, trying lower quality...', name: 'ImageUtils');
        return await compressImage(file, targetSizeKB: targetSizeKB, quality: quality - 15);
      }
      
      return compressedFile;
    } catch (e) {
      developer.log('Error compressing image: $e', name: 'ImageUtils');
      return file; // Return original file if compression fails
    }
  }
  
  /// Save compressed image to app documents directory
  static Future<String?> saveCompressedImage(
    File file, {
    String prefix = 'img',
    int targetSizeKB = 500,
  }) async {
    try {
      // Compress image first
      final compressedFile = await compressImage(file, targetSizeKB: targetSizeKB);
      
      if (compressedFile == null) {
        return null;
      }
      
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      final savedPath = path.join(appDir.path, fileName);
      
      // Copy compressed file to app directory
      final savedFile = await compressedFile.copy(savedPath);
      
      developer.log('Image saved to: ${savedFile.path}', name: 'ImageUtils');
      
      return savedFile.path;
    } catch (e) {
      developer.log('Error saving compressed image: $e', name: 'ImageUtils');
      return null;
    }
  }
  
  /// Get file size in KB
  static Future<double> getFileSizeKB(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      return bytes / 1024;
    } catch (e) {
      developer.log('Error getting file size: $e', name: 'ImageUtils');
      return 0;
    }
  }
}
