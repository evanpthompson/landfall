import 'package:test/test.dart';
import 'package:landfall_shared/landfall_shared.dart';

void main() {
  group('LicenseTier', () {
    test('free has 7 day history retention', () {
      expect(LicenseTier.free.historyRetentionDays, equals(7));
    });

    test('pro has 90 day history retention', () {
      expect(LicenseTier.pro.historyRetentionDays, equals(90));
    });

    test('foundingMember has 365 day history retention', () {
      expect(LicenseTier.foundingMember.historyRetentionDays, equals(365));
    });

    test('free is not pro', () {
      expect(LicenseTier.free.isPro, isFalse);
    });

    test('pro is pro', () {
      expect(LicenseTier.pro.isPro, isTrue);
    });

    test('foundingMember is pro', () {
      expect(LicenseTier.foundingMember.isPro, isTrue);
    });

    test('free has 500 daily API limit', () {
      expect(LicenseTier.free.dailyApiLimit, equals(500));
    });

    test('pro has unlimited daily API limit (0 = no cap)', () {
      expect(LicenseTier.pro.dailyApiLimit, equals(0));
    });

    test('foundingMember has unlimited daily API limit', () {
      expect(LicenseTier.foundingMember.dailyApiLimit, equals(0));
    });

    test('displayName values are non-empty', () {
      for (final tier in LicenseTier.values) {
        expect(tier.displayName, isNotEmpty);
      }
    });

    test('fromString round-trips all tiers', () {
      for (final tier in LicenseTier.values) {
        expect(LicenseTier.fromString(tier.name), equals(tier));
      }
    });

    test('fromString unknown value returns free', () {
      expect(LicenseTier.fromString('unknown_tier'), equals(LicenseTier.free));
    });
  });

  group('LicenseStatus', () {
    test('free status has no activatedAt or maskedKey', () {
      const status = LicenseStatus(tier: LicenseTier.free);
      expect(status.tier, equals(LicenseTier.free));
      expect(status.isPro, isFalse);
      expect(status.activatedAt, isNull);
      expect(status.maskedKey, isNull);
    });

    test('pro status reports isPro true', () {
      final status = LicenseStatus(
        tier: LicenseTier.pro,
        activatedAt: DateTime.utc(2026, 4, 26),
        maskedKey: 'LF-PRO-****-1234',
      );
      expect(status.isPro, isTrue);
      expect(status.activatedAt, isNotNull);
      expect(status.maskedKey, equals('LF-PRO-****-1234'));
    });

    test('foundingMember status reports isPro true', () {
      final status = LicenseStatus(
        tier: LicenseTier.foundingMember,
        activatedAt: DateTime.utc(2026, 4, 26),
      );
      expect(status.isPro, isTrue);
    });
  });

  group('IntegrationPackInfo', () {
    test('owned pack reports isOwned true', () {
      const pack = IntegrationPackInfo(
        packId: 'sports_scores',
        name: 'Sports Scores',
        description: 'Live game scores and ticker updates.',
        version: '1.0.0',
        priceUsd: 5.0,
        authorName: 'Landfall',
        isOwned: true,
      );
      expect(pack.isOwned, isTrue);
      expect(pack.packId, equals('sports_scores'));
      expect(pack.name, equals('Sports Scores'));
    });

    test('unowned pack reports isOwned false', () {
      const pack = IntegrationPackInfo(
        packId: 'rss_headlines',
        name: 'RSS Headlines',
        description: 'Rotating news headlines from any RSS feed.',
        version: '1.0.0',
        priceUsd: 5.0,
        authorName: 'Landfall',
        isOwned: false,
      );
      expect(pack.isOwned, isFalse);
    });

    test('copyWith preserves all fields when nothing changes', () {
      const pack = IntegrationPackInfo(
        packId: 'countdown',
        name: 'Countdown Timers',
        description: 'Countdown to any date.',
        version: '1.0.0',
        priceUsd: 5.0,
        authorName: 'Landfall',
        isOwned: false,
      );
      final copy = pack.copyWith();
      expect(copy.packId, equals(pack.packId));
      expect(copy.isOwned, equals(pack.isOwned));
    });

    test('copyWith can mark pack as owned', () {
      const pack = IntegrationPackInfo(
        packId: 'countdown',
        name: 'Countdown Timers',
        description: 'Countdown to any date.',
        version: '1.0.0',
        priceUsd: 5.0,
        authorName: 'Landfall',
        isOwned: false,
      );
      final owned = pack.copyWith(isOwned: true);
      expect(owned.isOwned, isTrue);
      expect(owned.packId, equals('countdown'));
    });
  });
}
