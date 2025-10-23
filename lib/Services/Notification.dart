import 'package:flutter/cupertino.dart';

class NotificationProvider with ChangeNotifier {
  List<String> _notifications = []; // Store the list of notifications

  List<String> get notifications => _notifications;

  // Add new notification
  void addNotification(String message) {
    _notifications.insert(0, message); // Insert new message at the top
    notifyListeners(); // Notify all listeners (Cleaner Dashboard)
  }

  // Clear all notifications
  void clearNotifications() {
    _notifications.clear(); // Remove all notifications
    notifyListeners(); // Notify all listeners
  }
}
