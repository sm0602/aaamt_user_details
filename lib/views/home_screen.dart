import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'user_controller.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  final UserController userController = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange.shade200,
        title: Text(
          "User Details",
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Obx(() {
                final position = userController.currentPosition.value;
                final address = userController.currentAddress.value;
                return position != null
                    ? Padding(
                        padding: EdgeInsets.all(8.0.w),
                        child: Text(
                          'Location: ${position.latitude}, ${position.longitude}\nAddress: $address',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      )
                    : Center(child: CircularProgressIndicator());
              }),
              Obx(() {
                if (userController.isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: userController.users.length,
                    itemBuilder: (context, index) {
                      final user = userController.users[index];
                      final localImagePath =
                          userController.getLocalImagePath(user.id);

                      return ListTile(
                        leading: SizedBox(
                          width: 50.w,
                          height: 50.h,
                          child: localImagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50.r),
                                  child: Image.file(
                                    File(localImagePath),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(50.r),
                                  child: Image.network(
                                    user.avatar,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                        title: Text(
                          '${user.firstName} ${user.lastName}',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        subtitle: Text(
                          user.email,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.upload,
                            size: 20.sp,
                          ),
                          onPressed: () =>
                              _showImageSourceDialog(context, user.id),
                        ),
                      );
                    },
                  );
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context, int userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Upload Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  userController.uploadImage(userId, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  userController.uploadImage(userId, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
