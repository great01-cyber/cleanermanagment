import 'package:flutter/material.dart';

class MealTicketProvider with ChangeNotifier {
  List<MealTicket> _mealTickets = [];

  List<MealTicket> get mealTickets => _mealTickets;

  void addMealTicket(MealTicket ticket) {
    _mealTickets.add(ticket);
    notifyListeners();
  }

  void removeExpiredTickets() {
    _mealTickets.removeWhere((ticket) => ticket.isExpired);
    notifyListeners();
  }
}
class MealTicket {
  final String title;
  final String description;
  final int durationInMinutes;
  late DateTime expiryTime;

  MealTicket({
    required this.title,
    required this.description,
    required this.durationInMinutes,
  }) {
    expiryTime = DateTime.now().add(Duration(minutes: durationInMinutes));
  }

  bool get isExpired => DateTime.now().isAfter(expiryTime);

  String get ticketCode => expiryTime.millisecondsSinceEpoch.toString(); // 🔥 This will generate the unique code
}
