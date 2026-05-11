import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/companion/companion_event_bus.dart';
import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';

class MockProfileRepository extends Mock implements DashboardProfileRepository {}

ProfileInfo _profile(int id, String name, {bool active = false}) => ProfileInfo(
      id: id,
      name: name,
      slug: name.toLowerCase(),
      isActive: active,
      layout: DashboardLayout.weekdayLayout(),
      sortOrder: id,
    );

void main() {
  late MockProfileRepository repository;
  late CompanionEventBus bus;
  late List<CompanionTrigger> captured;

  setUp(() {
    repository = MockProfileRepository();
    bus = CompanionEventBus();
    captured = [];
    bus.events.listen(captured.add);
    registerFallbackValue(DashboardLayout.weekdayLayout());
  });

  tearDown(() => bus.dispose());

  test('activateProfile to Night emits nightProfileActivated', () async {
    final night = _profile(3, 'Night', active: true);
    when(() => repository.activateProfile(3))
        .thenAnswer((_) async => night);
    when(() => repository.listProfiles()).thenAnswer((_) async => [night]);

    final cubit = DashboardProfileCubit(repository, bus: bus);
    await cubit.activateProfile(3);

    expect(captured, contains(CompanionTrigger.nightProfileActivated));
    await cubit.close();
  });

  test('activateProfile to Weekday emits dayProfileActivated', () async {
    final weekday = _profile(1, 'Weekday', active: true);
    when(() => repository.activateProfile(1))
        .thenAnswer((_) async => weekday);
    when(() => repository.listProfiles()).thenAnswer((_) async => [weekday]);

    final cubit = DashboardProfileCubit(repository, bus: bus);
    await cubit.activateProfile(1);

    expect(captured, contains(CompanionTrigger.dayProfileActivated));
    await cubit.close();
  });

  test('activateProfile to Weekend emits dayProfileActivated', () async {
    final weekend = _profile(2, 'Weekend', active: true);
    when(() => repository.activateProfile(2))
        .thenAnswer((_) async => weekend);
    when(() => repository.listProfiles()).thenAnswer((_) async => [weekend]);

    final cubit = DashboardProfileCubit(repository, bus: bus);
    await cubit.activateProfile(2);

    expect(captured, contains(CompanionTrigger.dayProfileActivated));
    await cubit.close();
  });

  test('loadProfiles emits no trigger on initial load', () async {
    final weekday = _profile(1, 'Weekday', active: true);
    when(() => repository.listProfiles()).thenAnswer((_) async => [weekday]);

    final cubit = DashboardProfileCubit(repository, bus: bus);
    await cubit.loadProfiles();

    expect(captured, isEmpty);
    await cubit.close();
  });

  test('no bus — activateProfile completes without error', () async {
    final weekday = _profile(1, 'Weekday', active: true);
    when(() => repository.activateProfile(1))
        .thenAnswer((_) async => weekday);
    when(() => repository.listProfiles()).thenAnswer((_) async => [weekday]);

    final cubit = DashboardProfileCubit(repository);
    await expectLater(cubit.activateProfile(1), completes);
    await cubit.close();
  });
}
