import 'dart:math' as math;

import 'package:flutter/material.dart';

typedef PagedCardItemBuilder = Widget Function(BuildContext context, int index);

class PagedCardPageState {
  const PagedCardPageState({
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;
  final int currentPage;
}

class PagedCardPageIndicator extends StatelessWidget {
  const PagedCardPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.backgroundColor = const Color(0xB3FFFFFF),
    this.borderColor = const Color(0xFFD5E2F2),
  });

  final int pageCount;
  final int currentPage;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              for (var i = 0; i < pageCount; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == currentPage ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == currentPage
                        ? const Color(0xFF4A7FB8)
                        : const Color(0xFFC9D8EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class PagedCardGrid extends StatefulWidget {
  const PagedCardGrid({
    super.key,
    required this.itemCount,
    required this.crossAxisCount,
    required this.rowsPerPage,
    required this.itemHeight,
    required this.itemBuilder,
    this.spacing = 10,
    this.runSpacing = 10,
    this.showInlineIndicator = true,
    this.onPageStateChanged,
  });

  final int itemCount;
  final int crossAxisCount;
  final int rowsPerPage;
  final double itemHeight;
  final double spacing;
  final double runSpacing;
  final bool showInlineIndicator;
  final ValueChanged<PagedCardPageState>? onPageStateChanged;
  final PagedCardItemBuilder itemBuilder;

  @override
  State<PagedCardGrid> createState() => _PagedCardGridState();
}

class _PagedCardGridState extends State<PagedCardGrid> {
  late final PageController _pageController;
  int _currentPage = 0;
  PagedCardPageState? _lastState;

  int get _itemsPerPage =>
      math.max(1, widget.crossAxisCount) * math.max(1, widget.rowsPerPage);

  int get _pageCount {
    if (widget.itemCount <= 0) return 0;
    return ((widget.itemCount + _itemsPerPage - 1) / _itemsPerPage).floor();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitPageState();
    });
  }

  @override
  void didUpdateWidget(covariant PagedCardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxPage = math.max(0, _pageCount - 1);
    if (_currentPage > maxPage) {
      _currentPage = maxPage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(_currentPage);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitPageState();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _emitPageState() {
    final maxPage = math.max(0, _pageCount - 1);
    final state = PagedCardPageState(
      pageCount: _pageCount,
      currentPage: _currentPage.clamp(0, maxPage),
    );
    if (_lastState?.pageCount == state.pageCount &&
        _lastState?.currentPage == state.currentPage) {
      return;
    }
    _lastState = state;
    widget.onPageStateChanged?.call(state);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = math.max(1, widget.crossAxisCount);
        final rowsPerPage = math.max(1, widget.rowsPerPage);
        final itemWidth =
            (constraints.maxWidth - widget.spacing * (crossAxisCount - 1)) /
                crossAxisCount;
        final pageHeight = rowsPerPage * widget.itemHeight +
            widget.runSpacing * (rowsPerPage - 1);
        final pageCount = _pageCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: pageHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: pageCount,
                onPageChanged: (page) {
                  if (page == _currentPage) return;
                  setState(() {
                    _currentPage = page;
                  });
                  _emitPageState();
                },
                itemBuilder: (context, pageIndex) {
                  final start = pageIndex * _itemsPerPage;
                  final end = math.min(widget.itemCount, start + _itemsPerPage);
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Wrap(
                      spacing: widget.spacing,
                      runSpacing: widget.runSpacing,
                      children: [
                        for (var index = start; index < end; index++)
                          SizedBox(
                            width: itemWidth,
                            height: widget.itemHeight,
                            child: widget.itemBuilder(context, index),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (pageCount > 1 && widget.showInlineIndicator) ...[
              const SizedBox(height: 8),
              PagedCardPageIndicator(
                pageCount: pageCount,
                currentPage: _currentPage,
                backgroundColor: const Color(0xF2FFFFFF),
                borderColor: const Color(0xFFD5E2F2),
              ),
            ],
          ],
        );
      },
    );
  }
}
