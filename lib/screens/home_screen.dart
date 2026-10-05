import 'package:flutter/material.dart';
import 'package:invitacion_app/screens/check/check_screen.dart';
import 'package:invitacion_app/screens/list/list_screen.dart';


class HomeScreen extends StatefulWidget {
	const HomeScreen({super.key});
	@override
	State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
	int _index = 0;
	final _pages = const [CheckScreen(), ListScreen()];

	@override
	Widget build(BuildContext context) {
		return Scaffold( 
			body: _pages[_index],
			bottomNavigationBar: NavigationBar(
				selectedIndex: _index,
				onDestinationSelected: (i) => setState(() => _index = i),
				destinations: const [
					NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Escanear'),
					NavigationDestination(icon: Icon(Icons.list), label: 'Lista'),
				],
			),
		);
	}
}