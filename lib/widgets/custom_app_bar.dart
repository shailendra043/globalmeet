import 'package:flutter/material.dart';
import 'circle_button.dart';
import 'custom_tab_bar.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<IconData> icons;
  final int selectedIndex;
  final Function(int) onTap;
  final List<IconData> actions;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.icons,
    required this.selectedIndex,
    required this.onTap,
    this.actions = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 50.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: actions
                      .map((icon) => CircleButton(
                            icon: icon,
                            onPressed: () {},
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          CustomTabBar(
            icons: icons,
            selectedIndex: selectedIndex,
            onTap: onTap,
            isBottomIndicator: true,
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(100.0);
} 