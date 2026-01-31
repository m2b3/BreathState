import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final bool hasBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.color,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveBorderColor = isDark 
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.08);

    final effectiveGradientStart = isDark 
        ? (color ?? Colors.white).withOpacity(0.14)
        : (color ?? Colors.white).withOpacity(0.65);

    final effectiveGradientEnd = isDark 
        ? (color ?? Colors.white).withOpacity(0.06)
        : (color ?? Colors.white).withOpacity(0.35);

    final bgOpacity = isDark ? 0.10 : 0.45;

    final shadowColor = isDark 
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.08);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 12,
              spreadRadius: -4,
              offset: const Offset(0, -4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withOpacity(bgOpacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: hasBorder
                  ? Border.all(
                      color: effectiveBorderColor,
                      width: 1.0,
                    )
                  : null,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveGradientStart,
                  effectiveGradientEnd,
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
