import 'package:flutter/material.dart';
import 'package:turf_client/constants/assets.dart';
import 'package:turf_client/models/user.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final User user;

  EditProfileScreen({required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _profilePicture;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _profilePicture = widget.user.profilePicture;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profilePicture = pickedFile.path;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profilePicture != null
                      ? FileImage(File(_profilePicture!))
                      : AssetImage(Assets.profilePicture) as ImageProvider,
                  child: _profilePicture == null
                      ? Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildTextField('Name', _nameController),
            SizedBox(height: 10),
            _buildTextField('Email', _emailController),
            SizedBox(height: 10),
            _buildTextField('Phone', _phoneController),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle save profile logic
                  Navigator.pop(
                      context,
                      User(
                        name: _nameController.text,
                        email: _emailController.text,
                        phone: _phoneController.text,
                        city: widget.user.city,
                        profilePicture:
                            _profilePicture ?? widget.user.profilePicture,
                      ));
                },
                child: Text('Save'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}
