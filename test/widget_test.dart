import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helper/main.dart'; // Updated package name
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  setUpAll(() {
    ImagePicker.platform = TestImagePicker();
    PermissionHandler().mock();
  });

  testWidgets('Initial UI Verification', (WidgetTester tester) async {
    await tester.pumpWidget(const CropDoctorApp());
    expect(find.text('Crop Disease Detector'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });

  testWidgets('Image Selection Flow', (WidgetTester tester) async {
    await tester.pumpWidget(const CropDoctorApp());
    
    // Test camera flow
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Test gallery flow
    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

// Test implementations
class TestImagePicker extends ImagePicker {
  dynamic response;
  @override
  Future<XFile?> pickImage({ImageSource? source, CameraDevice preferredCameraDevice = CameraDevice.rear}) async {
    return response ?? XFile('test_image.jpg');
  }
}

class MockPermissionHandler extends PermissionHandler {
  @override
  Future<PermissionStatus> request(Permission permission) async => PermissionStatus.granted;
  void mock() => PermissionHandler.instance = this;
}