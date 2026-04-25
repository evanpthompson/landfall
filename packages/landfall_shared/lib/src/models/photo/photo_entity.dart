/// A photo available for the slideshow, mapped from the server-side Photo row.
///
/// [imageUrl] is the fully-qualified URL to fetch image bytes — constructed
/// server-side from the Landfall internal photo ID. No provider-specific
/// identifiers are exposed here.
class PhotoEntity {
  const PhotoEntity({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.fetchedAt,
    required this.imageUrl,
  });

  final int id;
  final String filename;
  final String mimeType;
  final DateTime fetchedAt;

  /// Fully-qualified URL to the photo serve route, e.g.
  /// `http://localhost:8080/photos/42`.
  final String imageUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoEntity && id == other.id && imageUrl == other.imageUrl;

  @override
  int get hashCode => Object.hash(id, imageUrl);

  @override
  String toString() => 'PhotoEntity($id: $filename)';
}
