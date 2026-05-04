import 'package:flutter/material.dart';

class MyReservationsView extends StatelessWidget {
  const MyReservationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_added, size: 100, color: Colors.green),
          Text('قائمة حجوزاتي', style: TextStyle(fontSize: 20)),
          Text('سيتم ربطها بجدول Reservations في اليوم 6', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}