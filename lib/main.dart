import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const CropDoctorApp());

class CropDoctorApp extends StatelessWidget {
  const CropDoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Doctor',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const DiseaseDetectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  File? _image;
  List<dynamic>? _predictions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
      );
    } catch (e) {
      debugPrint("Failed to load model: $e");
    }
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required')),
        );
        return;
      }
    }

    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _isLoading = true;
    });

    await _predictDisease(File(pickedFile.path));
  }

  Future<void> _predictDisease(File image) async {
    try {
      final predictions = await Tflite.runModelOnImage(
        path: image.path,
        imageMean: 127.5,
        imageStd: 127.5,
        numResults: 3,
        threshold: 0.4,
      );

      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Prediction error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Disease Detector')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageButton(ImageSource.camera, Icons.camera_alt),
                  _buildImageButton(ImageSource.gallery, Icons.photo_library),
                ],
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _image != null
                      ? Column(
                          children: [
                            Image.file(_image!, height: 250),
                            const SizedBox(height: 24),
                            _predictions != null && _predictions!.isNotEmpty
                                ? _buildResults()
                                : const Text(
                                    'No predictions found',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ],
                        )
                      : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageButton(ImageSource source, IconData icon) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(source == ImageSource.camera ? 'Camera' : 'Gallery'),
      onPressed: () => _pickImage(source),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detection Results:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._predictions!.map((prediction) => ListTile(
              title: Text(
                prediction['label']?.toString() ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Confidence: ${((prediction['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%',
              ),
            )).toList(),
      ],
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}