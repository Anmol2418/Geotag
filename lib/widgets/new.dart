import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/face_verification_service.dart';
import '../utils/api_client.dart'; // Your own API helper class

class ClockInFaceVerification extends StatefulWidget {
  final String employeeId;
  const ClockInFaceVerification({Key? key, required this.employeeId}) : super(key: key);

  @override
  State<ClockInFaceVerification> createState() => _ClockInFaceVerificationState();
}

class _ClockInFaceVerificationState extends State<ClockInFaceVerification> {
  final ImagePicker _picker = ImagePicker();
  File? _liveImage;
  bool _isVerifying = false;
  String? _message;

  // Step 1: Pick live image from camera
  Future<void> _captureFace() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera);
    if (img != null) {
      setState(() {
        _liveImage = File(img.path);
        _message = null;
      });
    }
  }

  // Step 2 & 3: Get stored image URL & verify face
  Future<void> _verifyAndClockIn() async {
    if (_liveImage == null) {
      setState(() {
        _message = 'Please capture your face photo first.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _message = null;
    });

    try {
      final response = await ApiClient.get('/employees/${widget.employeeId}', auth: true);
      final storedImageUrl = response['face_image_url'] as String?;

      if (storedImageUrl == null || storedImageUrl.isEmpty) {
        setState(() {
          _message = 'No registered face image found.';
        });
        return;
      }

      final verified = await FaceVerificationService.verifyFace(_liveImage!, storedImageUrl);
      final confidence = FaceVerificationService.lastConfidence ?? 0.0;
      final threshold = FaceVerificationService.lastThreshold ?? 0.0;

      if (verified) {
        setState(() {
          _message = 'Face verified! Clock in successful.';
        });

        // TODO: Call your clock-in API here
        // await AttendanceService.clockIn(widget.employeeId, DateTime.now());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clock-in successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _message = 'Face mismatch. Access denied.\nConfidence: $confidence vs Threshold: $threshold';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face mismatch. Access denied.\nConfidence: $confidence vs Threshold: $threshold'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _message = 'Verification error: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clock In - Face Verification')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _liveImage != null
                ? Image.file(_liveImage!, height: 200)
                : Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: Text('No live face captured')),
                  ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isVerifying ? null : _captureFace,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture Face'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isVerifying ? null : _verifyAndClockIn,
              icon: _isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified_user),
              label: Text(_isVerifying ? 'Verifying...' : 'Verify & Clock In'),
            ),
            const SizedBox(height: 20),
            if (_message != null) Text(_message!, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
