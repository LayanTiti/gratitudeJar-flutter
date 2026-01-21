import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home.dart';
import 'dashboard.dart';
import 'reminder.dart';
import 'profile.dart';

class MainShell extends StatefulWidget {
   MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  
  final Color primary =  Color(0xFF0A6167);
  final Color accent =  Color(0xFFF08A5D);
  final Color bgColor =  Color.fromARGB(255, 205, 229, 229);
  final Color borderGrey =  Color(0xFFE0E0E0);

  int _index = 0;

  //Pages
  late final List<Widget> _pages = [
    HomeScreen(),
    DashboardScreen(),
    ReminderScreen(),
    ProfileScreen(),
  ];

  // page header title 
  final List<String> _pageTitles = [
    'Home',
    'Weekly Dashboard',
    'Positive Reminder',
    'Profile',
  ];

  final List<IconData> _pageIcons =  [
    Icons.home_rounded,
    Icons.insights_rounded,
    Icons.notifications_active_rounded,
    Icons.person_rounded,
  ];

  // Bottom items 
  final List<_NavItem> _items =  [
    _NavItem(label: 'Home', icon: Icons.home_rounded),
    _NavItem(label: 'Dashboard', icon: Icons.insights_rounded),
    _NavItem(label: 'Reminder', icon: Icons.notifications_active_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_rounded),
  ];

  void _go(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  // Logout  
  Future<void> _showLogoutDialog() async {
    Future<void> logout() async {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:  EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderGrey),
            ),
            padding:  EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout, color: accent, size: 46),
                 SizedBox(height: 10),
                Text(
                  'Log out?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
                 SizedBox(height: 8),
                 Text(
                  'Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                 SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding:  EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                     SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // second appbar
  Widget _pageHeader() {
    return Container(
      width: double.infinity,
      color: primary,
      padding:  EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Icon(
              _pageIcons[_index],
              color: Colors.white,
              size: 18,
            ),
          ),
           SizedBox(width: 10),
          Text(
            _pageTitles[_index],
            style:  TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // Main AppBar 
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.18),
              child: Image.asset(
                'images/logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
             SizedBox(width: 10),
             Text(
              'Gratitude Jar',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _showLogoutDialog,
            icon:  Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),

      // Body Header 
      body: Column(
        children: [
          _pageHeader(), 
          Expanded(
            child: IndexedStack(
              index: _index,
              children: _pages,
            ),
          ),
        ],
      ),

      // Bottom bar
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color:  Color(0xFFF7F9F9),
            border: Border(top: BorderSide(color: borderGrey)),
          ),
          padding:  EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == _index;

              return Expanded(
                child: _BottomNavItem(
                  label: item.label,
                  icon: item.icon,
                  active: active,
                  primary: primary,
                  onTap: () => _go(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// Model 
class _NavItem {
  final String label;
  final IconData icon;
   _NavItem({required this.label, required this.icon});
}

// Bottom item
class _BottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color primary;
  final VoidCallback onTap;

   _BottomNavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : primary;

    return LayoutBuilder(
      builder: (context, c) {
        
        final double fontSize = c.maxWidth < 85 ? 10.5 : 12;

        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration:  Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 52,
            padding:  EdgeInsets.symmetric(horizontal: 6, vertical: 5), 
            decoration: BoxDecoration(
              color: active ? primary : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: fg),
                 SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w900,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
