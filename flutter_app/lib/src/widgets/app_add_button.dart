import 'package:flutter/material.dart';

class AppAddButtonTokens {
  const AppAddButtonTokens._();

  static const Color background = Color(0xFFEAF3FF);
  static const Color backgroundPressed = Color(0xFFDDEEFF);
  static const Color backgroundDisabled = Color(0xFFF2F5F7);
  static const Color foreground = Color(0xFF2E5F92);
  static const Color foregroundDisabled = Color(0xFF9AAAB8);
  static const Color border = Color(0xFFC8DCF4);
  static const Color borderPressed = Color(0xFFB5CCE8);
  static const Color iconChip = Color(0x1F2E5F92);
  static const Color shadow = Color(0x224975A9);
}

ButtonStyle _buildAddButtonStyle({
  required double borderRadius,
  required Size minSize,
  Size? maxSize,
  required EdgeInsetsGeometry padding,
  Color? backgroundColor,
  Color? backgroundPressedColor,
  Color? backgroundDisabledColor,
  Color? foregroundColor,
  Color? foregroundDisabledColor,
  Color? borderColor,
  Color? borderPressedColor,
  Color? shadowColor,
  Color? overlayPressedColor,
  Color? overlayHoverColor,
}) {
  final resolvedBackground = backgroundColor ?? AppAddButtonTokens.background;
  final resolvedBackgroundPressed =
      backgroundPressedColor ?? AppAddButtonTokens.backgroundPressed;
  final resolvedBackgroundDisabled =
      backgroundDisabledColor ?? AppAddButtonTokens.backgroundDisabled;
  final resolvedForeground = foregroundColor ?? AppAddButtonTokens.foreground;
  final resolvedForegroundDisabled =
      foregroundDisabledColor ?? AppAddButtonTokens.foregroundDisabled;
  final resolvedBorder = borderColor ?? AppAddButtonTokens.border;
  final resolvedBorderPressed =
      borderPressedColor ?? AppAddButtonTokens.borderPressed;
  final resolvedShadow = shadowColor ?? AppAddButtonTokens.shadow;
  final resolvedOverlayPressed = overlayPressedColor ?? const Color(0x1416645D);
  final resolvedOverlayHover = overlayHoverColor ?? const Color(0x0D16645D);

  return ButtonStyle(
    minimumSize: WidgetStatePropertyAll<Size>(minSize),
    maximumSize: maxSize == null ? null : WidgetStatePropertyAll<Size>(maxSize),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(padding),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    elevation: WidgetStateProperty.resolveWith<double>((states) {
      if (states.contains(WidgetState.disabled)) return 0;
      if (states.contains(WidgetState.pressed)) return 0.3;
      return 1.6;
    }),
    shadowColor: WidgetStatePropertyAll<Color>(resolvedShadow),
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return resolvedBackgroundDisabled;
      }
      if (states.contains(WidgetState.pressed)) {
        return resolvedBackgroundPressed;
      }
      return resolvedBackground;
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return resolvedForegroundDisabled;
      }
      return resolvedForeground;
    }),
    side: WidgetStateProperty.resolveWith<BorderSide>((states) {
      if (states.contains(WidgetState.pressed)) {
        return BorderSide(color: resolvedBorderPressed);
      }
      return BorderSide(color: resolvedBorder);
    }),
    shape: WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return resolvedOverlayPressed;
      }
      if (states.contains(WidgetState.hovered)) {
        return resolvedOverlayHover;
      }
      return null;
    }),
  );
}

class AppToneIconButton extends StatelessWidget {
  const AppToneIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 38,
    this.iconSize = 20,
    this.borderRadius = 11,
    this.backgroundColor,
    this.backgroundPressedColor,
    this.backgroundDisabledColor,
    this.foregroundColor,
    this.foregroundDisabledColor,
    this.borderColor,
    this.borderPressedColor,
    this.shadowColor,
    this.overlayPressedColor,
    this.overlayHoverColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? backgroundPressedColor;
  final Color? backgroundDisabledColor;
  final Color? foregroundColor;
  final Color? foregroundDisabledColor;
  final Color? borderColor;
  final Color? borderPressedColor;
  final Color? shadowColor;
  final Color? overlayPressedColor;
  final Color? overlayHoverColor;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: _buildAddButtonStyle(
        borderRadius: borderRadius,
        minSize: Size(size, size),
        maxSize: Size(size, size),
        padding: EdgeInsets.zero,
        backgroundColor: backgroundColor,
        backgroundPressedColor: backgroundPressedColor,
        backgroundDisabledColor: backgroundDisabledColor,
        foregroundColor: foregroundColor,
        foregroundDisabledColor: foregroundDisabledColor,
        borderColor: borderColor,
        borderPressedColor: borderPressedColor,
        shadowColor: shadowColor,
        overlayPressedColor: overlayPressedColor,
        overlayHoverColor: overlayHoverColor,
      ),
      child: Icon(icon, size: iconSize),
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return button;
    }
    return Tooltip(
      message: tooltip,
      child: button,
    );
  }
}

class AppAddIconButton extends StatelessWidget {
  const AppAddIconButton({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.size = 38,
    this.iconSize = 20,
    this.borderRadius = 11,
  });

  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppToneIconButton(
      icon: Icons.add_rounded,
      onPressed: onPressed,
      tooltip: tooltip,
      size: size,
      iconSize: iconSize,
      borderRadius: borderRadius,
    );
  }
}

class AppAddTextButton extends StatelessWidget {
  const AppAddTextButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.iconSize = 16,
    this.height = 34,
    this.borderRadius = 10,
  });

  final VoidCallback? onPressed;
  final String label;
  final double iconSize;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: _buildAddButtonStyle(
        borderRadius: borderRadius,
        minSize: Size(0, height),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Container(
        width: iconSize + 10,
        height: iconSize + 10,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppAddButtonTokens.iconChip,
        ),
        child: Icon(Icons.add_rounded, size: iconSize),
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
