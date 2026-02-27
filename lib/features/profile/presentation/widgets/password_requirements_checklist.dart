import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/utils/password_utils.dart';

/// Password requirements checklist widget
class PasswordRequirementsChecklist extends StatelessWidget {
  final String password;

  const PasswordRequirementsChecklist({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final requirements = PasswordUtils.checkRequirements(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password must contain:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        _RequirementItem(
          met: requirements.hasMinLength,
          text: 'At least 8 characters',
        ),
        _RequirementItem(
          met: requirements.hasUppercase,
          text: 'One uppercase letter',
        ),
        _RequirementItem(
          met: requirements.hasLowercase,
          text: 'One lowercase letter',
        ),
        _RequirementItem(
          met: requirements.hasNumber,
          text: 'One number',
        ),
        _RequirementItem(
          met: requirements.hasSpecialChar,
          text: 'One special character',
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final bool met;
  final String text;

  const _RequirementItem({
    required this.met,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Ionicons.checkmark_circle : Ionicons.close_circle,
            size: 16,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: met ? Colors.green : Colors.grey,
                  decoration: met ? null : TextDecoration.none,
                ),
          ),
        ],
      ),
    );
  }
}

