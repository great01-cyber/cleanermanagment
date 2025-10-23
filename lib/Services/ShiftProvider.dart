import 'package:flutter/material.dart';

class Shift {
  final String date;
  final String time;
  final String location;
  final String cleaner;
  final String description;

  Shift({required this.date, required this.time, required this.location, required this.cleaner, required this.description});
}

class ShiftProvider extends ChangeNotifier {
  List<Shift> _shifts = [];

  List<Shift> get shifts => _shifts;

  void addShift(Shift shift) {
    _shifts.add(shift);
    notifyListeners(); // Notify UI to rebuild
  }
}
