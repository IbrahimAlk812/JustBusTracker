import 'package:flutter/material.dart';
// استدعاء ملف البطاقة اللي انت عملته
import 'package:just_bus_tracker/screens/driver/bus_info_card.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  
  void startTrip() {
    print("Trip started");
  }

  void endTrip() {
    print("Trip ended");
  }

  void reportEmergency() {
    print("Emergency reported!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // استدعاء البطاقة من الملف الثاني
              const BusInfoCard(),
              
              const SizedBox(height: 50),
              
              // زر بدء الرحلة
              ElevatedButton(
                onPressed: startTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(250, 80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Start Trip', style: TextStyle(fontSize: 24, color: Colors.white)),
              ),
              const SizedBox(height: 25),
              
              // زر إنهاء الرحلة
              ElevatedButton(
                onPressed: endTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(250, 80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('End Trip', style: TextStyle(fontSize: 24, color: Colors.white)),
              ),
              const SizedBox(height: 60), 
              
              // زر الطوارئ
              ElevatedButton(
                onPressed: reportEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(250, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Report Emergency', style: TextStyle(fontSize: 20, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}