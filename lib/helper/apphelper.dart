import 'package:shared_preferences/shared_preferences.dart';

class AppHelper {
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstLaunch') ?? true;
    if (isFirstTime) {
      await prefs.setBool('isFirstLaunch', false);
    }
    return isFirstTime;
  }
}
