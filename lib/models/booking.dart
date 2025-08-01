class Booking {
  final String turfId;
  final String turfName;
  final String userId;
  final String name;
  final String phoneNumber;
  final String date;
  final String timeSlot;
  final double amount;
  final String status;
  final String createdAt;

  Booking(
      {required this.turfId,
      required this.turfName,
      required this.userId,
      required this.name,
      required this.phoneNumber,
      required this.date,
      required this.timeSlot,
      required this.amount,
      required this.status,
      required this.createdAt});
}
