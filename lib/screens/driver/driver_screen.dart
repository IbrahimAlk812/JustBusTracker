import 'package:flutter/material.dart';
import 'package:just_bus_tracker/screens/driver/bus_info_card.dart';
// 1️⃣ استدعاء ملف الخريطة الجديد اللي عملناه
import 'package:just_bus_tracker/screens/driver/driver_map_preview.dart';

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
              // الكرت اللي بيعرض معلومات الباص والركاب
              const BusInfoCard(),
              
              const SizedBox(height: 20), // مسافة فاصلة
              
              // 2️⃣ الخريطة حطيناها هون! (تحت الكرت ومباشرة فوق الأزرار) 👇
              const DriverMapPreview(),
              
              const SizedBox(height: 30), // مسافة فاصلة قبل الأزرار
              
              // زر بدء الرحلة
              ElevatedButton(
                onPressed: startTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(250, 60), // صغرنا الزر شوي عشان يوسع مع الخريطة
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Start Trip', style: TextStyle(fontSize: 22, color: Colors.white)),
              ),
              const SizedBox(height: 15),
              
              // زر إنهاء الرحلة
              ElevatedButton(
                onPressed: endTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(250, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('End Trip', style: TextStyle(fontSize: 22, color: Colors.white)),
              ),
              const SizedBox(height: 25), 
              
              // زر الطوارئ
              ElevatedButton(
                onPressed: reportEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(250, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Report Emergency', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 20), // مسافة عشان ما يلزق بآخر الشاشة
            ],
          ),
        ),
      ),
    );
  }
}