import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/disruption_alert_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_3d_screen.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SafarApp());
}

class SafarApp extends StatelessWidget {
  final bool showSplash;

  const SafarApp({super.key, this.showSplash = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAFAR - Chennai Commuter Transit',
      debugShowCheckedModeBanner: false,
      theme: SafarTheme.lightTheme,
      home: showSplash ? const Splash3DScreen() : const SafarMainContainer(),
    );
  }
}

class SafarMainContainer extends StatefulWidget {
  const SafarMainContainer({super.key});

  @override
  State<SafarMainContainer> createState() => _SafarMainContainerState();
}

class _SafarMainContainerState extends State<SafarMainContainer> {
  int _currentTabIndex = 0;

  final List<Widget> _tabs = [
    const HomeScreen(),
    const DisruptionAlertScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentTabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentTabIndex != 0) {
          setState(() => _currentTabIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: SafarTokens.background,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            color: SafarTokens.background,
            child: IndexedStack(index: _currentTabIndex, children: _tabs),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: SafarTokens.deepCharcoal.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: _currentTabIndex,
              onDestinationSelected: _onTabTapped,
              backgroundColor: Colors.white,
              indicatorColor: SafarTokens.softMint,
              elevation: 0,
              height: 64,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.commute_outlined),
                  selectedIcon: Icon(
                    Icons.commute_rounded,
                    color: SafarTokens.transitGreen,
                  ),
                  label: 'Commute',
                ),
                NavigationDestination(
                  icon: Icon(Icons.warning_amber_rounded),
                  selectedIcon: Icon(
                    Icons.warning_rounded,
                    color: SafarTokens.alertAmber,
                  ),
                  label: 'Alerts',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
