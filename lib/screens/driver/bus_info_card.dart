import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusInfoCard extends StatefulWidget {
  const BusInfoCard({Key? key}) : super(key: key);

  @override
  State<BusInfoCard> createState() => _BusInfoCardState();
}

class _BusInfoCardState extends State<BusInfoCard> {
  String busNumber = "Loading...";
  String routeName = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchBusAndRouteData();
  }

  Future<void> fetchBusAndRouteData() async {
    try {
      /* // هاض كود الربط الفعلي مع Supabase (عدل أسماء الجداول حسب اللي عندك)
      final response = await Supabase.instance.client
          .from('buses') // اسم الجدول
          .select('bus_number, route_name')
          .limit(1) // جلب باص السائق الحالي
          .single();
          
      setState(() {
        busNumber = response['bus_number'];
        routeName = response['route_name'];
      });
      */

      // قيم مؤقتة للفحص عشان ما يضرب معك المحاكي قبل ربط الجداول
      await Future.delayed(const Duration(seconds: 1)); // محاكاة وقت التحميل
      setState(() {
        busNumber = "B-174";
        routeName = "Irbid - JUST University";
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.blue.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
        child: Column(
          children: [
            Text(
              'Bus: $busNumber',
              // 1️⃣ التعديل هنا: إزالة const وتعديل اسم اللون إلى Colors.blue.shade900
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900, 
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Route: $routeName',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}