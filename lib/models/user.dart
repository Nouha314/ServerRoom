import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../auth/login.dart';
import '../my_voids.dart';

class SrUser {
  String? id;
  String? email;
  String? name;
  String? pwd;
  bool isAdmin;
  bool verified;

  SrUser({
    this.id = 'js1cLhYXwqC6NAcxNjJ8',
    this.email = 'no-email',
    this.name = 'no-name',
    this.isAdmin = true, //change later
    this.verified = false,
    this.pwd = 'no-pwd',
  });
}

SrUser SrUserFromMap(userDoc) {
  SrUser user = SrUser();

  user.id = userDoc.get('id');
  user.email = userDoc.get('email');
  user.pwd = userDoc.get('pwd');
  user.name = userDoc.get('name');
  user.verified = userDoc.get('verified');
  user.isAdmin = userDoc.get('isAdmin');

  print('## User_Props_loaded From database');

  return user;
}

Future<void> getUserInfoByEmail(userEmail) async {
  await usersColl.where('email', isEqualTo: userEmail).get().then((event) {
    var userDoc = event.docs.single;
    currentUser = SrUserFromMap(userDoc);
    printUser(currentUser);
  }).catchError((e) => print("## cant find user in db: $e"));
}

printUser(SrUser user) {
  print('#### USER ####\n'
      '--id: ${user.id} \n'
      '--email: ${user.email} \n'
      '--pwd: ${user.pwd} \n'
      '--name: ${user.name} \n'
      '--verified: ${user.verified} \n'
      '--isAdmin: ${user.isAdmin} \n');
}

deleteUserFromAuth(email,pwd) async {
  //auth user to delete
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: pwd,
  ).then((value) async {
    print('## account: <${FirebaseAuth.instance.currentUser!.email}> deleted');
    //delete user
    FirebaseAuth.instance.currentUser!.delete();

    //signIn with admin
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: currentUser.email!,
      password: currentUser.pwd!,
    );
    print('## admin: <${FirebaseAuth.instance.currentUser!.email}> reSigned in');

  });




}

 logoutUser()  {
  //SharedPreferences preferences = await SharedPreferences.getInstance();
  //await preferences.clear();
  FirebaseAuth.instance.signOut().then((value) {
    Get.offAll(() => MyLogin());
  });
}