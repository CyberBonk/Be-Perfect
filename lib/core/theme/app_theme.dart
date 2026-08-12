import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ColorSeedOption {
  final String name;
  final Color color;

  const ColorSeedOption({required this.name, required this.color});
}

class AppTheme {
  static const seeds = <ColorSeedOption>[
    ColorSeedOption(name: "Beacon Teal", color: Color(0xFF006689)),
    ColorSeedOption(name: "Beacon Amber", color: Color(0xFFFFB300)),
    ColorSeedOption(name: "Neon Cyan", color: Color(0xFF00E5FF)),
    ColorSeedOption(name: "Emerald Green", color: Color(0xFF00E676)),
    ColorSeedOption(name: "Deep Purple", color: Color(0xFF7C4DFF)),
    ColorSeedOption(name: "Ruby Red", color: Color(0xFFD50000)),
    ColorSeedOption(name: "Electric Blue", color: Color(0xFF00B0FF)),
  ];

  static ThemeData lightThemeWithSeed(Color seed) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  static ThemeData darkThemeWithSeed(Color seed) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

class ThemeSeedColorNotifier extends Notifier<Color> {
  @override
  Color build() => AppTheme.seeds.first.color;
  void update(Color color) => state = color;
}

final themeSeedColorProvider =
    NotifierProvider<ThemeSeedColorNotifier, Color>(ThemeSeedColorNotifier.new);
