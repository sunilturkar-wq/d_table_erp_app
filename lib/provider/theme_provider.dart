import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  static const Color primaryBlue = Color(0xFF003366); // Navy blue

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get themeData {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    textTheme: Typography.blackMountainView.apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    primaryTextTheme: Typography.blackMountainView.apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE9ECEF),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(color: Colors.black, fontSize: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(color: Colors.black, fontSize: 13),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryBlue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white,
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue),
      ),
    ),
    extensions: const [AppColors.light],
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    textTheme: Typography.blackMountainView.apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    primaryTextTheme: Typography.blackMountainView.apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE9ECEF),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(color: Colors.black, fontSize: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(color: Colors.black, fontSize: 13),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryBlue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white,
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue),
      ),
    ),
    extensions: const [AppColors.light],
  );
}

/// Custom color extension — theme-aware colors har jagah accessible
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color cardBackground;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color toolbarBackground;
  final Color inputBackground;
  final Color chipBackground;
  final Color tableHeaderBackground;
  final Color shadowColor;
  final Color divider;

  const AppColors({
    required this.cardBackground,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.toolbarBackground,
    required this.inputBackground,
    required this.chipBackground,
    required this.tableHeaderBackground,
    required this.shadowColor,
    required this.divider,
  });

  static const AppColors light = AppColors(
    cardBackground: Colors.white,
    cardBorder: Color(0xFFE9ECEF),
    textPrimary: Colors.black,
    textSecondary: Colors.black,
    textMuted: Color(0xFF868E96),
    toolbarBackground: Colors.white,
    inputBackground: Colors.white,
    chipBackground: Colors.white,
    tableHeaderBackground: Color(0xFF1A1D1E),
    shadowColor: Color(0x0A000000),
    divider: Color(0xFFE9ECEF),
  );

  static const AppColors dark = AppColors(
    cardBackground: Color(0xFF1E1E2E),
    cardBorder: Color(0xFF2A2D3E),
    textPrimary: Color(0xFFE9ECEF),
    textSecondary: Color(0xFFADB5BD),
    textMuted: Color(0xFF6C757D),
    toolbarBackground: Color(0xFF252538),
    inputBackground: Color(0xFF2A2D3E),
    chipBackground: Color(0xFF252538),
    tableHeaderBackground: Color(0xFF0D0D1A),
    shadowColor: Color(0x1A000000),
    divider: Color(0xFF2A2D3E),
  );

  @override
  AppColors copyWith({
    Color? cardBackground,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? toolbarBackground,
    Color? inputBackground,
    Color? chipBackground,
    Color? tableHeaderBackground,
    Color? shadowColor,
    Color? divider,
  }) {
    return AppColors(
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      toolbarBackground: toolbarBackground ?? this.toolbarBackground,
      inputBackground: inputBackground ?? this.inputBackground,
      chipBackground: chipBackground ?? this.chipBackground,
      tableHeaderBackground:
          tableHeaderBackground ?? this.tableHeaderBackground,
      shadowColor: shadowColor ?? this.shadowColor,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      toolbarBackground: Color.lerp(
        toolbarBackground,
        other.toolbarBackground,
        t,
      )!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      tableHeaderBackground: Color.lerp(
        tableHeaderBackground,
        other.tableHeaderBackground,
        t,
      )!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
