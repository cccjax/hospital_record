import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.value,
    required this.label,
    this.icon,
    this.subtitle,
    this.searchKeywords = const <String>[],
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? subtitle;
  final List<String> searchKeywords;
}

class AppDropdownFormField<T> extends FormField<T> {
  AppDropdownFormField({
    super.key,
    required this.items,
    this.selectedValue,
    this.hintText = '请选择',
    this.isEnabled = true,
    this.searchable = false,
    this.searchHintText = '输入关键词搜索',
    this.emptySearchText = '未找到匹配项',
    this.menuMaxHeight = 300,
    this.onChanged,
    super.validator,
    super.autovalidateMode,
  }) : super(
          initialValue: selectedValue,
          builder: (field) {
            final state = field as _AppDropdownFormFieldState<T>;
            return state._buildField();
          },
        );

  final List<AppDropdownOption<T>> items;
  final T? selectedValue;
  final String hintText;
  final bool isEnabled;
  final bool searchable;
  final String searchHintText;
  final String emptySearchText;
  final double menuMaxHeight;
  final ValueChanged<T?>? onChanged;

  @override
  FormFieldState<T> createState() => _AppDropdownFormFieldState<T>();
}

class _AppDropdownFormFieldState<T> extends FormFieldState<T> {
  final GlobalKey _anchorKey = GlobalKey();

  AppDropdownFormField<T> get _widget => widget as AppDropdownFormField<T>;

  @override
  void didUpdateWidget(covariant AppDropdownFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_widget.selectedValue != oldWidget.selectedValue &&
        _widget.selectedValue != value) {
      setValue(_widget.selectedValue);
    }
  }

  @override
  void didChange(T? value) {
    super.didChange(value);
    _widget.onChanged?.call(value);
  }

  Widget _buildField() {
    final selected = _selectedOption;
    final hasError = errorText != null;
    final enabled = _widget.isEnabled && _widget.items.isNotEmpty;

    final borderColor = hasError
        ? const Color(0xFFB63A49)
        : enabled
            ? const Color(0xFFD3E0F1)
            : const Color(0xFFDCE4EF);
    final backgroundColor = enabled ? Colors.white : const Color(0xFFF4F7FB);

    final textStyle = TextStyle(
      color:
          selected == null ? const Color(0xFF8A9CB2) : const Color(0xFF243C56),
      fontSize: 13.5,
      fontWeight: selected == null ? FontWeight.w500 : FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: _anchorKey,
            onTap: enabled ? _openMenu : null,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 42),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selected?.label ?? _widget.hintText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: enabled
                        ? const Color(0xFF5D7490)
                        : const Color(0xFF98A8BB),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 11),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Color(0xFFB63A49),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  AppDropdownOption<T>? get _selectedOption {
    for (final option in _widget.items) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }

  Future<void> _openMenu() async {
    if (_widget.searchable) {
      final selected = await _openSearchPopover();
      if (selected != null) {
        didChange(selected);
      }
      return;
    }
    final anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) {
      return;
    }
    final box = anchorContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) {
      return;
    }

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight =
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay);
    final menuTop = topLeft.dy + box.size.height + 6;
    final position = RelativeRect.fromLTRB(
      topLeft.dx,
      menuTop,
      overlay.size.width - bottomRight.dx,
      overlay.size.height - menuTop,
    );

    final currentValue = value;
    final selected = await showMenu<T>(
      context: context,
      position: position,
      color: const Color(0xFFF8FBFF),
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      constraints: BoxConstraints(
        minWidth: box.size.width,
        maxWidth: box.size.width,
        maxHeight: _widget.menuMaxHeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD6E3F3)),
      ),
      items: _widget.items
          .map(
            (option) => PopupMenuItem<T>(
              value: option.value,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              height: 42,
              child: _PopupRow(
                text: option.label,
                icon: option.icon,
                subtitle: option.subtitle,
                selected: option.value == currentValue,
              ),
            ),
          )
          .toList(),
    );

    if (selected != null) {
      didChange(selected);
    }
  }

  Future<T?> _openSearchPopover() async {
    final anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) {
      return null;
    }
    final box = anchorContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) {
      return null;
    }

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final menuTop = topLeft.dy + box.size.height + 6;
    final preferredWidth = box.size.width.clamp(240.0, 380.0).toDouble();
    final menuLeft = topLeft.dx
        .clamp(12.0, math.max(12.0, overlay.size.width - preferredWidth - 12.0))
        .toDouble();
    final maxHeight = (overlay.size.height - menuTop - 12.0)
        .clamp(160.0, _widget.menuMaxHeight)
        .toDouble();

    final currentValue = value;
    return showDialog<T>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      useSafeArea: false,
      builder: (dialogContext) {
        return _SearchableDropdownPopover<T>(
          items: _widget.items,
          selectedValue: currentValue,
          searchHintText: _widget.searchHintText,
          emptySearchText: _widget.emptySearchText,
          matchesOption: _matchesOption,
          left: menuLeft,
          top: menuTop,
          width: preferredWidth,
          maxHeight: maxHeight,
        );
      },
    );
  }

  bool _matchesOption(AppDropdownOption<T> option, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    final haystacks = <String>[
      option.label,
      option.subtitle ?? '',
      ...option.searchKeywords,
    ];
    for (final text in haystacks) {
      if (text.toLowerCase().contains(normalized)) {
        return true;
      }
    }
    return false;
  }
}

class _SearchableDropdownPopover<T> extends StatefulWidget {
  const _SearchableDropdownPopover({
    required this.items,
    required this.selectedValue,
    required this.searchHintText,
    required this.emptySearchText,
    required this.matchesOption,
    required this.left,
    required this.top,
    required this.width,
    required this.maxHeight,
  });

  final List<AppDropdownOption<T>> items;
  final T? selectedValue;
  final String searchHintText;
  final String emptySearchText;
  final bool Function(AppDropdownOption<T> option, String query) matchesOption;
  final double left;
  final double top;
  final double width;
  final double maxHeight;

  @override
  State<_SearchableDropdownPopover<T>> createState() =>
      _SearchableDropdownPopoverState<T>();
}

class _SearchableDropdownPopoverState<T>
    extends State<_SearchableDropdownPopover<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height - media.viewInsets.bottom - widget.top - 10.0;
    final panelHeight = math.min(
      widget.maxHeight,
      math.max(120.0, availableHeight),
    );
    final maxWidth = math.max(200.0, media.size.width - 24.0);
    final panelWidth = math.min(widget.width, maxWidth);
    final panelLeft = widget.left
        .clamp(12.0, math.max(12.0, media.size.width - panelWidth - 12.0))
        .toDouble();
    final panelTop = widget.top
        .clamp(
          8.0,
          math.max(
            8.0,
            media.size.height - media.viewInsets.bottom - panelHeight,
          ),
        )
        .toDouble();
    final filtered = widget.items
        .where((option) => widget.matchesOption(option, _query))
        .toList();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: panelLeft,
            top: panelTop,
            width: panelWidth,
            child: Material(
              color: const Color(0xFFF8FBFF),
              elevation: 10,
              shadowColor: const Color(0x220B3159),
              surfaceTintColor: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD6E3F3)),
                ),
                child: SizedBox(
                  height: panelHeight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Column(
                      children: [
                        TextField(
                          autofocus: true,
                          onChanged: (value) {
                            setState(() {
                              _query = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: widget.searchHintText,
                            prefixIcon:
                                const Icon(Icons.search_rounded, size: 18),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                                  child: Text(
                                    widget.emptySearchText,
                                    style: const TextStyle(
                                      color: Color(0xFF6F829A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 5),
                                  itemBuilder: (context, index) {
                                    final option = filtered[index];
                                    final selected =
                                        option.value == widget.selectedValue;
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(11),
                                      onTap: () => Navigator.of(context)
                                          .pop(option.value),
                                      child: _PopupRow(
                                        text: option.label,
                                        icon: option.icon,
                                        subtitle: option.subtitle,
                                        selected: selected,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupRow extends StatelessWidget {
  const _PopupRow({
    required this.text,
    required this.selected,
    this.icon,
    this.subtitle,
  });

  final String text;
  final IconData? icon;
  final String? subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF4FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: const Color(0xFF557292)),
              const SizedBox(width: 7),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF23578A)
                          : const Color(0xFF334A64),
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF3B6E9F)
                            : const Color(0xFF6B8098),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Color(0xFF2F659C),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
