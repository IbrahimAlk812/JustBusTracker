import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_pin, size: 100, color: Colors.orange),
          Text('الملف الشخصي للطالب', style: TextStyle(fontSize: 20)),
          Text('هنا تظهر بياناتك من جدول Profiles', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}