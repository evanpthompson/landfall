import 'package:landfall_shared/landfall_shared.dart';
import 'package:test/test.dart';

void main() {
  group('ProfileCardFilter.allows', () {
    test('all filter allows everything', () {
      const f = ProfileCardFilter.all;
      expect(f.allows(source: 'agent.homekit', mood: CardMood.normal), isTrue);
      expect(f.allows(source: 'system.clock', mood: CardMood.urgent), isTrue);
    });

    group('allowedMoods', () {
      const f = ProfileCardFilter(allowedMoods: [CardMood.celebratory, CardMood.success]);

      test('allows matching mood', () {
        expect(f.allows(source: 'agent.x', mood: CardMood.celebratory), isTrue);
        expect(f.allows(source: 'agent.x', mood: CardMood.success), isTrue);
      });

      test('blocks non-matching mood', () {
        expect(f.allows(source: 'agent.x', mood: CardMood.urgent), isFalse);
        expect(f.allows(source: 'agent.x', mood: CardMood.normal), isFalse);
        expect(f.allows(source: 'agent.x', mood: CardMood.muted), isFalse);
      });
    });

    group('allowedSources prefix matching', () {
      const f = ProfileCardFilter(allowedSources: ['agent.homekit', 'system.clock']);

      test('allows exact source match', () {
        expect(f.allows(source: 'agent.homekit', mood: CardMood.normal), isTrue);
        expect(f.allows(source: 'system.clock', mood: CardMood.normal), isTrue);
      });

      test('allows prefix match', () {
        expect(f.allows(source: 'agent.homekit.light', mood: CardMood.normal), isTrue);
      });

      test('blocks non-matching source', () {
        expect(f.allows(source: 'agent.other', mood: CardMood.normal), isFalse);
        expect(f.allows(source: 'system.weather', mood: CardMood.normal), isFalse);
      });
    });

    group('combined mood + source filter', () {
      const f = ProfileCardFilter(
        allowedMoods: [CardMood.celebratory],
        allowedSources: ['agent.party'],
      );

      test('allows when both match', () {
        expect(f.allows(source: 'agent.party', mood: CardMood.celebratory), isTrue);
      });

      test('blocks wrong mood even if source matches', () {
        expect(f.allows(source: 'agent.party', mood: CardMood.normal), isFalse);
      });

      test('blocks wrong source even if mood matches', () {
        expect(f.allows(source: 'agent.other', mood: CardMood.celebratory), isFalse);
      });
    });
  });

  group('ProfileCardFilter JSON round-trip', () {
    test('all filter round-trips to empty map', () {
      const f = ProfileCardFilter.all;
      expect(f.toJson(), isEmpty);
      expect(ProfileCardFilter.fromJson(f.toJson()), equals(f));
    });

    test('fully specified filter survives round-trip', () {
      const f = ProfileCardFilter(
        allowedMoods: [CardMood.urgent, CardMood.celebratory],
        allowedSources: ['agent.homekit', 'agent.calendar'],
        maxCards: 5,
      );
      expect(ProfileCardFilter.fromJson(f.toJson()), equals(f));
    });

    test('maxCards only round-trips', () {
      const f = ProfileCardFilter(maxCards: 3);
      final decoded = ProfileCardFilter.fromJson(f.toJson());
      expect(decoded.maxCards, 3);
      expect(decoded.allowedMoods, isNull);
      expect(decoded.allowedSources, isNull);
    });
  });

  group('ProfileCardFilter equality', () {
    test('two all filters are equal', () {
      expect(ProfileCardFilter.all, equals(const ProfileCardFilter()));
    });

    test('different maxCards are not equal', () {
      expect(
        const ProfileCardFilter(maxCards: 3),
        isNot(equals(const ProfileCardFilter(maxCards: 5))),
      );
    });
  });
}
