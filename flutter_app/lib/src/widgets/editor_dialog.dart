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
    this.maxHeightFactor = 0.88,
    this.insetPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    this.bodyPadding = const EdgeInsets.fromLTRB(18, 16, 18, 14),
    this.scrollableBody = true,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final double maxHeightFactor;
  final EdgeInsets insetPadding;
  final EdgeInsets bodyPadding;
  final bool scrollableBody;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeHeightFactor = maxHeightFactor.clamp(0.5, 1.0).toDouble();
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: insetPadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: media.size.height * safeHeightFactor,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFF6FAFF),
                Color(0xFFEFF8F6),
              ],
            ),
            border: Border.all(color: const Color(0xFFCFE0F2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x260E263F),
                blurRadius: 28,
                offset: Offset(0, 18),
              ),
              BoxShadow(
                color: Color(0x120E766E),
                blurRadius: 40,
                offset: Offset(-12, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(
                  title: title,
                  subtitle: subtitle,
                  icon: icon,
                ),
                if (scrollableBody)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: bodyPadding,
                      child: child,
                    ),
                  )
                else
                  Expanded(
                    child: Padding(
                      padding: bodyPadding,
                      child: child,
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 11, 16, 15),
                  decoration: const BoxDecoration(
                    color: Color(0xF6FFFFFF),
                    border: Border(
                      top: BorderSide(color: Color(0xFFD4E3F3)),
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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE7F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D133B5F),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF7FBFF),
            Color(0xFFEAF8F7),
            Color(0xFFEAF2FF),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFD8E5F4)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF0D766E), Color(0xFF2E8DE6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D766E).withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 19,
              color: Colors.white,
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
