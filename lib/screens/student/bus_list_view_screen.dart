import 'package:flutter/material.dart';
import 'package:just_bus_tracker/services/database_service.dart'; // Import your service

class BusListViewScreen extends StatefulWidget {
  const BusListViewScreen({super.key});

  @override
  State<BusListViewScreen> createState() => _BusListViewScreenState();
}

class _BusListViewScreenState extends State<BusListViewScreen> {
  final DatabaseService _dbService = DatabaseService();

  // Helper to show modern status messages
  void _showNotification(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Handle Booking logic
  Future<void> _processBooking(String busId) async {
    final status = await _dbService.bookSeat(busId);

    if (status == 'success') {
      _showNotification('Seat booked successfully!', true);
      setState(() {}); // Refresh UI to update capacity
    } else {
      _showNotification('Booking failed: Bus is full.', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Available Buses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            ),
          ),
        ),
      ),
      // 1. Fetching all buses from Database
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbService.getBuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No buses available right now.'));
          }

          final buses = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];
              final busId = bus['id'].toString();
              final destination = bus['to'] ?? 'Unknown';

              // 2. Fetching real-time capacity for each bus
              return FutureBuilder<int>(
                future: _dbService.getAvailableCapacity(busId, destination),
                builder: (context, capSnapshot) {
                  final capacity = capSnapshot.data ?? 0;
                  final bool isFull = capacity <= 0;

                  return _buildBusCard(
                    busId,
                    destination,
                    bus['price'],
                    capacity,
                    isFull,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBusCard(
    String id,
    String to,
    dynamic price,
    int capacity,
    bool isFull,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.directions_bus,
                  color: Color(0xFF1A237E),
                  size: 30,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus #$id',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        to,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$price JOD',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_seat,
                      size: 18,
                      color: isFull ? Colors.red : Colors.blueGrey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isFull ? 'Full' : '$capacity seats left',
                      style: TextStyle(
                        color: isFull ? Colors.red : Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: isFull ? null : () => _processBooking(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
