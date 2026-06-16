import 'package:flutter/material.dart';

class AnimatedFab extends StatefulWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onManualTap;

  const AnimatedFab({
    super.key,
    required this.onCameraTap,
    required this.onManualTap,
  });

  @override
  State<AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<AnimatedFab>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isExpanded) ...[
          ScaleTransition(
            scale: _scaleAnimation,
            child: FloatingActionButton.small(
              heroTag: 'scan',
              backgroundColor: theme.colorScheme.secondary,
              onPressed: () {
                _toggle();
                widget.onCameraTap();
              },
              child: const Icon(Icons.camera_alt),
            ),
          ),
          const SizedBox(height: 8),
          ScaleTransition(
            scale: _scaleAnimation,
            child: FloatingActionButton.small(
              heroTag: 'manual',
              backgroundColor: theme.colorScheme.tertiary,
              onPressed: () {
                _toggle();
                widget.onManualTap();
              },
              child: const Icon(Icons.edit),
            ),
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          heroTag: 'main',
          onPressed: _toggle,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 3.14159,
                child: Icon(_isExpanded ? Icons.close : Icons.add),
              );
            },
          ),
        ),
      ],
    );
  }
}
