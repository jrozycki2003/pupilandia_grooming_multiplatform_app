/// \file user_avatar.dart
/// \brief Widget avatara użytkownika
/// 
/// Wyświetla zdjęcie profilowe użytkownika lub domyślny avatar.

import 'package:flutter/material.dart';

/// \class UserAvatar
/// \brief Widget okrągłego avatara użytkownika
class UserAvatar extends StatelessWidget {
  final String? imageUrl; ///< URL zdjęcia profilowego
  final double size; ///< Rozmiar avatara w pikselach

  const UserAvatar({super.key, required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final defaultAvatar = Image.asset(
      'images/profile.png',
      height: size,
      width: size,
      fit: BoxFit.cover,
    );

    return ClipOval(
      child: (imageUrl?.isNotEmpty ?? false)
          ? Image.network(
              imageUrl!,
              height: size,
              width: size,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheWidth: (size * 2).round(),
              cacheHeight: (size * 2).round(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: size,
                  width: size,
                  color: Colors.grey.shade200,
                );
              },
              errorBuilder: (_, __, ___) => defaultAvatar,
            )
          : defaultAvatar,
    );
  }
}
