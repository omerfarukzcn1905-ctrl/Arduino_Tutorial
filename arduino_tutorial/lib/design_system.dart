import 'package:flutter/material.dart';

/// 🎨 Design System for Arduino Tutorial App
/// This file contains all design tokens (colors, spacing, text styles, etc.)
/// Use these throughout the app to maintain consistency

// ============================================================================
// 🎯 COLOR PALETTE
// ============================================================================
class AppColors {
  // Primary Colors (Tech-forward gradient blues & purples)
  static const Color primaryDark = Color(0xFF0F1419); // Dark background
  static const Color primaryBlue = Color(0xFF00A8E8); // Tech blue
  static const Color primaryPurple = Color(0xFF7209B7); // Electric purple
  static const Color primaryCyan = Color(0xFF00D9FF); // Bright cyan

  // Accent Colors (For interactive elements)
  static const Color accentGreen = Color(0xFF00FF41); // Success (neon green)
  static const Color accentOrange = Color(0xFFFF6B35); // Warning
  static const Color accentRed = Color(0xFFFF4757); // Error
  static const Color accentYellow = Color(0xFFFFD60A); // Highlight

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFF8B8B8B);
  static const Color darkGrey = Color(0xFF2A2A2A);
  static const Color black = Color(0xFF000000);

  // Semantic Colors
  static const Color success = accentGreen;
  static const Color warning = accentOrange;
  static const Color error = accentRed;
  static const Color info = primaryBlue;
}

// ============================================================================
// 📐 SPACING & SIZING
// ============================================================================
class AppSpacing {
  // Basic unit: 4px (use multiples for consistent spacing)
  static const double xs = 4.0;    // Extra small
  static const double sm = 8.0;    // Small
  static const double md = 16.0;   // Medium (default)
  static const double lg = 24.0;   // Large
  static const double xl = 32.0;   // Extra large
  static const double xxl = 48.0;  // Double extra large

  // Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
}

// ============================================================================
// 🔤 TYPOGRAPHY (Text Styles)
// ============================================================================
class AppTypography {
  static const String fontFamily = 'Roboto';

  // Headings
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  // Captions
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.5,
  );

  // Code/Mono (for Arduino code display)
  static const TextStyle codeMono = TextStyle(
    fontFamily: 'Courier New',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}

// ============================================================================
// 🎨 THEME CONFIGURATION
// ============================================================================
class AppTheme {
  /// Dark theme optimized for a tech/Arduino app
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Primary colors
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.primaryDark,
      
      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryPurple,
        tertiary: AppColors.primaryCyan,
        surface: AppColors.darkGrey,
        error: AppColors.accentRed,
        brightness: Brightness.dark,
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.heading2.copyWith(
          color: AppColors.white,
        ),
        iconTheme: const IconThemeData(color: AppColors.primaryCyan),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          elevation: 8,
        ),
      ),

      // Text field theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.primaryCyan),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(
            color: AppColors.mediumGrey,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(
            color: AppColors.primaryCyan,
            width: 2,
          ),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.mediumGrey,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.mediumGrey,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.darkGrey,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkGrey,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
    );
  }

  /// Light theme (optional - for future use)
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.lightGrey,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryPurple,
        error: AppColors.accentRed,
      ),
    );
  }
}

// ============================================================================
// 🎪 CUSTOM WIDGETS (Reusable Components)
// ============================================================================

/// Modern gradient button with cool effects
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.primaryCyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: widget.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.white.withOpacity(0.8),
                    ),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.label,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Cool card with gradient border effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color gradientStart;
  final Color gradientEnd;
  final EdgeInsets padding;

  const GlassCard({
    super.key,
    required this.child,
    this.gradientStart = AppColors.primaryBlue,
    this.gradientEnd = AppColors.primaryPurple,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primaryCyan.withOpacity(0.3),
          width: 1.5,
        ),
        gradient: LinearGradient(
          colors: [
            AppColors.darkGrey.withOpacity(0.8),
            AppColors.darkGrey.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Animated badge for blocks and status indicators
class AnimatedBadge extends StatefulWidget {
  final String label;
  final Color color;

  const AnimatedBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  State<AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            border: Border.all(
              color: widget.color.withOpacity(0.3 + (_controller.value * 0.3)),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            widget.label,
            style: AppTypography.bodySmall.copyWith(
              color: widget.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
