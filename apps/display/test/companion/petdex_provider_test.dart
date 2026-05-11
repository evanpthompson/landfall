import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/companion/provider/petdex_provider.dart';
import 'package:display/src/features/companion/provider/sprite_frame_spec.dart';

void main() {
  group('PetdexProvider', () {
    late PetdexProvider provider;

    setUp(() => provider = PetdexProvider());

    test('providerId is petdex', () {
      expect(provider.providerId, 'petdex');
    });

    test('frameWidth and frameHeight match petdex grid spec', () {
      expect(provider.frameWidth, 192);
      expect(provider.frameHeight, 208);
    });

    test('specFor returns correct row/frameCount for idle', () {
      final spec = provider.specFor(CompanionAnimationState.idle);
      expect(spec, isNotNull);
      expect(spec!.row, 0);
      expect(spec.frameCount, 6);
      expect(spec.fps, 8);
      expect(spec.loops, isTrue);
    });

    test('specFor returns correct row for play (running-right)', () {
      final spec = provider.specFor(CompanionAnimationState.play);
      expect(spec!.row, 1);
      expect(spec.frameCount, 8);
    });

    test('specFor returns correct row for playLeft (running-left)', () {
      final spec = provider.specFor(CompanionAnimationState.playLeft);
      expect(spec!.row, 2);
    });

    test('specFor returns correct row for pet (waving)', () {
      final spec = provider.specFor(CompanionAnimationState.pet);
      expect(spec!.row, 3);
      expect(spec.loops, isFalse);
    });

    test('specFor returns correct row for reactCelebratory (jumping)', () {
      final spec = provider.specFor(CompanionAnimationState.reactCelebratory);
      expect(spec!.row, 4);
    });

    test('specFor returns correct row for reactUrgent (failed)', () {
      final spec = provider.specFor(CompanionAnimationState.reactUrgent);
      expect(spec!.row, 5);
    });

    test('specFor returns correct row for idleCalm (waiting)', () {
      final spec = provider.specFor(CompanionAnimationState.idleCalm);
      expect(spec!.row, 6);
    });

    test('specFor returns correct row for playSprint (running)', () {
      final spec = provider.specFor(CompanionAnimationState.playSprint);
      expect(spec!.row, 7);
    });

    test('specFor returns correct row for lookAtViewer (review)', () {
      final spec = provider.specFor(CompanionAnimationState.lookAtViewer);
      expect(spec!.row, 8);
    });

    test('specFor returns null for states with no petdex row', () {
      expect(provider.specFor(CompanionAnimationState.reactWeatherRain), isNull);
      expect(provider.specFor(CompanionAnimationState.reactWeatherSun), isNull);
      expect(provider.specFor(CompanionAnimationState.reactNight), isNull);
      expect(provider.specFor(CompanionAnimationState.evolve), isNull);
      expect(provider.specFor(CompanionAnimationState.feed), isNull);
    });

    test('resolve falls back to idle for unsupported states', () {
      expect(
        provider.resolve(CompanionAnimationState.reactWeatherRain),
        CompanionAnimationState.idle,
      );
    });

    test('resolve returns state unchanged when supported', () {
      expect(
        provider.resolve(CompanionAnimationState.play),
        CompanionAnimationState.play,
      );
    });

    test('supportedStates contains all 9 petdex rows', () {
      expect(provider.supportedStates.length, 9);
    });

    test('all rows 0–8 are reachable via distinct states', () {
      final rows = provider.supportedStates
          .map((s) => provider.specFor(s)!.row)
          .toSet();
      expect(rows, containsAll([0, 1, 2, 3, 4, 5, 6, 7, 8]));
    });
  });

  group('SpriteFrameSpec', () {
    test('equality: same values are equal', () {
      const a = SpriteFrameSpec(row: 0, frameCount: 6, fps: 8);
      const b = SpriteFrameSpec(row: 0, frameCount: 6, fps: 8);
      expect(a, equals(b));
    });

    test('loops defaults to true', () {
      const spec = SpriteFrameSpec(row: 0, frameCount: 4, fps: 8);
      expect(spec.loops, isTrue);
    });
  });
}
