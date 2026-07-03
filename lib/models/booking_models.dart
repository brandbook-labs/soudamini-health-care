// lib/models/booking_models.dart

class ServiceItem {
  final String name;
  final double price;
  final String value; // unique slug/id
  bool isSelected;

  ServiceItem({
    required this.name,
    required this.price,
    required this.value,
    this.isSelected = false,
  });
}

class BookingSelection {
  final String date; // e.g. "Mon, 20 Jan"
  final String slotTime; // e.g. "10:00 AM"
  final String slotId; // e.g. "10:00"

  BookingSelection({
    required this.date,
    required this.slotTime,
    required this.slotId,
  });
}
