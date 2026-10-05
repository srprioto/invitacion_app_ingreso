import 'package:flutter/material.dart';
import 'package:invitacion_app/assets/AppTheme.dart';
import 'package:invitacion_app/screens/home_screen.dart';

void main() => runApp(const MyApp()); // Asegúrate de que esta línea existe

class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			debugShowCheckedModeBanner: false,
			title: 'Invitaciones Check',
			theme: appTheme,
			home: const HomeScreen(), // HomeScreen va aquí, no un Scaffold suelto
		);
	}
}