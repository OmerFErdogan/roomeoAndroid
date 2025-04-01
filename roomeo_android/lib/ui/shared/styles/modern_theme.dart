// lib/ui/shared/styles/modern_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernTheme {
  // Ana renkler
  static const Color primary = Color(0xFF3E64FF); // Mavi
  static const Color secondary = Color(0xFF5E60CE); // Mor
  static const Color accent = Color(0xFF5390D9); // Açık Mavi
  static const Color success = Color(0xFF48BF84); // Yeşil
  static const Color warning = Color(0xFFFFA62B); // Turuncu
  static const Color error = Color(0xFFFF5A5F); // Kırmızı
  static const Color info = Color(0xFF64B5F6); // Gök Mavisi

  // Arka plan renkleri
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Colors.white;

  // Metin renkleri
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textLight = Colors.white;
  static const Color textMuted = Color(0xFF8A8A8A);

  // Dekoratif elemanlar
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double defaultPadding = 16.0;
  static const double borderWidth = 1.0;
  static const Color borderColor = Color(0xFFEAEAEA);

  // Gölgeler
  static List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> strongShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      offset: Offset(0, 6),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  // Gradyanlar
  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      secondary,
    ],
  );

  static LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      accent,
      secondary.withOpacity(0.8),
    ],
  );

  // Buton stilleri
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: EdgeInsets.symmetric(
      vertical: 16.0,
      horizontal: 24.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    shadowColor: primary.withOpacity(0.5),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: primary,
    elevation: 0,
    padding: EdgeInsets.symmetric(
      vertical: 16.0,
      horizontal: 24.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: primary, width: borderWidth),
    ),
  );

  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primary,
    side: BorderSide(color: primary, width: borderWidth),
    padding: EdgeInsets.symmetric(
      vertical: 16.0,
      horizontal: 24.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primary,
    padding: EdgeInsets.symmetric(
      vertical: 8.0,
      horizontal: 16.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );

  // Metin stilleri - Modern, zarif tipografi
  static TextStyle headingStyle = GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
    letterSpacing: -0.5,
  );

  static TextStyle subheadingStyle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static TextStyle titleStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static TextStyle bodyStyle = GoogleFonts.inter(
    fontSize: 16,
    color: textPrimary,
    height: 1.5,
  );

  static TextStyle captionStyle = GoogleFonts.inter(
    fontSize: 14,
    color: textSecondary,
    height: 1.4,
  );

  static TextStyle buttonTextStyle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static TextStyle chipTextStyle = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  // Input dekorasyonu
  static InputDecoration inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: borderColor, width: borderWidth),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: borderColor, width: borderWidth),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: primary, width: borderWidth),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: error, width: borderWidth),
    ),
    hintStyle: captionStyle.copyWith(color: textSecondary.withOpacity(0.6)),
    prefixIconColor: textSecondary,
    suffixIconColor: textSecondary,
  );

  // Input dekorasyon teması
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: borderColor, width: borderWidth),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: borderColor, width: borderWidth),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: primary, width: borderWidth),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: error, width: borderWidth),
    ),
    hintStyle: captionStyle.copyWith(color: textSecondary.withOpacity(0.6)),
    prefixIconColor: textSecondary,
    suffixIconColor: textSecondary,
  );

  // Kart dekorasyonu
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: lightShadow,
    border: null,
  );

  // App theme
  static ThemeData themeData = ThemeData(
    primaryColor: primary,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: secondary,
      error: error,
      background: backgroundLight,
      surface: surfaceColor,
      onBackground: textPrimary,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: headingStyle,
        displayMedium: subheadingStyle,
        titleLarge: titleStyle,
        bodyLarge: bodyStyle,
        bodyMedium: bodyStyle,
        labelLarge: buttonTextStyle,
        titleMedium: subheadingStyle,
        titleSmall: captionStyle,
      ),
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
      foregroundColor: textPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      titleTextStyle: subheadingStyle,
      iconTheme: IconThemeData(color: textPrimary),
      toolbarHeight: 65,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    iconTheme: IconThemeData(
      color: textPrimary,
      size: 24,
    ),
    dividerTheme: DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 24,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimary,
      contentTextStyle: bodyStyle.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: primary,
      unselectedLabelColor: textSecondary,
      indicatorColor: primary,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: buttonTextStyle,
      unselectedLabelStyle:
          buttonTextStyle.copyWith(fontWeight: FontWeight.normal),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return primary;
        }
        return Colors.transparent;
      }),
      side: BorderSide(width: 1.5, color: textSecondary.withOpacity(0.5)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return primary;
        }
        return textSecondary;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return primary;
        }
        return Colors.white;
      }),
      trackColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return primary.withOpacity(0.5);
        }
        return textSecondary.withOpacity(0.3);
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: textSecondary.withOpacity(0.2),
      thumbColor: primary,
      overlayColor: primary.withOpacity(0.2),
      thumbShape: RoundSliderThumbShape(
        enabledThumbRadius: 12,
        elevation: 4,
      ),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
    ),
  );

  // Oda Kartları İçin Modern Dekorasyon
  static BoxDecoration roomCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: lightShadow,
  );

  // Aktif oda vurgulaması
  static BoxDecoration activeRoomCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: defaultShadow,
    border: Border.all(
      color: primary.withOpacity(0.3),
      width: 1.5,
    ),
  );

  // Özel oda
  static BoxDecoration privateRoomDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: lightShadow,
  );

  // Premium oda
  static BoxDecoration premiumRoomDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: lightShadow,
    border: Border.all(
      color: warning.withOpacity(0.5),
      width: 1,
    ),
  );

  // Kullanıcı koltuk dekorasyonu
  static BoxDecoration userSeatDecoration({
    bool isActive = false,
    bool isCurrentUser = false,
  }) {
    return BoxDecoration(
      color: isCurrentUser ? primary.withOpacity(0.05) : Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isActive || isCurrentUser ? lightShadow : null,
      border: Border.all(
        color: isCurrentUser ? primary : borderColor,
        width: isCurrentUser ? 1.5 : 1.0,
      ),
    );
  }

  // Boş koltuk dekorasyonu
  static BoxDecoration emptySeatDecoration = BoxDecoration(
    color: backgroundLight,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: borderColor,
      width: 1,
      style: BorderStyle.solid,
    ),
  );

  // Oda bölümü konteynerleri
  static BoxDecoration roomSectionDecoration = BoxDecoration(
    color: backgroundLight,
    borderRadius: BorderRadius.circular(smallBorderRadius),
    boxShadow: lightShadow,
  );

  // Zamanlayıcı konteyneri
  static BoxDecoration timerContainerDecoration = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: lightShadow,
    border: Border.all(
      color: borderColor,
      width: borderWidth,
    ),
  );

  // Durum rozeti
  static BoxDecoration roomStatusBadgeDecoration({required Color color}) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: color.withOpacity(0.5),
        width: 1.0,
      ),
    );
  }

  // Üye konteyneri
  static BoxDecoration membersContainerDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(smallBorderRadius),
    boxShadow: lightShadow,
  );

  // Katılımcı avatarı stillendirilmesi
  static BoxDecoration participantAvatarDecoration({
    required Color statusColor,
    bool isActive = true,
    bool isSpeaking = false,
  }) {
    return BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: isSpeaking ? lightShadow : null,
      border: Border.all(
        color: isSpeaking ? primary : borderColor,
        width: isSpeaking ? 2.0 : 1.0,
      ),
    );
  }

  // Oda kontrol butonları
  static BoxDecoration roomControlButtonDecoration = BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: lightShadow,
  );

  // Oda kodu girişi stillendirilmesi
  static InputDecoration roomCodeInputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: borderColor, width: borderWidth),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: borderColor, width: borderWidth),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: primary, width: borderWidth),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: error, width: borderWidth),
    ),
    hintText: 'Oda Erişim Kodu',
    hintStyle: captionStyle.copyWith(color: textSecondary.withOpacity(0.6)),
    prefixIcon: Icon(Icons.lock_outline, color: textSecondary),
    suffixIconColor: textSecondary,
  );

  // Oda tipi etiketi stillendirilmesi
  static TextStyle roomTypeStyle = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
  );

  // Oda tipi rozeti
  static BoxDecoration roomTypeDecoration({required bool isPremium}) {
    return BoxDecoration(
      color: isPremium ? warning.withOpacity(0.1) : primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(smallBorderRadius),
      border: Border.all(
        color: isPremium ? warning.withOpacity(0.5) : primary.withOpacity(0.5),
        width: 1.0,
      ),
    );
  }

  // Çalışma alanı konteyneri
  static BoxDecoration workspaceDecoration = BoxDecoration(
    color: backgroundLight,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: lightShadow,
  );

  // Masa ikonu stillendirilmesi
  static BoxDecoration deskIconDecoration({required Color color}) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      shape: BoxShape.circle,
      border: Border.all(
        color: color.withOpacity(0.5),
        width: 1.0,
      ),
    );
  }

  // Status stilleri
  static Map<String, StatusStyle> statusStyles = {
    'active': StatusStyle(
      color: success,
      icon: Icons.check_circle,
      label: 'Active',
    ),
    'working': StatusStyle(
      color: primary,
      icon: Icons.timer,
      label: 'Working',
    ),
    'break': StatusStyle(
      color: warning,
      icon: Icons.coffee,
      label: 'On Break',
    ),
    'offline': StatusStyle(
      color: textSecondary,
      icon: Icons.offline_bolt,
      label: 'Offline',
    ),
  };
}

// Status stil yardımcı sınıfı
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
