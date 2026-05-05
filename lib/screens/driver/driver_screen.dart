import 'package:flutter/material.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final String busNumber = "B-174"; 

  void startTrip() {
    print("Trip started for bus $busNumber");
  }

  void endTrip() {
    print("Trip ended for bus $busNumber");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bus Number: $busNumber',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: startTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(250, 80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Start Trip',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: endTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(250, 80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'End Trip',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}