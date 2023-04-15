// state manager
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// backend client
import 'package:mini_naplo/services/client/user.dart';
import 'chart_controller.dart';
// database
import 'package:hive/hive.dart';
// utils
import 'package:mini_naplo/services/controllers/network_service.dart';
import 'package:mini_naplo/services/models/models.dart';
import 'package:mini_naplo/constants/constants.dart' as cv;


class ApiService extends GetxService {
  // reactive variables
  final timeTable = <TimeTable>[].obs;
  final grades = <Grade>[].obs;
  final gradesPerSubject = <dynamic, dynamic>{}.obs;
  final absence = Absences().obs;
  final student = Student().obs;
  final _user = User().obs;
  final isDataLoaded = false.obs;
  // db instance
  final db = Hive.box('MainBox');

  // getters
  get user => _user.value;
  get bearerAsMap => _user.value.bearer.toMap();

  @override
  Future<void> onInit() async {
    super.onInit();

    // early returns for offline and null database
    if (!await Get.find<NetworkService>().isOnline()) return;
    if (db.get('username') == null) return;

    // show dialog till data loading
    showDialog(
      context: Get.overlayContext!,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );

    await createUser(
      username: db.get('username'),
      password: db.get('password'),
      institute: cv.instituteCode,
    );
    await initData();
    isDataLoaded(true);

    Navigator.of(Get.overlayContext!).pop();
  }

  // returns true if user created successfully
  Future<bool> createUser({
    required String username,
    required String password,
    required String institute,
  }) async {
    _user(User(
      user: username,
      password: password,
      institute: institute,
    ));
    await user.init();
    
    return await user.login();
  }

  Future<void> refreshData() async {
    if (!await Get.find<NetworkService>().isOnline()) return;

    await user.refreshBearer();
    await initData();
  }

  Future<void> initData() async {
    student(await user.getStudentInfo());
    absence(await user.getAbsences());
    grades(await user.getEvaluations());

    Get.find<ChartController>().setData(grades);
    getGps();

    try {
      timeTable(await user.getTable());
    } catch (e) {
      // errors if not school day
    }
  }

  void getGps() {
    // Group by sub
    gradesPerSubject(Grade.getGradesPerSubject(grades.value));
    // Remove sub where 0
    gradesPerSubject.removeWhere((key, value) => value["calculated"] == 0);
    gradesPerSubject.removeWhere((key, value) => value["calculated"].isNaN);
    // Sort by DESC
    gradesPerSubject.value = Grade.sortByCustom(gradesPerSubject, "calculated");
  }
}
