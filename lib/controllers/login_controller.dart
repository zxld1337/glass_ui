// basic
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:glass_ui/services/network_service.dart';
import 'package:glass_ui/utils/constants.dart' as cv;
// services
import 'package:glass_ui/client/user.dart';
// routing
import 'package:glass_ui/routes/app_routes.dart';
// hive database
import 'package:hive_flutter/hive_flutter.dart';

import 'frame_controller.dart';

class LoginController extends GetxController {
  // ui vars
  final buttonText = "Bejelentkezés".obs;
  final isObscure = true.obs;
  // text controllers
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  // db refrence
  final mainBox = Hive.box("MainBox");

  @override
  void onInit() {
    super.onInit();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // on Button Press
  void signUserIn() async {
    if (!Get.find<NetworkService>().hasConnection) {
      buttonText("Nincsen internet!");
      return;
    }

    String username = usernameController.text;
    String password = passwordController.text;

    // assert problems && validate imput
    if (!_studentIsValid(username, password)) return;

    final user = User(
      username,
      password,
      cv.instituteCode,
    );

    await user.init();
    final loginSuccess = await user.login();

    if (!loginSuccess) {
      buttonText("Hibás Jelszó, vagy Felhasználónév");
      return;
    }

    buttonText("Sikeres bejelentkezés");
    await _addStudentToDb(username, password, user.bearer.toMap());

    // TODO when relogin set to mainPage
    if (Get.parameters['relogin'] == null) {
      Get.offNamed(Routes.NAVIGATOR);
    } else {
      //? Get.find<FrameController>().onBottomMenuTap(0); not working
      Get.back();
    }
  }

  // validating inputs
  bool _studentIsValid(String user, String password) {
    if (user.isEmpty) {
      buttonText("Üres Felhasználónév mező!");
      return false;
    }
    if (password.isEmpty) {
      buttonText("Üres Jelszó mező!");
      return false;
    }
    return true;
  }

  // save valid user to database
  Future<void> _addStudentToDb(String usr, String pwd, Map brr) async {
    await mainBox.put("username", usr);
    await mainBox.put("password", pwd);
    await mainBox.put("bearer", brr);
  }

  void resetButtonText(String text) => buttonText("Bejelentkezés");
}
