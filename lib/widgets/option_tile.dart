import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  final String option;
  final bool isSelected;
  final bool isCorrect;
  final bool isIncorrect;
  final bool isDisabled;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isCorrect,
    required this.isIncorrect,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _getBorderColor(context),
            width: _getBorderWidth(),
          ),
          borderRadius: BorderRadius.circular(8),
          color: _getBackgroundColor(context),
        ),
        child: Row(
          children: [
            _buildLeadingIcon(context),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: _getTextColor(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor(BuildContext context) {
    if (isCorrect) return Colors.green;
    if (isIncorrect) return Colors.red;
    if (isSelected) return Theme.of(context).colorScheme.primary;
    return Colors.grey.shade300;
  }

  double _getBorderWidth() {
    if (isCorrect || isIncorrect || isSelected) return 2;
    return 1;
  }

  Color _getBackgroundColor(BuildContext context) {
    if (isCorrect) return Colors.green.shade50;
    if (isIncorrect) return Colors.red.shade50;
    if (isSelected) return Theme.of(context).colorScheme.primaryContainer;
    return Colors.transparent;
  }

  Color _getTextColor(BuildContext context) {
    if (isCorrect) return Colors.green.shade900;
    if (isIncorrect) return Colors.red.shade900;
    if (isSelected) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  Widget _buildLeadingIcon(BuildContext context) {
    if (isCorrect) {
      return Icon(Icons.check_circle, color: Colors.green);
    }
    if (isIncorrect) {
      return Icon(Icons.cancel, color: Colors.red);
    }
    if (isSelected) {
      return Icon(
        Icons.radio_button_checked,
        color: Theme.of(context).colorScheme.primary,
      );
    }
    return Icon(Icons.radio_button_unchecked, color: Colors.grey);
  }
}
