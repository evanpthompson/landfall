import 'package:test/test.dart';
import 'package:landfall_shared/landfall_shared.dart';

void main() {
  group('PhotoSource JSON round-trip', () {
    test('PhotoSourceServerpod serialises and deserialises', () {
      const source = PhotoSourceServerpod();
      final json = source.toJson();
      expect(PhotoSource.fromJson(json), equals(source));
    });

    test('PhotoSourceLocalDirectory serialises and deserialises', () {
      const source = PhotoSourceLocalDirectory(path: '/home/pi/photos');
      final json = source.toJson();
      final result = PhotoSource.fromJson(json);
      expect(result, equals(source));
      expect((result as PhotoSourceLocalDirectory).path, equals('/home/pi/photos'));
    });

    test('PhotoSourceNetwork serialises and deserialises', () {
      const source = PhotoSourceNetwork(
        urls: ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
      );
      final json = source.toJson();
      final result = PhotoSource.fromJson(json);
      expect(result, equals(source));
      expect((result as PhotoSourceNetwork).urls, equals(source.urls));
    });

    test('PhotoSourceS3 serialises and deserialises', () {
      const source = PhotoSourceS3(
        bucket: 'my-bucket',
        region: 'us-east-1',
        prefix: 'photos/',
        accessKey: 'AKID',
        secretKey: 'secret',
      );
      final json = source.toJson();
      final result = PhotoSource.fromJson(json);
      expect(result, equals(source));
      final s3 = result as PhotoSourceS3;
      expect(s3.bucket, equals('my-bucket'));
      expect(s3.region, equals('us-east-1'));
      expect(s3.prefix, equals('photos/'));
      expect(s3.accessKey, equals('AKID'));
      expect(s3.secretKey, equals('secret'));
    });

    test('PhotoSourceS3 optional credentials default to null', () {
      const source = PhotoSourceS3(
        bucket: 'public-bucket',
        region: 'eu-west-1',
        prefix: '',
      );
      final json = source.toJson();
      final result = PhotoSource.fromJson(json) as PhotoSourceS3;
      expect(result.accessKey, isNull);
      expect(result.secretKey, isNull);
    });

    test('fromJson throws on unknown type', () {
      expect(
        () => PhotoSource.fromJson({'type': 'unknown'}),
        throwsArgumentError,
      );
    });
  });
}
