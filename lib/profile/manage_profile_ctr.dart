

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ManageProfileCtr extends GetxController {


  void changeUserEmailPwd(email,pwd)async{

    AuthCredential cred = EmailAuthProvider.credential(email: email, password: pwd);
    User user = await FirebaseAuth.instance.currentUser!;
    var authResult = await user.reauthenticateWithCredential(cred);

    User newUser = authResult.user!;
    print('## newUser: <${newUser.email}/${''}>');
  }
}