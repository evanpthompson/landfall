import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/companion/companion_event_bus.dart';
import 'package:display/src/features/weather/cubit/weather_cubit.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

WeatherEntity _weather(String condition) => WeatherEntity(
      locationName: 'Test City',
      tempC: 20,
      feelsLikeC: 18,
      condition: condition,
      iconCode: '01d',
      humidity: 60,
      windSpeedMs: 3,
      fetchedAt: DateTime(2026, 5, 1),
    );

const _emptyForecast = <ForecastDayEntity>[];

void main() {
  late MockWeatherRepository repository;
  late CompanionEventBus bus;
  late List<CompanionTrigger> captured;

  setUp(() {
    repository = MockWeatherRepository();
    bus = CompanionEventBus();
    captured = [];
    bus.events.listen(captured.add);
    when(() => repository.getForecast())
        .thenAnswer((_) async => _emptyForecast);
  });

  tearDown(() => bus.dispose());

  group('rain conditions', () {
    for (final condition in ['Rain', 'Drizzle', 'heavy shower', 'Thunderstorm']) {
      test('condition "$condition" emits weatherChangedToRain', () async {
        when(() => repository.getCurrentWeather())
            .thenAnswer((_) async => _weather(condition));

        final cubit = WeatherCubit(repository, bus: bus);
        await cubit.loadWeather();

        expect(captured, contains(CompanionTrigger.weatherChangedToRain));
        await cubit.close();
      });
    }
  });

  group('sun conditions', () {
    for (final condition in ['Clear', 'Sunny', 'Fair']) {
      test('condition "$condition" emits weatherChangedToSun', () async {
        when(() => repository.getCurrentWeather())
            .thenAnswer((_) async => _weather(condition));

        final cubit = WeatherCubit(repository, bus: bus);
        await cubit.loadWeather();

        expect(captured, contains(CompanionTrigger.weatherChangedToSun));
        await cubit.close();
      });
    }
  });

  test('neutral condition emits nothing', () async {
    when(() => repository.getCurrentWeather())
        .thenAnswer((_) async => _weather('Cloudy'));

    final cubit = WeatherCubit(repository, bus: bus);
    await cubit.loadWeather();

    expect(captured, isEmpty);
    await cubit.close();
  });

  test('same condition on second load emits no trigger', () async {
    when(() => repository.getCurrentWeather())
        .thenAnswer((_) async => _weather('Rain'));

    final cubit = WeatherCubit(repository, bus: bus);
    await cubit.loadWeather();
    captured.clear();
    await cubit.loadWeather();

    expect(captured, isEmpty);
    await cubit.close();
  });

  test('changed condition emits trigger', () async {
    when(() => repository.getCurrentWeather())
        .thenAnswer((_) async => _weather('Clear'));
    final cubit = WeatherCubit(repository, bus: bus);
    await cubit.loadWeather();
    captured.clear();

    when(() => repository.getCurrentWeather())
        .thenAnswer((_) async => _weather('Rain'));
    await cubit.loadWeather();

    expect(captured, contains(CompanionTrigger.weatherChangedToRain));
    await cubit.close();
  });

  test('no bus — loadWeather completes without error', () async {
    when(() => repository.getCurrentWeather())
        .thenAnswer((_) async => _weather('Rain'));

    final cubit = WeatherCubit(repository);
    await expectLater(cubit.loadWeather(), completes);
    await cubit.close();
  });
}
