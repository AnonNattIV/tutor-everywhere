import 'package:flutter/material.dart';
import 'package:tutoreverywhere_frontend/pages/tutor/profile.dart';
import '../all/chat.dart';

class TutorHomePage extends StatefulWidget {
  const TutorHomePage({super.key});

  @override
  State<TutorHomePage> createState() => _TutorHomePageState();
}

class _TutorHomePageState extends State<TutorHomePage> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final List<NavigationDestination> destinations = [
      NavigationDestination(
        selectedIcon: Icon(Icons.chat_bubble),
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Chat',
      ),
      NavigationDestination(
        selectedIcon: Icon(Icons.person),
        icon: Icon(Icons.person_outline),
        label: 'Profile',
      ),
      NavigationDestination(
        selectedIcon: Icon(Icons.calendar_month),
        icon: Icon(Icons.calendar_month_outlined),
        label: 'Schedule',
      ),
    ];

    void _showLogoutDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Logout"),
            content: Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Cancel
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // TODO: Clear auth state (Provider/SharedPrefs)
                  // Navigate to Login and clear stack
                  // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginPage()), (route) => false);
                  print("User Logged Out");
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text("Logout"),
              ),
            ],
          );
        },
      );
    }

    void _onMenuOptionSelected(String value) {
      switch (value) {
        case 'settings':
          // Navigate to Settings Page
          // Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage()));
          print("Navigate to Settings");
          break;
        case 'logout':
          // Show confirmation dialog before logging out
          _showLogoutDialog();
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(destinations[currentPageIndex].label),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            onSelected: _onMenuOptionSelected,
            icon: Icon(Icons.more_vert),
            color: Colors.white,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: "settings",
                child: Row(
                  children: [
                    Icon(Icons.settings, color: theme.primaryColor, size: 20),
                    SizedBox(width: 12),
                    Text("Settings"),
                  ],
                )
              ),

              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text("Logout", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.transparent,
        selectedIndex: currentPageIndex,
        destinations: destinations
      ),
      body: <Widget>[
        ChatPage(),
        ProfilePage(),
        Center(child: Text("Schedule")),
      ][currentPageIndex]
    );
  } 
}