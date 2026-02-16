import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF8B7EF6),
  primaryColorDark: const Color(0xFF6C5CE7),
  primaryColorLight: const Color(0xFFB5A8FF),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF8B7EF6),
    secondary: Color(0xFF00D68F),
    tertiary: Color(0xFFFF8A5C),
    surface: Color(0xFF1E1E2E),
    background: Color(0xFF121212),
    error: Color(0xFFFF6B6B),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.white,
    onBackground: Colors.white,
    onError: Colors.white,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E2E),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: 0.15,
    ),
    iconTheme: IconThemeData(color: Colors.white, size: 24),
    actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: 0,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: 0,
      height: 1.22,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: 0,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: 0,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: 0,
      height: 1.33,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: 0,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: 0.15,
      height: 1.50,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE0E0E0),
      fontFamily: 'Inter',
      letterSpacing: 0.1,
      height: 1.43,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Color(0xFFE0E0E0),
      fontFamily: 'Inter',
      letterSpacing: 0.5,
      height: 1.50,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFFC0C0C0),
      fontFamily: 'Inter',
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Color(0xFFA0A0A0),
      fontFamily: 'Inter',
      letterSpacing: 0.4,
      height: 1.33,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFFE0E0E0),
      fontFamily: 'Inter',
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: Color(0xFFC0C0C0),
      fontFamily: 'Inter',
      letterSpacing: 0.5,
      height: 1.45,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF8B7EF6),
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        letterSpacing: 0.5,
      ),
      minimumSize: const Size(88, 48),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (states) => states.contains(MaterialState.pressed)
            ? Colors.white.withOpacity(0.12)
            : null,
      ),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF8B7EF6),
      side: const BorderSide(color: Color(0xFF8B7EF6), width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        letterSpacing: 0.5,
      ),
      minimumSize: const Size(88, 48),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (states) => states.contains(MaterialState.pressed)
            ? const Color(0xFF8B7EF6).withOpacity(0.12)
            : null,
      ),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF8B7EF6),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        letterSpacing: 0.5,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      minimumSize: const Size(64, 40),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (states) => states.contains(MaterialState.pressed)
            ? const Color(0xFF8B7EF6).withOpacity(0.12)
            : null,
      ),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2A2A3A),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF8B7EF6), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
    ),
    hintStyle: const TextStyle(
      color: Color(0xFF808080),
      fontSize: 15,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
    ),
    labelStyle: const TextStyle(
      color: Color(0xFFC0C0C0),
      fontSize: 14,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: const TextStyle(
      color: Color(0xFF8B7EF6),
      fontSize: 14,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
    ),
    errorStyle: const TextStyle(
      color: Color(0xFFFF6B6B),
      fontSize: 12,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
    ),
    prefixStyle: const TextStyle(
      color: Color(0xFFC0C0C0),
      fontSize: 15,
      fontFamily: 'Inter',
    ),
    suffixStyle: const TextStyle(
      color: Color(0xFFC0C0C0),
      fontSize: 15,
      fontFamily: 'Inter',
    ),
  ),

  cardTheme: const CardThemeData(
    color: Color(0xFF1E1E2E),
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF1E1E2E),
    selectedItemColor: Color(0xFF8B7EF6),
    unselectedItemColor: Color(0xFF808080),
    selectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontFamily: 'Inter',
      letterSpacing: 0.4,
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontFamily: 'Inter',
      letterSpacing: 0.4,
    ),
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),

  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFF1E1E2E),
    indicatorColor: const Color(0xFF8B7EF6).withOpacity(0.2),
    labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
          (states) => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Inter',
        letterSpacing: 0.4,
      ),
    ),
    iconTheme: MaterialStateProperty.resolveWith<IconThemeData>(
          (states) => const IconThemeData(
        size: 24,
      ),
    ),
  ),

  dividerTheme: const DividerThemeData(
    color: Color(0xFF2A2A3A),
    thickness: 1,
    space: 1,
  ),

  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF2A2A3A),
    disabledColor: const Color(0xFF1E1E2E),
    selectedColor: const Color(0xFF8B7EF6),
    secondarySelectedColor: const Color(0xFF8B7EF6).withOpacity(0.2),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    labelStyle: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      fontFamily: 'Inter',
      color: Colors.white,
    ),
    secondaryLabelStyle: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      fontFamily: 'Inter',
      color: Color(0xFFC0C0C0),
    ),
    brightness: Brightness.dark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF8B7EF6),
    foregroundColor: Colors.white,
    elevation: 0,
    highlightElevation: 4,
    shape: CircleBorder(),
  ),

  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFF1E1E2E),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: 0.15,
    ),
    contentTextStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Color(0xFFE0E0E0),
      fontFamily: 'Inter',
      letterSpacing: 0.5,
    ),
  ),

  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF2A2A3A),
    contentTextStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: 0.25,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    behavior: SnackBarBehavior.floating,
  ),

  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF1E1E2E),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    dragHandleColor: Color(0xFF2A2A3A),
    showDragHandle: false,
  ),

  listTileTheme: const ListTileThemeData(
    tileColor: Colors.transparent,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    titleTextStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      fontFamily: 'Inter',
      letterSpacing: 0.15,
    ),
    subtitleTextStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFFC0C0C0),
      fontFamily: 'Inter',
      letterSpacing: 0.25,
    ),
    leadingAndTrailingTextStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFFE0E0E0),
      fontFamily: 'Inter',
    ),
    iconColor: Color(0xFFC0C0C0),
    textColor: Colors.white,
  ),

  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF8B7EF6);
      }
      return const Color(0xFF808080);
    }),
    trackColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF8B7EF6).withOpacity(0.5);
      }
      return const Color(0xFF2A2A3A);
    }),
  ),

  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF8B7EF6);
      }
      return Colors.transparent;
    }),
    checkColor: MaterialStateProperty.all(Colors.white),
    side: const BorderSide(color: Color(0xFF808080), width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  ),

  radioTheme: RadioThemeData(
    fillColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF8B7EF6);
      }
      return const Color(0xFF808080);
    }),
  ),

  sliderTheme: SliderThemeData(
    activeTrackColor: const Color(0xFF8B7EF6),
    inactiveTrackColor: const Color(0xFF2A2A3A),
    thumbColor: const Color(0xFF8B7EF6),
    overlayColor: const Color(0xFF8B7EF6).withOpacity(0.12),
    valueIndicatorColor: const Color(0xFF8B7EF6),
    valueIndicatorTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
    ),
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF8B7EF6),
    linearTrackColor: Color(0xFF2A2A3A),
    circularTrackColor: Color(0xFF2A2A3A),
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: Color(0xFF8B7EF6),
    unselectedLabelColor: Color(0xFF808080),
    indicatorColor: Color(0xFF8B7EF6),
    labelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
      letterSpacing: 0.5,
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: 'Inter',
      letterSpacing: 0.5,
    ),
  ),

  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: const Color(0xFF2A2A3A),
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Colors.white,
      fontFamily: 'Inter',
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
);