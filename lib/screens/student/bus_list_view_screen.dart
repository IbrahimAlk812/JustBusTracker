import 'package:flutter/material.dart';

class BusListViewScreen extends StatelessWidget {
  const BusListViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> busData = [
      {
        'id': '005',
        'to': 'مجمع عمان',
        'price': '1.15',
        'time': '08:30 AM',
        'seats': 5,
      },
      {
        'id': '004',
        'to': 'مجمع الزرقاء',
        'price': '0.65',
        'time': '09:15 AM',
        'seats': 12,
      },
      {
        'id': '001',
        'to': 'الرمثا',
        'price': '0.35',
        'time': '10:00 AM',
        'seats': 0,
      }, // باص ممتلئ
      {
        'id': '002',
        'to': 'مجمع عمان',
        'price': '1.15',
        'time': '11:30 AM',
        'seats': 8,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F7FA,
      ), // خلفية رمادية فاتحة جداً مريحة للعين
      appBar: AppBar(
        title: const Text(
          'الرحلات المتاحة',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: busData.length,
        itemBuilder: (context, index) {
          final bus = busData[index];
          bool isFull = bus['seats'] == 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  // الجزء العلوي: معلومات الباص
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: Color(0xFF1A237E),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'باص #${bus['id']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                bus['to'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263238),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${bus['price']} JOD',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              'ذهاب فقط',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  // الجزء السفلي: الوقت والمقاعد والزر
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              bus['time'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.event_seat_rounded,
                              size: 18,
                              color: isFull ? Colors.red : Colors.blueGrey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isFull ? 'ممتلئ' : '${bus['seats']} مقاعد متاحة',
                              style: TextStyle(
                                color: isFull ? Colors.red : Colors.blueGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: isFull ? null : () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('احجز الآن'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
