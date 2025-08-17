import 'package:flutter/material.dart';

/// Widget mejorado para botón de join/leave con estados de loading
class JoinLeaveButton extends StatefulWidget {
  final bool isJoined;
  final bool isLoading;
  final VoidCallback onPressed;
  final String? loadingText;
  final ButtonStyle? style;
  final bool isCompact;

  const JoinLeaveButton({
    super.key,
    required this.isJoined,
    required this.onPressed,
    this.isLoading = false,
    this.loadingText,
    this.style,
    this.isCompact = false,
  });

  @override
  State<JoinLeaveButton> createState() => _JoinLeaveButtonState();
}

class _JoinLeaveButtonState extends State<JoinLeaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isCompact) {
      return _buildCompactButton(theme);
    }

    return _buildFullButton(theme);
  }

  Widget _buildCompactButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 80,
            height: 32,
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: widget.isJoined
                  ? theme.colorScheme.secondaryContainer
                  : theme.colorScheme.primary,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.isLoading ? null : _handleTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: widget.isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isJoined
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isJoined ? Icons.check : Icons.add,
                              size: 14,
                              color: widget.isJoined
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.onPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.isJoined ? 'Unido' : 'Unirse',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.isJoined
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: widget.isLoading ? null : _handleTap,
              style:
                  widget.style ??
                  FilledButton.styleFrom(
                    backgroundColor: widget.isJoined
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.primary,
                    foregroundColor: widget.isJoined
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onPrimary,
                    disabledBackgroundColor: theme.colorScheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
              icon: widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Icon(
                      widget.isJoined ? Icons.check_circle : Icons.add_circle,
                      size: 20,
                    ),
              label: Text(
                widget.isLoading
                    ? (widget.loadingText ?? 'Procesando...')
                    : (widget.isJoined
                          ? 'Unido a la comunidad'
                          : 'Unirse a la comunidad'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
