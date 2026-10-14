import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class ModeratorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const ModeratorAppBar({
    super.key,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Logo
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Peer',
                  style: TextStyle(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'LearHub',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Explore Button
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.explore_outlined,
                    color: AppColors.primaryTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Explore',
                    style: TextStyle(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.primaryTeal,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Profile Icon
          GestureDetector(
            onTap: () {
              context.push('/profile');
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 1),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          color: Colors.black87,
                          size: 24,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.black87,
                        size: 24,
                      ),
              ),
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
