import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.padding,
  });

  final String title;
  final Widget child;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFF8FBFF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1DEEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x17112F4D),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x0A0D766E),
            blurRadius: 24,
            offset: Offset(-8, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0xFF0D766E), Color(0xFF2E8DE6)],
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF314B68),
                      height: 1.2,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE5EEF8),
            ),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: child,
          ),
        ],
      ),
    );
  }
}
