import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'api_services.dart';
import 'user_model.dart';

class UserController extends GetxController {
  var users = <User>[].obs;
  var isLoading = false.obs;
  var currentPosition = Rxn<Position>();
  var currentAddress = ''.obs;
  final _userImagesBox = Hive.box('userImages');
  final _imagePicker = ImagePicker();
  final _imagePathsMap =
      <int, String>{}.obs; // New observable map for image paths

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    fetchCurrentLocation();
    _loadSavedImages(); // Load saved images when controller initializes
  }

  void _loadSavedImages() {
    for (var key in _userImagesBox.keys) {
      _imagePathsMap[key] = _userImagesBox.get(key);
    }
  }

  void fetchUsers() async {
    try {
      isLoading(true);
      final fetchedUsers = await ApiService.fetchUsers();
      users.assignAll(fetchedUsers);
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.best),
      );
      currentPosition.value = position;

      resolveAddress(position.latitude, position.longitude);
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  Future<void> resolveAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        currentAddress.value =
            '${placemark.street}, ${placemark.locality}, ${placemark.country}';
      } else {
        currentAddress.value = 'Address not found';
      }
    } catch (e) {
      currentAddress.value = 'Error resolving address';
      print('Error resolving address: $e');
    }
  }

  Future<void> uploadImage(int userId) async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = pickedFile.name;
        final permanentPath = '${appDir.path}/$fileName';
        final tempFile = File(pickedFile.path);
        final permanentFile = await tempFile.copy(permanentPath);

        // Save to both Hive and the observable map
        _userImagesBox.put(userId, permanentFile.path);
        _imagePathsMap[userId] = permanentFile.path;

        // Update the users list to trigger a rebuild
        users.refresh();
      } catch (e) {
        print('Error saving image: $e');
      }
    }
  }

  String? getLocalImagePath(int userId) {
    return _imagePathsMap[userId] ?? _userImagesBox.get(userId);
  }
}
