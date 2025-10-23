import 'package:flutter/material.dart';

class CleanerReportAccidents extends StatefulWidget {
  const CleanerReportAccidents({super.key});

  @override
  State<CleanerReportAccidents> createState() => _CleanerReportAccidentsState();
}

class _CleanerReportAccidentsState extends State<CleanerReportAccidents> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Report Accidents"),
      ),
    );
  }
}
