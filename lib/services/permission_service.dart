import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request camera and microphone permissions for calling
  Future<bool> requestCallPermissions() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      
      // Request microphone permission
      final microphoneStatus = await Permission.microphone.request();
      
      // Check if both permissions are granted
      final isGranted = cameraStatus.isGranted && microphoneStatus.isGranted;
      
      print('[PermissionService] Camera: $cameraStatus, Microphone: $microphoneStatus');
      
      return isGranted;
    } catch (e) {
      print('[PermissionService] Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if camera and microphone permissions are granted
  Future<bool> hasCallPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final microphoneStatus = await Permission.microphone.status;
      
      return cameraStatus.isGranted && microphoneStatus.isGranted;
    } catch (e) {
      print('[PermissionService] Error checking permissions: $e');
      return false;
    }
  }

  /// Request specific permission
  Future<bool> requestPermission(Permission permission) async {
    try {
      final status = await permission.request();
      return status.isGranted;
    } catch (e) {
      print('[PermissionService] Error requesting $permission: $e');
      return false;
    }
  }

  /// Check specific permission status
  Future<bool> hasPermission(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isGranted;
    } catch (e) {
      print('[PermissionService] Error checking $permission: $e');
      return false;
    }
  }

  /// Open app settings if permissions are permanently denied
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('[PermissionService] Error opening app settings: $e');
    }
  }
} 