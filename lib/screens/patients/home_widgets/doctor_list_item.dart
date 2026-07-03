import 'package:flutter/material.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/models/doctor_model.dart'; // For JivanDoctorCard

class DoctorListItem extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;

  const DoctorListItem({super.key, required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spaceSm),
      child: JivanDoctorCard(doctor: doctor, onTap: onTap, onBook: onTap),
    );
  }
}
