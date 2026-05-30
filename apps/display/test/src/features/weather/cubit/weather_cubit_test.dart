import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';
import 'package:display/src/features/weather/cubit/weather_cubit.dart';
import 'package:display/src/features/weather/cubit/weather_state.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

WeatherEntity get _weather => WeatherEntity(
      locationName: 'Chicago',
      tempC: 22.0,
      feelsLikeC: 20.0,
      condition: 'Clear sky',
      iconCode: '01d',
      humidity: 55,
      windSpeedMs: 3.5,
      fetchedAt: DateTime(2026, 4, 19, 12, 0),
    );

List<ForecastDayEntity> get _forecast => [
      ForecastDayEntity(
        date: DateTime.utc(2026, 4, 19),
        minTempC: 14.0,
        maxTempC: 23.0,
        condition: 'Clear sky',
        iconCode: '01d',
      ),
      ForecastDayEntity(
        date: DateTime.utc(2026, 4, 20),
        minTempC: 12.0,
        maxTempC: 20.0,
        condition: 'Few clouds',
        iconCode: '02d',
      ),
    ];

void main() {
  late MockWeatherRepository repository;

  setUp(() {
    repository = MockWeatherRepository();
  });

  group('WeatherCubit', () {
    test('initial state is WeatherLoading', () {
      expect(WeatherCubit(repository).state, isA<WeatherLoading>());
    });

    group('loadWeather', () {
      blocTest<WeatherCubit, WeatherState>(
        'emits [WeatherLoading, WeatherLoaded] when both calls succeed',
        build: () {
          when(() => repository.getCurrentWeather())
              .thenAnswer((_) async => _weather);
          when(() => repository.getForecast())
              .thenAnswer((_) async => _forecast);
          return WeatherCubit(repository);
        },
        act: (cubit) => cubit.loadWeather(),
        expect: () => [
          isA<WeatherLoading>(),
          isA<WeatherLoaded>()
              .having((s) => s.current.locationName, 'locationName', 'Chicago')
              .having((s) => s.forecast.length, 'forecast.length', 2),
        ],
      );

      blocTest<WeatherCubit, WeatherState>(
        'emits [WeatherLoading, WeatherError] when current weather is null',
        build: () {
          when(() => repository.getCurrentWeather())
              .thenAnswer((_) async => null);
          when(() => repository.getForecast())
              .thenAnswer((_) async => _forecast);
          return WeatherCubit(repository);
        },
        act: (cubit) => cubit.loadWeather(),
        expect: () => [
          isA<WeatherLoading>(),
          isA<WeatherError>(),
        ],
      );

      blocTest<WeatherCubit, WeatherState>(
        'emits [WeatherLoading, WeatherError] when repository throws',
        build: () {
          when(() => repository.getCurrentWeather())
              .thenThrow(Exception('Connection refused'));
          when(() => repository.getForecast())
              .thenAnswer((_) async => []);
          return WeatherCubit(repository);
        },
        act: (cubit) => cubit.loadWeather(),
        expect: () => [
          isA<WeatherLoading>(),
          isA<WeatherError>(),
        ],
      );

      blocTest<WeatherCubit, WeatherState>(
        'emits WeatherLoaded with empty forecast when forecast is empty',
        build: () {
          when(() => repository.getCurrentWeather())
              .thenAnswer((_) async => _weather);
          when(() => repository.getForecast())
              .thenAnswer((_) async => []);
          return WeatherCubit(repository);
        },
        act: (cubit) => cubit.loadWeather(),
        expect: () => [
          isA<WeatherLoading>(),
          isA<WeatherLoaded>()
              .having((s) => s.forecast, 'forecast', isEmpty),
        ],
      );

      blocTest<WeatherCubit, WeatherState>(
        'does not emit WeatherLoading on background refresh when already loaded',
        build: () {
          when(() => repository.getCurrentWeather())
              .thenAnswer((_) async => _weather);
          when(() => repository.getForecast())
              .thenAnswer((_) async => _forecast);
          return WeatherCubit(repository);
        },
        act: (cubit) async {
          await cubit.loadWeather();
          await cubit.loadWeather();
        },
        expect: () => [
          isA<WeatherLoading>(),
          isA<WeatherLoaded>(),
          isA<WeatherLoaded>(), // second refresh: no WeatherLoading, data updates silently
        ],
      );

      blocTest<WeatherCubit, WeatherState>(
        'keeps stale data when background refresh returns null',
        build: () {
          when(() => repository.getCurrentWeather())
              .thenAnswer((_) async => _weather);
          when(() => repository.getForecast())
              .thenAnswer((_) async => _forecast);
          return WeatherCubit(repository);
        },
        act: (cubit) async {
          await cubit.loadWeather();
          when(() => repository.getCurrentWeather())
              .thenAnswer((_) async => null);
          await cubit.loadWeather();
        },
        expect: () => [
          isA<WeatherLoading>(),
          isA<WeatherLoaded>(),
          // null on refresh: no error emitted, stale WeatherLoaded stays
        ],
      );

      blocTest<WeatherCubit, WeatherState>(
        'keeps stale data when background refresh throws',
        build: () {
          when(() => repository.getCurrentWeather())
              .thenAnswer((_) async => _weather);
          when(() => repository.getForecast())
              .thenAnswer((_) async => _forecast);
          return WeatherCubit(repository);
        },
        act: (cubit) async {
          await cubit.loadWeather();
          when(() => repository.getCurrentWeather())
              .thenThrow(Exception('Network error'));
          await cubit.loadWeather();
        },
        expect: () => [
          isA<WeatherLoading>(),
          isA<WeatherLoaded>(),
          // error on refresh: no error emitted, stale WeatherLoaded stays
        ],
      );
    });
  });
}
