import 'package:neom_commons/core/data/implementations/app_hive_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';

class CaseteTrialUsageManager {

  // Method to set daily trial usage
  void setDailyTrialUsage(int trialUsage) async {
    final caseteBox = await AppHiveController().getBox(AppHiveBox.casete.name);

    DateTime today = DateTime.now();
    DateTime? storedDate = caseteBox.get('dailyTrialDay') as DateTime?;
    int storedUsage = caseteBox.get('dailyTrialUsage', defaultValue: 0);

    // If the stored date is not today, reset usage
    if (storedDate == null || storedDate.day != today.day) {
      storedUsage = 0; // Reset usage for a new day
      caseteBox.put('dailyTrialDay', today); // Update the day
    }

    // Update the usage and store it in Hive
    storedUsage += trialUsage;
    caseteBox.put('dailyTrialUsage', storedUsage);

    AppUtilities.logger.d('Daily trial usage updated to: $storedUsage');
  }

  // Method to retrieve current daily trial usage
  Future<int> getDailyTrialUsage() async {
    DateTime today = DateTime.now();
    final caseteBox = await AppHiveController().getBox(AppHiveBox.casete.name);

    DateTime? storedDate = caseteBox.get('dailyTrialDay') as DateTime?;
    int storedUsage = caseteBox.get('dailyTrialUsage', defaultValue: 0);

    // Reset if the date has changed
    if (storedDate == null || storedDate.day != today.day) {
      storedUsage = 0;
      caseteBox.put('dailyTrialDay', today);
      caseteBox.put('dailyTrialUsage', 0); // Reset usage
    }

    return storedUsage;
  }

  // Method to increment the daily trial usage
  void increaseDailyTrialUsage(int increment) async {
    int currentUsage = await getDailyTrialUsage();
    setDailyTrialUsage(increment);
    AppUtilities.logger.d('Increased usage by $increment, new usage: $currentUsage');
  }
}
