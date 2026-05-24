import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DriverMapPreview extends StatefulWidget {
  const DriverMapPreview({Key? key}) : super(key: key);

  @override
  State<DriverMapPreview> createState() => _DriverMapPreviewState();
}

class _DriverMapPreviewState extends State<DriverMapPreview> {
  GoogleMapController? mapController;
  Position? currentPosition;
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // 1. التأكد من تشغيل الـ GPS في الهاتف
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMessage = 'الرجاء تفعيل خدمة الموقع (GPS) في هاتفك.';
          isLoading = false;
        });
        return;
      }

      // 2. طلب صلاحية الوصول للموقع من السائق
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = 'تم رفض صلاحية الموقع.';
            isLoading = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage = 'صلاحية الموقع مرفوضة بشكل دائم من إعدادات الهاتف.';
          isLoading = false;
        });
        return;
      } 

      // 3. جلب الإحداثيات الحالية
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = position;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ أثناء جلب الموقع: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250, // ارتفاع مربع الخريطة
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center))
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                      zoom: 15.0,
                    ),
                    myLocationEnabled: true, // إظهار النقطة الزرقاء
                    myLocationButtonEnabled: true, // زر العودة لموقعي
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                  ),
      ),
    );
  }
}