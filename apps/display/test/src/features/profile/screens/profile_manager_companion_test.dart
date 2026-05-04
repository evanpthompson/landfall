import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:mocktail/mocktail.dart';

import 'package:display/src/features/profile/cubit/dashboard_profile_cubit.dart';
import 'package:display/src/features/profile/screens/profile_manager_screen.dart';
import 'package:display/src/features/theme/cubit/theme_cubit.dart';

class _MockProfileRepo extends Mock implements DashboardProfileRepository {}
class _MockThemeRepo extends Mock implements ThemeRepository {}

ProfileInfo _profile({String? companionThemeSlug}) => ProfileInfo(
      id: 1,
      name: 'Gaming Night',
      slug: 'gaming-night',
      isActive: false,
      layout: DashboardLayout.weekdayLayout(),
      sortOrder: 1,
      companionThemeSlug: companionThemeSlug,
    );

Widget _buildApp({required ProfileInfo profile}) {
  final profileRepo = _MockProfileRepo();
  final themeRepo = _MockThemeRepo();

  when(() => profileRepo.listProfiles()).thenAnswer((_) async => [profile]);
  when(() => themeRepo.listThemes()).thenAnswer((_) async => []);

  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => DashboardProfileCubit(profileRepo)..loadProfiles(),
      ),
      BlocProvider(
        create: (_) => ThemeCubit(themeRepo)..loadThemes(),
      ),
    ],
    child: const MaterialApp(home: ProfileManagerScreen()),
  );
}

void main() {
  group('ProfileManagerScreen companion theme badge', () {
    testWidgets('shows companion theme chip when companionThemeSlug is set',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(profile: _profile(companionThemeSlug: 'neon-arcade')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('companion_theme_chip')), findsOneWidget);
    });

    testWidgets('does not show companion theme chip when slug is null',
        (tester) async {
      await tester.pumpWidget(_buildApp(profile: _profile()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('companion_theme_chip')), findsNothing);
    });

    testWidgets('companion chip shows theme slug text', (tester) async {
      await tester.pumpWidget(
        _buildApp(profile: _profile(companionThemeSlug: 'neon-arcade')),
      );
      await tester.pumpAndSettle();

      expect(find.text('neon-arcade'), findsOneWidget);
    });
  });
}
