import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// =============================================================================
// 🚀 1. EXTRA SERVICE MODEL
// =============================================================================
class ExtraService {
  final String name;
  final int count;

  ExtraService({required this.name, required this.count});

  factory ExtraService.fromJson(Map<String, dynamic> json) {
    return ExtraService(
      name: json['name']?.toString() ?? "Unknown Service",
      count: json['count'] != null ? int.tryParse(json['count'].toString()) ?? 1 : 1,
    );
  }
}

// =============================================================================
// 🚀 2. PATIENT MODEL (ଏହି ମଡେଲ୍ ନଥିବାରୁ ଏରର୍ ଆସୁଥିଲା)
// =============================================================================
class PatientInfo {
  final String name;
  final String phone;
  final String age;
  final String gender;

  PatientInfo({
    required this.name, 
    required this.phone, 
    required this.age, 
    required this.gender
  });

  factory PatientInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PatientInfo(name: "Unknown", phone: "-", age: "-", gender: "-");
    }
    return PatientInfo(
      name: json['name']?.toString() ?? "Unknown",
      phone: json['phone']?.toString() ?? "-",
      age: json['age']?.toString() ?? "-",
      gender: json['gender']?.toString() ?? "-",
    );
  }
}

// =============================================================================
// 🚀 3. MAIN APPOINTMENT MODEL
// =============================================================================
class Appointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorImage;
  final String doctorPhone;
  final String clinicName;
  final String clinicAddress;
  final double? clinicLat; 
  final double? clinicLng; 
  final String specialty;
  final DateTime dateTime;
  final String startTime; 
  final String endTime;   
  final String status; 
  final String type;
  final String clinicPhone;
  final String slotNumber;
  final double totalCost;
  final String paymentMethod;
  
  // 🚀 Patient ଏବଂ Extra Services ଏଠାରେ ଯୋଡାଗଲା
  final PatientInfo patient;
  final List<ExtraService> extraServices;
  final String bookedBy; 

  Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
    required this.doctorPhone,
    required this.clinicName,
    required this.clinicAddress,
    this.clinicLat,
    this.clinicLng,
    required this.specialty,
    required this.dateTime,
    required this.startTime,
    required this.endTime, 
    required this.status,
    required this.type,
    this.clinicPhone = "",
    this.slotNumber = "N/A",
    this.totalCost = 0.0,
    this.paymentMethod = "Pay at Clinic",
    required this.patient, // 👈 Required
    required this.extraServices, // 👈 Required
    this.bookedBy = "Self",
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor_id'] is Map ? json['doctor_id'] : {};
    final clinic = json['clinic_id'] is Map ? json['clinic_id'] : {};
    final user = json['user_id'] is Map ? json['user_id'] : {};

    // Doctor & Clinic Basic Info
    String name = doctor['name'] ?? "Unknown Doctor";
    String docPhone = doctor['phone']?.toString() ?? "";
    String cName = clinic['name'] ?? "Hospital/Clinic Not Assigned";
    String cAddress = clinic['address'] ?? "Address not available";

    // Specialty / Departments
    String dept = "General Physician";
    if (doctor['departments'] != null && (doctor['departments'] as List).isNotEmpty) {
      final firstDept = doctor['departments'][0];
      dept = firstDept is Map ? (firstDept['department'] ?? firstDept['name'] ?? dept) : firstDept.toString();
    }

    // Doctor Profile Image
    String img = doctor['profile'] ?? "";
    if (img.isEmpty || img.contains("undefined") || img == "null") {
      img = "https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&size=128";
    }

    // DateTime Parsing
    DateTime parsedDateTime = DateTime.now();
    try {
      if (json['exact_schedule_time'] != null) {
        parsedDateTime = DateTime.parse(json['exact_schedule_time']).toLocal();
      } else {
        String dateStr = json['date'] ?? "";
        String timeStr = json['start'] ?? "09:00 AM";
        parsedDateTime = DateFormat("yyyy-MM-dd h:mm a").parse("$dateStr $timeStr");
      }
    } catch (e) {
      parsedDateTime = DateTime.tryParse(json['createdAt'] ?? "") ?? DateTime.now();
    }

    // Clinic Phone
    String phone = "";
    if (clinic['phone'] != null && (clinic['phone'] as List).isNotEmpty) {
      phone = clinic['phone'][0].toString();
    }

    // Slot Number
    String slot = "N/A";
    if (json['slot_number'] != null) {
      slot = json['slot_number'].toString();
    } else if (json['numeric_slot'] != null) {
      slot = json['numeric_slot'].toString();
    }

    // Parse Extra Services Array
    List<ExtraService> servicesList = [];
    if (json['extra_services'] != null && json['extra_services'] is List) {
      servicesList = (json['extra_services'] as List).map((e) => ExtraService.fromJson(e)).toList();
    }

    // Strict Status Parsing
    String parsedStatus = "pending";
    if (json['status'] != null && json['status'].toString().isNotEmpty) {
      parsedStatus = json['status'].toString().trim().toLowerCase();
    }

    return Appointment(
      id: json['_id']?.toString() ?? "",
      doctorId: doctor['_id']?.toString() ?? "",
      doctorName: name,
      doctorImage: img,
      doctorPhone: docPhone,
      clinicName: cName,
      clinicAddress: cAddress,
      clinicLat: clinic['lat'] != null ? double.tryParse(clinic['lat'].toString()) : null,
      clinicLng: clinic['lng'] != null ? double.tryParse(clinic['lng'].toString()) : null,
      specialty: dept.toUpperCase().replaceAll("-", " "),
      dateTime: parsedDateTime,
      startTime: json['start']?.toString() ?? "09:00 AM", 
      endTime: json['end']?.toString() ?? "01:00 PM",     
      status: parsedStatus, 
      type: json['appointment_type']?.toString() ?? "consultation",
      clinicPhone: phone,
      slotNumber: slot,
      totalCost: double.tryParse(json['total_cost']?.toString() ?? "0") ?? 0.0,
      paymentMethod: json['payment_method']?.toString().replaceAll("_", " ") ?? "Pay at Clinic",
      
      // 🚀 Patient Parsing (ଏହିଠାରେ JSON ରୁ ପେସେଣ୍ଟ ଡାଟା ପଢାଯାଉଛି)
      patient: PatientInfo.fromJson(json['patient']),
      extraServices: servicesList,
      bookedBy: user['name']?.toString() ?? "Self",
    );
  }
}

// =============================================================================
// 🚀 4. APPOINTMENT LOGIC EXTENSION
// =============================================================================
extension AppointmentLogic on Appointment {
  bool get isCheckInAllowed {
    if (status != "pending" && status != "confirmed") return false;
    final now = DateTime.now();
    final isToday = now.year == dateTime.year && now.month == dateTime.month && now.day == dateTime.day;
    final diffInMins = dateTime.difference(now).inMinutes;
    return isToday && diffInMins <= 120 && diffInMins >= -120;
  }

  String get checkInDisabledMessage {
    if (isCheckInAllowed) return "I have reached the Clinic";
    final now = DateTime.now();
    final isToday = now.year == dateTime.year && now.month == dateTime.month && now.day == dateTime.day;
    return isToday ? "Opens 2 hours before appointment" : "Available on ${DateFormat('MMM dd').format(dateTime)}";
  }

  bool get isFinished {
    return ["cancelled", "completed", "no_show"].contains(status);
  }

  Color get statusColor {
    switch (status) {
      case 'confirmed': return Colors.blue.shade600; 
      case 'checked_in': return const Color(0xFF16A34A); 
      case 'pending': return const Color(0xFFF59E0B); 
      case 'cancelled':
      case 'no_show': return const Color(0xFFEF4444); 
      case 'completed': return const Color(0xFF2563EB); 
      default: return Colors.grey;
    }
  }

  String get formattedDateTime {
    return DateFormat('MMM dd, yyyy • h:mm a').format(dateTime);
  }

  String get formattedTimeRange {
    String datePart = DateFormat('MMM dd, yyyy').format(dateTime);
    return "$datePart • $startTime - $endTime"; 
  }
}