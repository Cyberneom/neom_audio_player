import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/enums/app_hive_box.dart';

class CaseteTrialUsageManager {
  final Box _box = Hive.box(AppHiveBox.casete.name);

  // Method to set daily trial usage
  void setDailyTrialUsage(int trialUsage) {
    DateTime today = DateTime.now();
    DateTime? storedDate = _box.get('dailyTrialDay') as DateTime?;
    int storedUsage = _box.get('dailyTrialUsage', defaultValue: 0);

    // If the stored date is not today, reset usage
    if (storedDate == null || storedDate.day != today.day) {
      storedUsage = 0; // Reset usage for a new day
      _box.put('dailyTrialDay', today); // Update the day
    }

    // Update the usage and store it in Hive
    storedUsage += trialUsage;
    _box.put('dailyTrialUsage', storedUsage);

    AppUtilities.logger.d('Daily trial usage updated to: $storedUsage');
  }

  // Method to retrieve current daily trial usage
  int getDailyTrialUsage() {
    DateTime today = DateTime.now();
    DateTime? storedDate = _box.get('dailyTrialDay') as DateTime?;
    int storedUsage = _box.get('dailyTrialUsage', defaultValue: 0);

    // Reset if the date has changed
    if (storedDate == null || storedDate.day != today.day) {
      storedUsage = 0;
      _box.put('dailyTrialDay', today);
      _box.put('dailyTrialUsage', 0); // Reset usage
    }

    return storedUsage;
  }

  // Method to increment the daily trial usage
  void increaseDailyTrialUsage(int increment) {
    int currentUsage = getDailyTrialUsage();
    setDailyTrialUsage(increment);
    AppUtilities.logger.d('Increased usage by $increment, new usage: $currentUsage');
  }
}
