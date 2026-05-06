import 'package:flutter/material.dart';

class BusMapView extends StatelessWidget {
  const BusMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 100, color: Colors.blue),
          Text('خريطة الباصات المباشرة', style: TextStyle(fontSize: 20)),
          Text('ستظهر الخريطة هنا في اليوم 8 حسب الخطة', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}