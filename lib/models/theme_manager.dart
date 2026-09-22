import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BilliardTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color accentColor;
  final Brightness brightness;
  final Color tableFeltColor;
  final Color tableCushionColor;
  final Color tableWoodColor;
  final Map<String, Color> indicatorColors;

  const BilliardTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.accentColor,
    required this.brightness,
    required this.tableFeltColor,
    required this.tableCushionColor,
    required this.tableWoodColor,
    required this.indicatorColors,
  });

  ThemeData toThemeData() {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        surface: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dialogBackgroundColor: backgroundColor,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ThemeManager {
  static const String _themePrefKey = 'selected_billiard_theme_id';

  static final List<BilliardTheme> themes = [
    // --- DARK THEMES ---
    const BilliardTheme(
      id: 'slate',
      name: 'Slate Dark (Đá phiến)',
      primaryColor: Colors.deepPurple,
      backgroundColor: Color(0xFF0F172A),
      cardColor: Color(0xFF1E293B),
      accentColor: Colors.cyanAccent,
      brightness: Brightness.dark,
      tableFeltColor: Color(0xFF334155),
      tableCushionColor: Color(0xFF1E293B),
      tableWoodColor: Color(0xFF020617),
      indicatorColors: {
        'cueBallAngle': Color(0xFFFFEA00), // Vàng chanh sáng
        'cardeBallClearance': Color(0xFF00E5FF), // Xanh cyan neon
        'contactPoint': Color(0xFFFF9100), // Cam sáng
        'targetPoint': Color(0xFFFF1744), // Đỏ san hô
        'slantCueCarde': Color(0xFFF50057), // Hồng sen/magenta
        'slantCardeTarget': Color(0xFFFFFFFF), // Trắng tinh
      },
    ),
    const BilliardTheme(
      id: 'green',
      name: 'Billiard Green (Bàn bida)',
      primaryColor: Colors.teal,
      backgroundColor: Color(0xFF062419),
      cardColor: Color(0xFF0C3C2A),
      accentColor: Colors.tealAccent,
      brightness: Brightness.dark,
      tableFeltColor: Color(0xFF0D5C3A),
      tableCushionColor: Color(0xFF073E26),
      tableWoodColor: Color(0xFF4A1A05),
      indicatorColors: {
        'cueBallAngle': Color(0xFFFFEA00), // Vàng chanh sáng
        'cardeBallClearance': Color(0xFF00E5FF), // Xanh cyan neon
        'contactPoint': Color(0xFFFF9100), // Cam sáng
        'targetPoint': Color(0xFFFF1744), // Đỏ san hô
        'slantCueCarde': Color(0xFFF50057), // Hồng sen/magenta
        'slantCardeTarget': Color(0xFFFFFFFF), // Trắng tinh
      },
    ),
    const BilliardTheme(
      id: 'blue',
      name: 'Ocean Blue (Đại dương)',
      primaryColor: Colors.blue,
      backgroundColor: Color(0xFF0B132B),
      cardColor: Color(0xFF1C2541),
      accentColor: Colors.lightBlueAccent,
      brightness: Brightness.dark,
      tableFeltColor: Color(0xFF1E3A8A),
      tableCushionColor: Color(0xFF172554),
      tableWoodColor: Color(0xFF0F172A),
      indicatorColors: {
        'cueBallAngle': Color(0xFFFFEA00), // Vàng chanh sáng
        'cardeBallClearance': Color(0xFF00E5FF), // Xanh cyan neon
        'contactPoint': Color(0xFFFF9100), // Cam sáng
        'targetPoint': Color(0xFFFF1744), // Đỏ san hô
        'slantCueCarde': Color(0xFFF50057), // Hồng sen/magenta
        'slantCardeTarget': Color(0xFFFFFFFF), // Trắng tinh
      },
    ),
    const BilliardTheme(
      id: 'purple',
      name: 'Cyberpunk (Tím Neon)',
      primaryColor: Colors.purple,
      backgroundColor: Color(0xFF120C1F),
      cardColor: Color(0xFF1D1530),
      accentColor: Colors.pinkAccent,
      brightness: Brightness.dark,
      tableFeltColor: Color(0xFF4C1D95),
      tableCushionColor: Color(0xFF2E1065),
      tableWoodColor: Color(0xFF090514),
      indicatorColors: {
        'cueBallAngle': Color(0xFFFFEA00), // Vàng chanh sáng
        'cardeBallClearance': Color(0xFF00E5FF), // Xanh cyan neon
        'contactPoint': Color(0xFFFF9100), // Cam sáng
        'targetPoint': Color(0xFFFF1744), // Đỏ san hô
        'slantCueCarde': Color(0xFFF50057), // Hồng sen/magenta
        'slantCardeTarget': Color(0xFFFFFFFF), // Trắng tinh
      },
    ),
    // --- LIGHT THEMES ---
    const BilliardTheme(
      id: 'light_slate',
      name: 'Slate Light (Bạc thanh lịch)',
      primaryColor: Colors.deepPurple,
      backgroundColor: Color(0xFFF1F5F9),
      cardColor: Colors.white,
      accentColor: Colors.deepPurple,
      brightness: Brightness.light,
      tableFeltColor: Color(0xFFCBD5E1),
      tableCushionColor: Color(0xFF94A3B8),
      tableWoodColor: Color(0xFF475569),
      indicatorColors: {
        'cueBallAngle': Color(0xFFFFEA00), // Vàng chanh sáng
        'cardeBallClearance': Color(0xFF00E5FF), // Xanh cyan neon
        'contactPoint': Color(0xFFFF9100), // Cam sáng
        'targetPoint': Color(0xFFFF1744), // Đỏ san hô
        'slantCueCarde': Color(0xFFF50057), // Hồng sen/magenta
        'slantCardeTarget': Color(0xFFFFFFFF), // Trắng tinh
      },
    ),
    const BilliardTheme(
      id: 'light_green',
      name: 'Mint Light (Xanh bạc hà)',
      primaryColor: Colors.teal,
      backgroundColor: Color(0xFFF0FDF4),
      cardColor: Colors.white,
      accentColor: Colors.teal,
      brightness: Brightness.light,
      tableFeltColor: Color(0xFFD1FAE5),
      tableCushionColor: Color(0xFF34D399),
      tableWoodColor: Color(0xFF065F46),
      indicatorColors: {
        'cueBallAngle': Color(0xFFFFEA00), // Vàng chanh sáng
        'cardeBallClearance': Color(0xFF00E5FF), // Xanh cyan neon
        'contactPoint': Color(0xFFFF9100), // Cam sáng
        'targetPoint': Color(0xFFFF1744), // Đỏ san hô
        'slantCueCarde': Color(0xFFF50057), // Hồng sen/magenta
        'slantCardeTarget': Color(0xFFFFFFFF), // Trắng tinh
      },
    ),
    const BilliardTheme(
      id: 'light_orange',
      name: 'Autumn Light (Cam mùa thu)',
      primaryColor: Colors.orange,
      backgroundColor: Color(0xFFFFF7ED),
      cardColor: Colors.white,
      accentColor: Colors.orange,
      brightness: Brightness.light,
      tableFeltColor: Color(0xFFFED7AA),
      tableCushionColor: Color(0xFFFDBA74),
      tableWoodColor: Color(0xFF7C2D12),
      indicatorColors: {
        'cueBallAngle': Color(0xFFFFEA00), // Vàng chanh sáng
        'cardeBallClearance': Color(0xFF00E5FF), // Xanh cyan neon
        'contactPoint': Color(0xFFFF9100), // Cam sáng
        'targetPoint': Color(0xFFFF1744), // Đỏ san hô
        'slantCueCarde': Color(0xFFF50057), // Hồng sen/magenta
        'slantCardeTarget': Color(0xFFFFFFFF), // Trắng tinh
      },
    ),
  ];

  static final ValueNotifier<BilliardTheme> currentTheme =
      ValueNotifier<BilliardTheme>(themes[0]);

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeId = prefs.getString(_themePrefKey);
    if (savedThemeId != null) {
      final theme = themes.firstWhere(
        (t) => t.id == savedThemeId,
        orElse: () => themes[0],
      );
      currentTheme.value = theme;
    }
  }

  static Future<void> setTheme(BilliardTheme theme) async {
    currentTheme.value = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, theme.id);
  }
}
