import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen({super.key});

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _videoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String _uploadStatus = '';

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _videoFile = File(video.path);
        _uploadStatus = '';
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null ||
        _titleController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a video, title, and description'),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading...';
    });

    // Update with your IP or use 10.0.2.2 for Android Emulator
    var uri = Uri.parse('http://192.168.1.3:8000/api/upload-video');
    var request = http.MultipartRequest('POST', uri);

    // Add string fields
    request.fields['title'] = _titleController.text;
    request.fields['description'] = _descriptionController.text;

    // Attach the file
    var multipartFile = await http.MultipartFile.fromPath(
      'video',
      _videoFile!.path,
    );
    request.files.add(multipartFile);

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("Response body ${response.body}");
      debugPrint("Response status code ${response.statusCode}");

      if (response.statusCode == 200) {
        setState(() {
          _uploadStatus = 'Upload Successful!';
        });
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _videoFile = null;
        });
      } else {
        setState(() {
          _uploadStatus = 'Upload Failed: ${response.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('Exception $e');
      setState(() {
        _uploadStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Video & Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            if (_videoFile != null)
              Text(
                'Selected File: ${_videoFile!.path.split('/').last}',
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            else
              Text('No video selected.', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text('Pick Video from Gallery'),
            ),
            SizedBox(height: 20),
            if (_isUploading)
              Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _uploadVideo,
                child: Text('Upload Content'),
              ),
            SizedBox(height: 20),
            Text(
              _uploadStatus,
              style: TextStyle(
                color: _uploadStatus.contains('Successful')
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
