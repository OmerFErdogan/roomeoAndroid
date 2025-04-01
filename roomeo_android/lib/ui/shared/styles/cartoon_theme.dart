// lib/ui/shared/styles/cartoon_theme.dart
import 'dart:math';

import 'package:flutter/material.dart';

class CartoonTheme {
  // Main colors - Black and white
  static const Color primary = Color(0xFF000000); // Pure Black
  static const Color secondary = Color(0xFF333333); // Dark Gray
  static const Color accent = Color(0xFF666666); // Medium Gray
  static const Color success = Color(0xFF000000); // Black
  static const Color warning = Color(0xFF333333); // Dark Gray
  static const Color info = Color(0xFF666666); // Medium Gray
  static const Color error = Color(0xFF000000); // Black

  // Background colors
  static const Color backgroundLight = Color(0xFFF8F8F8); // Off-white
  static const Color backgroundDark = Color(0xFFE0E0E0); // Light gray
  static const Color cardColor = Colors.white; // Pure white
  static const Color drawerColor = Color(0xFFF0F0F0); // Slightly off-white

  // Text colors
  static const Color textPrimary = Color(0xFF000000); // Black
  static const Color textSecondary = Color(0xFF666666); // Medium Gray
  static const Color textLight = Colors.white; // White

  // Decorative elements
  static const double borderRadius = 8.0; // More comic-style corners
  static const double smallBorderRadius = 4.0;
  static const double defaultPadding = 16.0;
  static const double borderWidth = 3.0; // Thicker borders for cartoon effect
  static const Color borderColor = Color(0xFF000000); // Black borders

  // Shadows - Bold and comic-like
  static List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Colors.black,
      offset: Offset(4, 4),
      blurRadius: 0, // Sharp shadow for comic effect
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      offset: Offset(2, 2),
      blurRadius: 0, // Sharp shadow
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> innerShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      offset: Offset(2, 2),
      blurRadius: 0, // Sharp inner shadow
      spreadRadius: -2,
    ),
  ];

  // No gradients in black and white theme
  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF000000),
      Color(0xFF333333),
    ],
  );

  static LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF333333),
      Color(0xFF000000),
    ],
  );

  // Button styles - Comic book style with thick borders
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    padding: EdgeInsets.symmetric(
      vertical: 16.0,
      horizontal: 24.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: Colors.black, width: borderWidth),
    ),
    shadowColor: Colors.black,
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFE0E0E0),
    foregroundColor: Colors.black,
    elevation: 0,
    padding: EdgeInsets.symmetric(
      vertical: 16.0,
      horizontal: 24.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: Colors.black, width: borderWidth),
    ),
    shadowColor: Colors.black,
  );

  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    side: BorderSide(color: Colors.black, width: borderWidth),
    padding: EdgeInsets.symmetric(
      vertical: 16.0,
      horizontal: 24.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: Colors.black,
    padding: EdgeInsets.symmetric(
      vertical: 8.0,
      horizontal: 16.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );

  // Text styles - Bold, comic-like typography
  static TextStyle headingStyle = TextStyle(
    fontFamily: 'ComicNeue',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
    letterSpacing: 0,
  );

  static TextStyle subheadingStyle = TextStyle(
    fontFamily: 'ComicNeue',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static TextStyle titleStyle = TextStyle(
    fontFamily: 'ComicNeue',
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );

  static TextStyle bodyStyle = TextStyle(
    fontFamily: 'ComicNeue',
    fontSize: 16,
    color: textPrimary,
    height: 1.5,
  );

  static TextStyle captionStyle = TextStyle(
    fontFamily: 'ComicNeue',
    fontSize: 14,
    color: textSecondary,
    height: 1.4,
  );

  static TextStyle buttonTextStyle = TextStyle(
    fontFamily: 'ComicNeue',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static TextStyle chipTextStyle = TextStyle(
    fontFamily: 'ComicNeue',
    fontSize: 12,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  // Input decoration - Comic book style with thick borders
  static InputDecoration inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.black, width: borderWidth),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.black, width: borderWidth),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.black, width: borderWidth),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.black, width: borderWidth),
    ),
    hintStyle: captionStyle.copyWith(color: textSecondary),
    prefixIconColor: Colors.black,
    suffixIconColor: Colors.black,
  );

  // Input decoration theme
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.black, width: borderWidth),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.black, width: borderWidth),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.black, width: borderWidth),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.black, width: borderWidth),
    ),
    hintStyle: captionStyle.copyWith(color: textSecondary),
    prefixIconColor: Colors.black,
    suffixIconColor: Colors.black,
  );

  // Card decoration - Comic style with thick borders and offset shadow
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: defaultShadow,
    border: Border.all(
      color: Colors.black,
      width: borderWidth,
    ),
  );

  // Chip decoration
  static BoxDecoration chipDecoration({Color color = Colors.black}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(smallBorderRadius),
      border: Border.all(
        color: Colors.black,
        width: 1.5,
      ),
    );
  }

  // Status indicator decoration
  static BoxDecoration statusDecoration(
      {required Color color, bool isActive = true}) {
    return BoxDecoration(
      color: isActive ? Colors.white : Color(0xFFE0E0E0),
      borderRadius: BorderRadius.circular(smallBorderRadius),
      border: Border.all(
        color: Colors.black,
        width: 2.0,
      ),
    );
  }

  // App theme - Comprehensive theme definition for black and white cartoon style
  static ThemeData themeData = ThemeData(
    primaryColor: primary,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: secondary,
      error: error,
      background: backgroundLight,
      surface: cardColor,
      onBackground: textPrimary,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: backgroundLight,
    fontFamily: 'ComicNeue',
    textTheme: TextTheme(
      displayLarge: headingStyle,
      displayMedium: subheadingStyle,
      titleLarge: titleStyle,
      bodyLarge: bodyStyle,
      bodyMedium: bodyStyle,
      labelLarge: buttonTextStyle,
      titleMedium: subheadingStyle,
      titleSmall: captionStyle,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: outlinedButtonStyle,
    ),
    textButtonTheme: TextButtonThemeData(
      style: textButtonStyle,
    ),
    inputDecorationTheme: inputDecorationTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      shadowColor: Colors.black,
      titleTextStyle: subheadingStyle,
      iconTheme: IconThemeData(color: Colors.black),
      toolbarHeight: 65,
      shape: Border(
        bottom: BorderSide(
          color: Colors.black,
          width: borderWidth,
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: Colors.black, width: borderWidth),
      ),
    ),
    iconTheme: IconThemeData(
      color: Colors.black,
      size: 24,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.black,
      thickness: 2,
      space: 24,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: Colors.black, width: borderWidth),
      ),
      extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: Colors.black, width: borderWidth),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: bodyStyle.copyWith(color: Colors.black),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: Colors.black, width: borderWidth),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.black,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: buttonTextStyle,
      unselectedLabelStyle:
          buttonTextStyle.copyWith(fontWeight: FontWeight.normal),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.black;
        }
        return Colors.white;
      }),
      side: BorderSide(width: borderWidth, color: Colors.black),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.black;
        }
        return Colors.black;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.black;
        }
        return Colors.white;
      }),
      trackColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.grey;
        }
        return Colors.grey.withOpacity(0.5);
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
        side: BorderSide(
          color: Colors.black,
          width: borderWidth,
          style: BorderStyle.solid,
        ),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Colors.black,
      inactiveTrackColor: Colors.grey,
      thumbColor: Colors.white,
      overlayColor: Colors.black.withOpacity(0.3),
      thumbShape: RoundSliderThumbShape(
        enabledThumbRadius: 12,
        elevation: 4,
      ),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
    ),
  );

  // Room card decoration - Strong black border with offset shadow for comic effect
  static BoxDecoration roomCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black,
        offset: Offset(3, 3),
        blurRadius: 0,
      ),
    ],
    border: Border.all(
      color: Colors.black,
      width: borderWidth,
    ),
  );

  // Active room with highlight
  static BoxDecoration activeRoomCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black,
        offset: Offset(3, 3),
        blurRadius: 0,
      ),
    ],
    border: Border.all(
      color: Colors.black,
      width: borderWidth,
    ),
  );

  // Private room - same as regular with distinctive pattern
  static BoxDecoration privateRoomDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black,
        offset: Offset(3, 3),
        blurRadius: 0,
      ),
    ],
    border: Border.all(
      color: Colors.black,
      width: borderWidth,
    ),
  );

  // Premium room - more distinctive border
  static BoxDecoration premiumRoomDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black,
        offset: Offset(3, 3),
        blurRadius: 0,
      ),
    ],
    border: Border.all(
      color: Colors.black,
      width: borderWidth,
    ),
  );

  // User seat styling
  static BoxDecoration userSeatDecoration(
      {bool isActive = false, bool isCurrentUser = false}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isActive || isCurrentUser ? defaultShadow : null,
      border: Border.all(
        color: Colors.black,
        width: isCurrentUser ? 3.0 : 2.0,
      ),
    );
  }

  // Empty seat with dashed border for comic effect
  static BoxDecoration emptySeatDecoration = BoxDecoration(
    color: backgroundLight,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: Colors.black.withOpacity(0.5),
      width: 1.5,
      style: BorderStyle.solid,
    ),
  );

  // Room section containers
  static BoxDecoration roomSectionDecoration = BoxDecoration(
    color: backgroundLight,
    borderRadius: BorderRadius.circular(smallBorderRadius),
    boxShadow: lightShadow,
    border: Border.all(
      color: Colors.black,
      width: 2.0,
    ),
  );

  // Timer container - circular with thick border
  static BoxDecoration timerContainerDecoration = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black,
        offset: Offset(2, 2),
        blurRadius: 0,
      ),
    ],
    border: Border.all(
      color: Colors.black,
      width: borderWidth,
    ),
  );

  // Status badge with strong border
  static BoxDecoration roomStatusBadgeDecoration({required Color color}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: lightShadow,
      border: Border.all(
        color: Colors.black,
        width: 2.0,
      ),
    );
  }

  // Member container with offset shadow
  static BoxDecoration membersContainerDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(smallBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black,
        offset: Offset(2, 2),
        blurRadius: 0,
      ),
    ],
    border: Border.all(
      color: Colors.black,
      width: 2.0,
    ),
  );

  // Participant avatar styling
  static BoxDecoration participantAvatarDecoration({
    required Color statusColor,
    bool isActive = true,
    bool isSpeaking = false,
  }) {
    return BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: isSpeaking ? defaultShadow : null,
      border: Border.all(
        color: Colors.black,
        width: isSpeaking ? 3.0 : 2.0,
      ),
    );
  }

  // Room control buttons with comic effect
  static BoxDecoration roomControlButtonDecoration = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black,
        offset: Offset(2, 2),
        blurRadius: 0,
      ),
    ],
    border: Border.all(
      color: Colors.black,
      width: 2.0,
    ),
  );

  // Room code input with distinctive styling
  static InputDecoration roomCodeInputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.black, width: borderWidth),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.black, width: borderWidth),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.black, width: borderWidth),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.black, width: borderWidth),
    ),
    hintText: 'Room Access Code',
    hintStyle: captionStyle.copyWith(color: Colors.grey),
    prefixIcon: Icon(Icons.lock, color: Colors.black),
    suffixIconColor: Colors.black,
  );

  // Room type label styling
  static TextStyle roomTypeStyle = TextStyle(
    fontFamily: 'ComicNeue',
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    height: 1.2,
  );

  // Room type badge
  static BoxDecoration roomTypeDecoration({required bool isPremium}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(smallBorderRadius),
      boxShadow: isPremium ? lightShadow : null,
      border: Border.all(
        color: Colors.black,
        width: isPremium ? 2.0 : 1.5,
      ),
    );
  }

  // Workspace container
  static BoxDecoration workspaceDecoration = BoxDecoration(
    color: backgroundLight,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black,
        offset: Offset(3, 3),
        blurRadius: 0,
      ),
    ],
    border: Border.all(
      color: Colors.black,
      width: borderWidth,
    ),
  );

  // Desk icon styling
  static BoxDecoration deskIconDecoration({required Color color}) {
    return BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black,
          offset: Offset(2, 2),
          blurRadius: 0,
        ),
      ],
      border: Border.all(
        color: Colors.black,
        width: 2.0,
      ),
    );
  }

  // Jagged edge path for comic book style panels
  static Path getZigzagPath(Size size, {bool isTop = true}) {
    final height = 15.0;
    final path = Path();
    final segmentWidth = 10.0; // Width of each zigzag segment
    final zigzagPoints = (size.width / segmentWidth).ceil() + 1;

    if (isTop) {
      path.moveTo(0, height);

      for (int i = 0; i < zigzagPoints; i++) {
        final x1 = i * segmentWidth;
        final x2 = (i + 0.5) * segmentWidth;
        final x3 = (i + 1) * segmentWidth;

        // Create zigzag pattern
        path.lineTo(x1, height);
        path.lineTo(x2, 0);
        path.lineTo(x3, height);
      }

      path.lineTo(size.width, height);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    } else {
      path.moveTo(0, size.height - height);

      for (int i = 0; i < zigzagPoints; i++) {
        final x1 = i * segmentWidth;
        final x2 = (i + 0.5) * segmentWidth;
        final x3 = (i + 1) * segmentWidth;

        // Create zigzag pattern at bottom
        path.lineTo(x1, size.height - height);
        path.lineTo(x2, size.height);
        path.lineTo(x3, size.height - height);
      }

      path.lineTo(size.width, size.height - height);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    path.close();
    return path;
  }

  // Speech bubble path for comic book style
  static Path getSpeechBubblePath(Size size) {
    final path = Path();
    final radius = size.width * 0.1;
    final tailWidth = size.width * 0.2;
    final tailHeight = size.height * 0.2;

    // Start at the top left with rounded corner
    path.moveTo(radius, 0);

    // Top edge
    path.lineTo(size.width - radius, 0);

    // Top right corner
    path.quadraticBezierTo(size.width, 0, size.width, radius);

    // Right edge
    path.lineTo(size.width, size.height - radius - tailHeight);

    // Bottom right corner
    path.quadraticBezierTo(size.width, size.height - tailHeight,
        size.width - radius, size.height - tailHeight);

    // Bottom edge (before tail)
    path.lineTo(size.width * 0.75 + tailWidth / 2, size.height - tailHeight);

    // Speech bubble tail
    path.lineTo(size.width * 0.85, size.height);
    path.lineTo(size.width * 0.75 - tailWidth / 2, size.height - tailHeight);

    // Rest of bottom edge
    path.lineTo(radius, size.height - tailHeight);

    // Bottom left corner
    path.quadraticBezierTo(
        0, size.height - tailHeight, 0, size.height - radius - tailHeight);

    // Left edge
    path.lineTo(0, radius);

    // Top left corner
    path.quadraticBezierTo(0, 0, radius, 0);

    path.close();
    return path;
  }

  // Comic explosion path (for notifications or emphasis)
  static Path getExplosionPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius =
        size.width < size.height ? size.width / 2 : size.height / 2;
    final innerRadius = outerRadius * 0.6;
    final points = 10; // Number of points in the explosion star

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * pi / points) + (pi / 10);
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  // Status styles with black and white icons
  static Map<String, StatusStyle> statusStyles = {
    'active': StatusStyle(
      color: Colors.black,
      icon: Icons.check_circle,
      label: 'Active',
    ),
    'working': StatusStyle(
      color: Colors.black,
      icon: Icons.timer,
      label: 'Working',
    ),
    'break': StatusStyle(
      color: Colors.black,
      icon: Icons.coffee,
      label: 'On Break',
    ),
    'offline': StatusStyle(
      color: Colors.grey,
      icon: Icons.offline_bolt,
      label: 'Offline',
    ),
  };
}

// Status style helper class
class StatusStyle {
  final Color color;
  final IconData icon;
  final String label;

  StatusStyle({
    required this.color,
    required this.icon,
    required this.label,
  });
}
