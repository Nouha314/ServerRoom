import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:server_room_new/my_ui.dart';
import 'package:server_room_new/my_voids.dart';
import 'package:server_room_new/profile/manage_profile_ctr.dart';

import '../models/user.dart';

class ManageProfile extends StatefulWidget {
  const ManageProfile({Key? key}) : super(key: key);

  @override
  _ManageProfileState createState() => _ManageProfileState();
}

class _ManageProfileState extends State<ManageProfile> {
  final _formKey = GlobalKey<FormState>();
  final _formKeyPwd = GlobalKey<FormState>();
  final _formKeyConfirmPwd = GlobalKey<FormState>();
  final ManageProfileCtr gc = Get.put<ManageProfileCtr>(ManageProfileCtr());

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Widget prop(title, prop) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9.0),
      child: Row(
        children: [
          Text(
            '$title',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Text(
            '$prop',
            style: TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryCol,
        title: const Text("Manage My Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 15,
                    ),
                    prop('User ID:  ', '${currentUser.id}'),
                    prop('User Name:  ', '${currentUser.name}'),
                    prop('User Email:  ', '${currentUser.email}'),
                    prop('Admin access:  ', '${currentUser.isAdmin ? 'Validated' : 'Not Validated'}'),
                  ],
                ),
              ),
              SizedBox(
                height: 25,
              ),
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Information',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                            color: Colors.blue,
                            letterSpacing: 1.5,
                            fontSize: 18
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Form(
                          key: _formKey,
                          child: SizedBox(
                            width: 62.w,
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: "Name"),
                              controller: _nameController,
                              validator: (value) {
                                if (value!.length < 4) {
                                  return "Name must be at least 4 characters long";
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  await usersColl.doc(currentUser.id).get().then((DocumentSnapshot documentSnapshot) async {
                                    if (documentSnapshot.exists) {
                                      await usersColl.doc(currentUser.id).update({
                                        'name': _nameController.text,
                                      }).then((value) async {
                                        // Update current user in memory
                                        currentUser.name = _nameController.text;
                                        
                                        // Update UI
                                        setState(() {});
                                        
                                        showSnk('Name updated successfully');
                                      }).catchError((error) {
                                        showSnk('Error updating name: $error');
                                      });
                                    }
                                  });
                                }
                              },
                              child: const Text("Change"),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Change Password',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                            color: Colors.blue,
                            letterSpacing: 1.5,
                            fontSize: 18
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Form(
                          key: _formKeyPwd,
                          child: SizedBox(
                            width: 62.w,
                            child: TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: "New Password",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                              validator: (value) {
                                if (value!.length < 8) {
                                  return "Password must be at least 8 characters long";
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Form(
                          key: _formKeyConfirmPwd,
                          child: SizedBox(
                            width: 62.w,
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: "Confirm Password",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isConfirmPasswordVisible,
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return "Passwords do not match";
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKeyPwd.currentState!.validate() && 
                                    _formKeyConfirmPwd.currentState!.validate()) {
                                  
                                  User? user = FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    try {
                                      // Update Firebase Auth password
                                      await user.updatePassword(_passwordController.text);
                                      
                                      // Also update Firestore for consistency
                                      await usersColl.doc(currentUser.id).update({
                                        'pwd': _passwordController.text,
                                      });
                                      
                                      // Clear password fields
                                      _passwordController.clear();
                                      _confirmPasswordController.clear();
                                      
                                      showSnk('Password updated successfully');
                                    } catch (e) {
                                      showSnk('This operation is sensitive and requires recent authentication.\nLog in again before retrying this request');
                                      print('## Failed to update password: $e');
                                    }
                                  }
                                }
                              },
                              child: const Text("Change"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
