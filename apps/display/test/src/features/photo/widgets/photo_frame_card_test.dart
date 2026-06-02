import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/auth/cubit/auth_cubit.dart';
import 'package:display/src/features/photo/cubit/photo_cubit.dart';
import 'package:display/src/features/photo/widgets/photo_frame_card.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {
  @override
  String? get currentAccessToken => null;
}

PhotoEntity _photo(String url, {int id = 1}) => PhotoEntity(
      id: id,
      filename: 'p$id.jpg',
      mimeType: 'image/jpeg',
      fetchedAt: DateTime(2026, 5, 1),
      imageUrl: url,
    );

Widget _wrapWithState(
  PhotoState state, {
  double width = 800,
  double height = 600,
}) {
  return _harness(
    cubit: _FakePhotoCubit(state),
    width: width,
    height: height,
  );
}

Widget _harness({
  required PhotoCubit cubit,
  void Function(ImageProvider provider)? evictProvider,
  double width = 800,
  double height = 600,
}) {
  final authCubit = MockAuthCubit();
  when(() => authCubit.state).thenReturn(const AuthUnauthenticated());
  return MaterialApp(
    theme: LandfallTheme.dark,
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<PhotoCubit>.value(value: cubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
          ],
          child: PhotoFrameCard(evictProvider: evictProvider),
        ),
      ),
    ),
  );
}

class _FakePhotoCubit extends PhotoCubit {
  _FakePhotoCubit(PhotoState initial) : super(_NullRepo(), _NullSettingsRepo()) {
    emit(initial);
  }
}

class _NullRepo implements PhotoRepository {
  @override
  Future<List<PhotoEntity>> getPhotos() async => [];
}

class _NullSettingsRepo implements DisplaySettingsRepository {
  @override
  Future<DisplaySettings> getSettings() async => const DisplaySettings();

  @override
  Future<void> saveSettings(DisplaySettings settings) async {}
}

void main() {
  group('PhotoFrameCard states', () {
    testWidgets('shows placeholder when loading', (tester) async {
      await tester.pumpWidget(_wrapWithState(const PhotoLoading()));
      expect(find.byType(PhotoFrameCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows "No photos configured" when empty', (tester) async {
      await tester.pumpWidget(_wrapWithState(const PhotoEmpty()));
      expect(find.text('No photos configured'), findsOneWidget);
    });

    testWidgets('shows "Photos unavailable" on error', (tester) async {
      await tester.pumpWidget(_wrapWithState(const PhotoError('timeout')));
      expect(find.text('Photos unavailable'), findsOneWidget);
    });

    // BUG-05: card must not overflow at small slot sizes.
    testWidgets('does not overflow in a 200x200 slot (loading)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithState(const PhotoLoading(), width: 200, height: 200),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow in a 200x200 slot (empty)', (tester) async {
      await tester.pumpWidget(
        _wrapWithState(const PhotoEmpty(), width: 200, height: 200),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('photoDecodeEdge', () {
    test('caps the decoded edge at kMaxPhotoDecodeEdge for large slots', () {
      expect(photoDecodeEdge(const Size(5000, 4000), 2.0), kMaxPhotoDecodeEdge);
    });

    test('scales with slot size and device pixel ratio below the cap', () {
      // longest logical edge 400 × dpr 2 = 800 device px (plus zoom headroom).
      final edge = photoDecodeEdge(const Size(400, 300), 2.0);
      expect(edge, greaterThanOrEqualTo(800));
      expect(edge, lessThanOrEqualTo(kMaxPhotoDecodeEdge));
    });

    test('falls back to the cap when constraints are unbounded', () {
      expect(
        photoDecodeEdge(const Size(double.infinity, double.infinity), 1.0),
        kMaxPhotoDecodeEdge,
      );
    });

    test('never returns a non-positive edge for a zero-size slot', () {
      expect(photoDecodeEdge(Size.zero, 1.0), greaterThan(0));
    });
  });

  group('photoProvider', () {
    test('wraps a file:// url in a fitted, non-upscaling ResizeImage', () {
      final provider = photoProvider(_photo('file:///home/pi/a.jpg'), 1024);
      expect(provider, isA<ResizeImage>());
      final resize = provider as ResizeImage;
      expect(resize.imageProvider, isA<FileImage>());
      expect(resize.width, 1024);
      expect(resize.height, 1024);
      expect(resize.policy, ResizeImagePolicy.fit);
      expect(resize.allowUpscaling, isFalse);
    });

    test('wraps an http url in a fitted ResizeImage(NetworkImage)', () {
      final provider = photoProvider(_photo('https://x.test/a.jpg'), 800);
      expect(provider, isA<ResizeImage>());
      final resize = provider as ResizeImage;
      expect(resize.imageProvider, isA<NetworkImage>());
      expect((resize.imageProvider as NetworkImage).url, 'https://x.test/a.jpg');
      expect(resize.width, 800);
    });
  });

  group('PhotoFrameCard rendering decodes at bounded resolution', () {
    testWidgets('file:// image is wrapped in a bounded ResizeImage', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithState(
          PhotoLoaded(
            photos: [_photo('file:///home/pi/local.jpg')],
            currentIndex: 0,
          ),
        ),
      );
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images, isNotEmpty);
      final resized = images
          .map((i) => i.image)
          .whereType<ResizeImage>()
          .toList();
      expect(resized, isNotEmpty);
      expect(resized.first.imageProvider, isA<FileImage>());
      expect(resized.first.width, isNotNull);
      expect(resized.first.width!, inInclusiveRange(1, kMaxPhotoDecodeEdge));
    });

    testWidgets('http image is wrapped in a bounded ResizeImage(NetworkImage)',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithState(
          PhotoLoaded(
            photos: [_photo('https://example.com/remote.jpg')],
            currentIndex: 0,
          ),
        ),
      );
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      final resized = images
          .map((i) => i.image)
          .whereType<ResizeImage>()
          .toList();
      expect(resized, isNotEmpty);
      final inner = resized.first.imageProvider;
      expect(inner, isA<NetworkImage>());
      expect((inner as NetworkImage).headers, isNull);
      expect(resized.first.width!, inInclusiveRange(1, kMaxPhotoDecodeEdge));
    });
  });

  group('PhotoFrameCard evicts off-screen photos', () {
    testWidgets('evicts the outgoing photo after the transition completes', (
      tester,
    ) async {
      // file:// URLs avoid a live NetworkImage HTTP stream, which interferes
      // with pump(duration) in widget tests. Eviction is provider-agnostic
      // (photoProvider handles both schemes — covered above), so this proves
      // the behaviour without the network-stream flakiness.
      final evicted = <ImageProvider>[];
      final photoA = _photo('file:///tmp/landfall/a.jpg', id: 1);
      final photoB = _photo('file:///tmp/landfall/b.jpg', id: 2);
      final cubit = _FakePhotoCubit(
        PhotoLoaded(photos: [photoA, photoB], currentIndex: 0),
      );

      await tester.pumpWidget(_harness(cubit: cubit, evictProvider: evicted.add));
      await tester.pump();

      cubit.advance(); // photoB becomes current; photoA is now outgoing.
      await tester.pump(); // didUpdateWidget schedules the eviction.

      expect(evicted, isEmpty, reason: 'must not evict mid-transition');

      await tester.pump(const Duration(seconds: 3)); // past the eviction delay.

      expect(evicted, isNotEmpty);
      final resized = evicted.whereType<ResizeImage>().toList();
      expect(resized, isNotEmpty);
      expect(
        (resized.first.imageProvider as FileImage).file.path,
        '/tmp/landfall/a.jpg',
        reason: 'the photo that left the screen is the one evicted',
      );

      // Dispose the widget so pending timers do not outlive the test.
      await tester.pumpWidget(const SizedBox());
    });
  });
}
