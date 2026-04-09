import 'package:flutter/material.dart';

class EditorDialog extends StatelessWidget {
  const EditorDialog({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.subtitle,
    this.icon = Icons.edit_note_rounded,
    this.maxWidth = 560,
    this.bodyPadding = const EdgeInsets.fromLTRB(16, 14, 16, 12),
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final EdgeInsets bodyPadding;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: media.size.height * 0.88,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF5F9FF)],
            ),
            border: Border.all(color: const Color(0xFFDCE8F7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x240F2847),
                blurRadius: 20,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(
                  title: title,
                  subtitle: subtitle,
                  icon: icon,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: bodyPadding,
                    child: child,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xF9FBFDFF),
                    border: Border(
                      top: BorderSide(color: Color(0xFFD8E3F2)),
                    ),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: actions,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditorPanel extends StatelessWidget {
  const EditorPanel({
    super.key,
    required this.child,
    this.title,
    this.description,
  });

  final Widget child;
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE8F6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title!,
                style: const TextStyle(
                  color: Color(0xFF244161),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            if (description != null) ...[
              const SizedBox(height: 3),
              Text(
                description!,
                style: const TextStyle(
                  color: Color(0xFF67809E),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
            if (title != null || description != null)
              const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFEFF6FF), Color(0xFFE3FFF8)],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFD8E5F4)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF0D766E).withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 19,
              color: const Color(0xFF0D766E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E334F),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFF5E7592),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
