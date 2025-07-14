import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FaceVerificationService {
  static double? lastConfidence = 0;
  static double? lastThreshold = 0;

  // Download the stored image from a URL to a local temporary file
  static Future<File> _downloadImageToFile(String imageUrl, String filename) async {
    try {
      print('⬇️ Downloading stored image from: $imageUrl');
      final response = await http.get(Uri.parse(imageUrl));
      print('📥 HTTP Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);
        print('✅ Stored image saved to ${file.path} (${bytes.length} bytes)');
        return file;
      } else {
        throw Exception('❌ Failed to download stored image: ${response.statusCode}');
      }
    } catch (e) {
      print('❗ Exception during image download: $e');
      rethrow;
    }
  }

  // Main method to verify face by sending live image and stored image to Flask
  static Future<bool> verifyFace(File liveImage, String storedImageUrl) async {
    try {
      // Step 1: Download stored image locally
      final storedImageFile = await _downloadImageToFile(storedImageUrl, 'stored_face.jpg');

      print('📡 Preparing POST request to Flask server...');
      print('📷 Live image path: ${liveImage.path}');
      print('📷 Stored image path: ${storedImageFile.path}');
      print('📁 Live image exists: ${await liveImage.exists()}');
      print('📁 Stored image exists: ${await storedImageFile.exists()}');

      if (!await liveImage.exists() || !await storedImageFile.exists()) {
        print('❌ One or both image files do not exist.');
        return false;
      }

      // Flask server endpoint — update IP if needed
      final uri = Uri.parse('http://172.16.18.188:5000/verify_face');

      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('live', liveImage.path))
        ..files.add(await http.MultipartFile.fromPath('stored', storedImageFile.path));

      print('📨 Sending multipart POST request...');
      final streamedResponse = await request.send().timeout(Duration(seconds: 10));
      final responseBody = await streamedResponse.stream.bytesToString();

      print('📨 Flask response status: ${streamedResponse.statusCode}');
      print('📨 Flask response body: $responseBody');

      if (streamedResponse.statusCode != 200) {
        print('❌ Flask server returned error status: ${streamedResponse.statusCode}');
        return false;
      }

      // Parse JSON response from Flask
      final json = jsonDecode(responseBody);
      final matched = json['match'] == true;
      lastConfidence = (json['confidence'] ?? 0).toDouble();
      lastThreshold = (json['threshold'] ?? 0).toDouble();

      print('🔍 Face verification result:');
      print('   Match: $matched');
      print('   Confidence: $lastConfidence');
      print('   Threshold: $lastThreshold');

      return matched;
    } catch (e) {
      print('❗ Exception in verifyFace(): $e');
      return false;
    }
  }
}
