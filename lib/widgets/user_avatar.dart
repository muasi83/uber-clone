import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular avatar that renders a photo from a URL with a letter-initial
/// fallback when the photo is null, empty, still loading, or fails to load.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
  });

  bool get _hasPhoto => photoUrl != null && photoUrl!.trim().isNotEmpty;

  String get _initial {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  Color get _fallbackColor {
    final seed = displayName.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return AppColors.avatarColors[seed % AppColors.avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPhoto) {
      return _initialAvatar();
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.surfaceVariant,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => _initialAvatar(),
          errorWidget: (context, url, error) => _initialAvatar(),
        ),
      ),
    );
  }

  Widget _initialAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? _fallbackColor,
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: radius * 0.9,
          fontWeight: FontWeight.bold,
          color: foregroundColor ?? Colors.white,
        ),
      ),
    );
  }
}
