import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:server_room_new/auth/register.dart';
import 'package:server_room_new/models/user.dart';
import 'package:server_room_new/my_voids.dart';

import '../home_page/home_page.dart';
import '../my_ui.dart';



class MyLogin extends StatefulWidget {
  const MyLogin({Key? key}) : super(key: key);

  @override
  _MyLoginState createState() => _MyLoginState();
}

class _MyLoginState extends State<MyLogin> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> loginButtonPressed() async {
    //dialogShow('Error', 'Please enter your email and password');

    // Check if email and password fields are not empty
    if (_formKey.currentState!.validate()) {
      try {
        print('## try to signIn');

        //try signIn
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        ).then((value) async {
          //account found

          await getUserInfoByEmail(_emailController.text).then((value) {



            if(currentUser.verified || currentUser.isAdmin){
              Get.offAll(() => HomePage());
              //toastShow('Welcome');
            }else{
              toastShow('You\'re not approved yet',color: Colors.redAccent);
            }


          });
        });

        // signIn error
      } on FirebaseAuthException catch (e) {
        print('## error signIn => ${e.message}');
        if (e.code == 'user-not-found') {
          dialogShow('User not found', '');

          print('## user not found');
        } else if (e.code == 'wrong-password') {
          dialogShow('Wrong password', '');

          print('## wrong password');
        }else{
          dialogShow('user not found', '');

          print('## unknown error');
        }
      } catch (e) {
        print('## catch err in signIn user_auth: $e');
      }
      // Navigate to home page
    }


  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: backGroundTemplate(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40.0),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20.0),
                    child: Text(
                      'Welcome back\n',
                      style: TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
                ),
                TextFormField(

                  validator: (value) {


                    if ( value == null || value == '' || !EmailValidator.validate(value!)) {
                      return "Please enter a valid email address";
                    }
                    return null;
                  },
                  controller: _emailController,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  validator: (value) {
                    if (value!.length < 8) {
                      return "Password must be at least 8 characters long";
                    }
                    return null;
                  },

                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Password',
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: loginButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(33, 150, 243, 1),
                  ),
                  child: const Text('Login',style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    Get.to(()=>MyRegister());
                  },
                  style: TextButton.styleFrom(
                   // backgroundColor: const Color.fromRGBO(33, 150, 243, 1),
                  ),
                  child: const Text('Create an account',style: TextStyle(
                  ),),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
