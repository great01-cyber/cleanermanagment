import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MealTicketWidget extends StatelessWidget {
  final String mealName;
  final String mealDescription;
  final String issuedBy;
  final String ticketCode;
  final DateTime expiryTime;

  const MealTicketWidget({
    Key? key,
    required this.mealName,
    required this.mealDescription,
    required this.issuedBy,
    required this.ticketCode,
    required this.expiryTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            spreadRadius: 2,
            offset: Offset(2, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Ticket Title
          Center(
            child: Text(
              "Meal Ticket",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ),

          Divider(thickness: 1.5),

          // Meal Name
          Text(
            mealName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade700,
            ),
          ),

          SizedBox(height: 5),

          // Meal Description
          Text(
            mealDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 10),

          // Ticket Details
          _ticketDetail("Issued By", issuedBy),
          _ticketDetail("Ticket Code", ticketCode),
          _ticketDetail("Valid Until", "${expiryTime.hour}:${expiryTime.minute}"),

          SizedBox(height: 15),

          // QR Code
          Center(
            child: QrImageView(
              data: ticketCode,
              version: QrVersions.auto,
              size: 120,
            ),
          ),

          SizedBox(height: 10),

          // Ticket Code
          Center(
            child: Text(
              ticketCode,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(height: 10),

          // Footer Message
          Center(
            child: Text(
              "Enjoy your meal! 🍽️",
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.orange.shade700,
              ),
            ),
          ),

          SizedBox(height: 10),

          Center(
            child: Text(
              "Time Left: ${expiryTime.difference(DateTime.now()).inMinutes}:${expiryTime.difference(DateTime.now()).inSeconds % 60}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),

        ],
      ),
    );
  }

  // Meal Ticket Details Widget
  Widget _ticketDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
