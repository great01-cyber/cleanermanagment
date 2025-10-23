import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Services/MealTicketWidget.dart';
import '../meal_ticket_provider.dart';

class SeeTickets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('See Tickets')),
      body: Consumer<MealTicketProvider>(
        builder: (context, mealTicketProvider, child) {
          if (mealTicketProvider.mealTickets.isEmpty) {
            return Center(child: Text('No meal tickets available.'));
          }
          return ListView.builder(
            itemCount: mealTicketProvider.mealTickets.length,
            itemBuilder: (context, index) {
              final ticket = mealTicketProvider.mealTickets[index];
              return _MealTicketCard(ticket: ticket);
            },
          );
        },
      ),
    );
  }
}

class _MealTicketCard extends StatefulWidget {
  final MealTicket ticket;

  _MealTicketCard({required this.ticket});

  @override
  __MealTicketCardState createState() => __MealTicketCardState();
}

class __MealTicketCardState extends State<_MealTicketCard> {
  @override
  Widget build(BuildContext context) {
    return MealTicketWidget(
      mealName: widget.ticket.title,
      mealDescription: widget.ticket.description,
      issuedBy: "Supervisor",
      ticketCode: widget.ticket.ticketCode,
      expiryTime: widget.ticket.expiryTime,
    );
  }
}
