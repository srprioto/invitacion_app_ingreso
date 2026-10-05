import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CheckScreen extends StatefulWidget {
	const CheckScreen({super.key});

	@override
	State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
	late final File _file;
	List<Map<String, dynamic>> _data = [];
	Map<String, dynamic>? _resultado;
	bool _loading = true;
	final TextEditingController _codeController = TextEditingController();

	@override
	void initState() {
		super.initState();
		_init();
	}

	@override
	void dispose() {
		_codeController.dispose();
		super.dispose();
	}

	Future<void> _init() async {
		_file = await _resolveFile();
		if (!await _file.exists()) {
			final raw = await DefaultAssetBundle.of(context)
					.loadString('lib/data/invitados.json');
			await _file.writeAsString(raw);
		}
		final raw = await _file.readAsString();
		setState(() {
			_data = List<Map<String, dynamic>>.from(jsonDecode(raw));
			_loading = false;
		});
	}

	Future<File> _resolveFile() async {
		if (kDebugMode) {
			final f = File('lib/data/invitados.json');
			if (await f.exists()) return f;
		}
		final exeDir = File(Platform.resolvedExecutable).parent.path;
		return File('$exeDir/invitados.json');
	}

	Future<void> _save() async {
		await _file.writeAsString(jsonEncode(_data));
	}

	String _formatNombre(String s) => s.trim().toUpperCase();

	void _buscar() {
		final code = _codeController.text.trim();
		if (code.isEmpty) return;
		final found = _data.firstWhere(
			(e) => (e['codigo'] ?? '').toString() == code,
			orElse: () => {},
		);
		setState(() => _resultado = found.isEmpty ? null : found);
	}

	Future<void> _ingresar() async {
		if (_resultado == null) return;
		final idx = _data.indexOf(_resultado!);
		if (idx == -1) return;
		setState(() {
			_data[idx]['acceso'] = 1;
			_resultado = _data[idx];
		});
		await _save();
	}

	@override
	Widget build(BuildContext context) {
		if (_loading) {
			return const Scaffold(body: Center(child: CircularProgressIndicator()));
		}
		return Scaffold(
			body: Center(
				child: FractionallySizedBox(
					widthFactor: 0.5,
					heightFactor: 1,
					child: Padding(
						padding: const EdgeInsets.all(24.0),
						child: Column(
							children: [
								Row(
									children: [
										IconButton.filled(
											iconSize: 40,
											padding: const EdgeInsets.all(16),
											icon: const Icon(Icons.qr_code_scanner),
											onPressed: () {},
										),
										const SizedBox(width: 12),
										Expanded(
											child: TextField(
												controller: _codeController,
												style: const TextStyle(fontSize: 20),
												decoration: const InputDecoration(
													hintText: 'Código',
													border: OutlineInputBorder(),
													contentPadding: EdgeInsets.symmetric(
														horizontal: 16,
														vertical: 20,
													),
												),
												onSubmitted: (_) => _buscar(),
											),
										),
										const SizedBox(width: 12),
										IconButton.filled(
											iconSize: 40,
											padding: const EdgeInsets.all(16),
											icon: const Icon(Icons.search),
											onPressed: _buscar,
										),
									],
								),
								const SizedBox(height: 32),
								if (_resultado != null)
									Expanded(
										child: SingleChildScrollView(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Text(
														_formatNombre(_resultado!['nombre'] ?? ''),
														style: const TextStyle(
															fontSize: 28,
															fontWeight: FontWeight.bold,
														),
													),
													const SizedBox(height: 16),
													_info('Código', _resultado!['codigo']),
													_info('Teléfono', _resultado!['telefono']),
													_info('DNI', _resultado!['DNI']),
													_info('Pagado', (_resultado!['pagado'] ?? 0) == 1 ? 'Sí' : 'No'),
													_info('Acceso', (_resultado!['acceso'] ?? 0) == 1 ? 'Sí' : 'No'),
													_info('Observación', _resultado!['observacion']),
												],
											),
										),
									)
								else
									const Expanded(
										child: Center(
											child: Text(
												'Sin resultados',
												style: TextStyle(fontSize: 18, color: Colors.grey),
											),
										),
									),
								const SizedBox(height: 16),
								SizedBox(
									width: double.infinity,
									height: 60,
									child: ElevatedButton(
										onPressed: _resultado != null ? _ingresar : null,
										child: const Text(
											'Ingresar',
											style: TextStyle(fontSize: 20),
										),
									),
								),
							],
						),
					),
				),
			),
		);
	}

	Widget _info(String label, dynamic value) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 4),
			child: Row(
				children: [
					SizedBox(
						width: 140,
						child: Text(
							label,
							style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
						),
					),
					Expanded(
						child: Text(
							(value ?? '').toString(),
							style: const TextStyle(fontSize: 16),
						),
					),
				],
			),
		);
	}
}