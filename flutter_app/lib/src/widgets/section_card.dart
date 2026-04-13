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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD3E0EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141B3756),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x0C1B3756),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFF2F7FF),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE1EAF6)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF425B78),
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
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
