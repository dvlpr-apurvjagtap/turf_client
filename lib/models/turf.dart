class Turf {
  final String id;
  final String name;
  final String description;
  final String location;
  final double rating;
  final List<String> sports;
  final String imageUrl;
  final double price;
  final List<String> amenities;
  final String phoneNumber;
  final String ownerId;

  Turf({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.rating,
    required this.sports,
    required this.imageUrl,
    required this.price,
    required this.amenities,
    required this.phoneNumber,
    required this.ownerId,
  });
}
