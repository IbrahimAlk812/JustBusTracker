
import 'package:flutter/material.dart';

class SupervisorBusTable extends StatelessWidget {
  const SupervisorBusTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المشرف - الباصات', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue[900],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "جدول المراقبة اليومي",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.blue[100]),
                      columns: const [
                        DataColumn(label: Text('رقم الباص')),
                        DataColumn(label: Text('اسم السائق')),
                        DataColumn(label: Text('الموقع الحالي')),
                        DataColumn(label: Text('الحالة')),
                      ],
                      rows: const [
                        DataRow(cells: [
                          DataCell(Text('101')),
                          DataCell(Text('أحمد الكردي')),
                          DataCell(Text('البوابة الشمالية')),
                          DataCell(Icon(Icons.directions_bus, color: Colors.green)),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('102')),
                          DataCell(Text('إبراهيم كساسبة')),
                          DataCell(Text('شارع الجامعة')),
                          DataCell(Icon(Icons.directions_bus, color: Colors.green)),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('103')),
                          DataCell(Text('محمد علي')),
                          DataCell(Text('مجمع عمان')),
                          DataCell(Icon(Icons.warning, color: Colors.orange)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
