import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'raw_printer.dart';

class CheckScreen extends StatefulWidget {
	const CheckScreen({super.key});

	@override
	State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
	late final File _file;
	late final File _correlFile;
	List<Map<String, dynamic>> _data = [];
	List<Map<String, dynamic>> _correlativos = [];
	Map<String, dynamic>? _resultado;
	Map<String, dynamic>? _correlExistente;
	bool _loading = true;
	final TextEditingController _codeController = TextEditingController();

	// ========== Impresora USB Zebra ZD230 ==========
	// Si es null, se autodetecta. Si falla, pon aquí el nombre exacto
	// que muestra Get-Printer, ej: 'ZDesigner ZD230-203dpi ZPL'
	static const String? PRINTER_NAME = null;
	String? _printerCache;

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
		_correlFile = await _resolveCorrelFile();

		if (!await _file.exists()) {
			final raw = await DefaultAssetBundle.of(context)
					.loadString('lib/data/invitados.json');
			await _file.writeAsString(raw);
		}
		final raw = await _file.readAsString();

		if (!await _correlFile.exists() ||
				(await _correlFile.readAsString()).trim().isEmpty) {
			await _correlFile.writeAsString('[]');
		}
		final correlRaw = await _correlFile.readAsString();
		List<Map<String, dynamic>> correlList = [];
		try {
			final decoded = jsonDecode(correlRaw);
			if (decoded is List) {
				correlList = List<Map<String, dynamic>>.from(decoded);
			}
		} catch (e) {
			debugPrint('correl.json corrupto, reiniciando: $e');
			await _correlFile.writeAsString('[]');
		}

		setState(() {
			_data = List<Map<String, dynamic>>.from(jsonDecode(raw));
			_correlativos = correlList;
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

	Future<File> _resolveCorrelFile() async {
		if (kDebugMode) {
			final f = File('lib/data/correl.json');
			if (await f.exists()) return f;
		}
		final exeDir = File(Platform.resolvedExecutable).parent.path;
		return File('$exeDir/correl.json');
	}

	Future<void> _save() async {
		await _file.writeAsString(jsonEncode(_data));
	}

	Future<void> _saveCorrel() async {
		final tmp = File('${_correlFile.path}.tmp');
		await tmp.writeAsString(jsonEncode(_correlativos));
		await tmp.rename(_correlFile.path);
	}

	String _formatNombre(String s) => s.trim().toUpperCase();

	int get _ultimoCorrelativo {
		if (_correlativos.isEmpty) return 0;
		return _correlativos
				.map((e) => (e['correlativo'] ?? 0) as int)
				.reduce((a, b) => a > b ? a : b);
	}

	void _buscar() {
		final code = _codeController.text.trim();
		if (code.isEmpty) return;

		final found = _data.firstWhere(
			(e) =>
					(e['codigo'] ?? '').toString() == code ||
					(e['DNI'] ?? '').toString() == code,
			orElse: () => {},
		);

		Map<String, dynamic>? correlFound;
		if (found.isNotEmpty) {
			final codigo = (found['codigo'] ?? '').toString();
			correlFound = _correlativos.firstWhere(
				(e) => (e['codigo'] ?? '').toString() == codigo,
				orElse: () => {},
			);
			if (correlFound.isEmpty) correlFound = null;
		}

		setState(() {
			_resultado = found.isEmpty ? null : found;
			_correlExistente = correlFound;
		});
	}

	Future<void> _ingresar() async {
		if (_resultado == null) return;
		final idx = _data.indexOf(_resultado!);
		if (idx == -1) return;

		final dataParaImprimir = Map<String, dynamic>.from(_resultado!);
		final codigo = (_resultado!['codigo'] ?? '').toString();

		final nuevoCorrel = {
			'correlativo': _ultimoCorrelativo + 1,
			'codigo': codigo,
			'DNI': (_resultado!['DNI'] ?? '').toString(),
		};
		_correlativos.add(nuevoCorrel);
		await _saveCorrel();

		setState(() {
			_data[idx]['acceso'] = 1;
		});
		await _save();

		final nombre = _formatNombre(_resultado!['nombre'] ?? '');
		_codeController.clear();
		setState(() {
			_resultado = null;
			_correlExistente = null;
		});

		if (!mounted) return;
		_mostrarAlerta('Ingreso correcto: $nombre');
		await _imprimirTicket(dataParaImprimir, nuevoCorrel['correlativo'] as int);
	}

	Future<void> _reimprimir() async {
		if (_resultado == null || _correlExistente == null) return;
		final dataParaImprimir = Map<String, dynamic>.from(_resultado!);
		final nro = _correlExistente!['correlativo'] ?? 0;

		_codeController.clear();
		setState(() {
			_resultado = null;
			_correlExistente = null;
		});

		if (!mounted) return;
		_mostrarAlerta('Reimprimiendo ticket Nro. ${nro.toString().padLeft(4, '0')}');
		await _imprimirTicket(dataParaImprimir, nro);
	}

	Future<String> _nombreImpresora() async {
		if (PRINTER_NAME != null) return PRINTER_NAME!;
		if (_printerCache != null) return _printerCache!;
		final detectada = await RawPrinter.detectarZebra();
		if (detectada == null) {
			throw Exception(
					'No se encontró una impresora Zebra instalada en Windows. '
					'Instala el driver ZDesigner o define PRINTER_NAME.');
		}
		_printerCache = detectada;
		return detectada;
	}

	/// ========== Imprimir ticket ZPL (USB, modo RAW) ==========
	Future<void> _imprimirTicket(Map<String, dynamic> invitado, int nroCorrel) async {
		try {
			final nombre = _formatNombre(invitado['nombre'] ?? '');
			final dni = (invitado['DNI'] ?? '').toString();
			final nroTicket = nroCorrel.toString().padLeft(4, '0');

			// Ajustar ^PW y ^LL según el tamaño real de la etiqueta
			final zpl = '^XA\n'
					'^CI28\n'
					'^PW560\n'
					'^LL300\n'
					'^FO30,30^A0N,28,28^FDAlmuerzo de confraternidad^FS\n'
					'^FO30,70^A0N,32,32^FDGERESA CUSCO^FS\n'
					'^FO30,130^A0N,36,36^FD$nombre^FS\n'
					'^FO30,180^A0N,28,28^FDDNI: $dni^FS\n'
					'^FO30,220^A0N,48,48^FDNro. $nroTicket^FS\n'
					'^XZ\n';

			final printer = await _nombreImpresora();
			RawPrinter.enviar(printer, zpl);

			debugPrint('Ticket impreso en "$printer": $nroTicket');
		} catch (e) {
			debugPrint('Error al imprimir: $e');
			if (mounted) {
				_mostrarAlerta('Error al imprimir: $e');
			}
		}
	}

	void _mostrarAlerta(String mensaje) {
		final overlay = Overlay.of(context);
		late OverlayEntry entry;

		entry = OverlayEntry(
			builder: (context) => _AlertaIngreso(
				mensaje: mensaje,
				onDismiss: () => entry.remove(),
			),
		);

		overlay.insert(entry);
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
													hintText: 'Código o DNI',
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
													_info(
														'Pagado',
														(_resultado!['pagado'] ?? 0) == 1 ? 'Sí' : 'No',
													),
													_info(
														'Acceso',
														(_resultado!['acceso'] ?? 0) == 1 ? 'Sí' : 'No',
													),
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
								if (_correlExistente != null)
									SizedBox(
										width: double.infinity,
										height: 60,
										child: ElevatedButton.icon(
											onPressed: _reimprimir,
											icon: const Icon(Icons.print),
											label: Text(
												'Reimprimir Ticket Nro. ${(_correlExistente!['correlativo'] ?? 0).toString().padLeft(4, '0')}',
												style: const TextStyle(fontSize: 18),
											),
										),
									),
								if (_correlExistente != null) const SizedBox(height: 12),
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

class _AlertaIngreso extends StatefulWidget {
	final String mensaje;
	final VoidCallback onDismiss;

	const _AlertaIngreso({
		required this.mensaje,
		required this.onDismiss,
	});

	@override
	State<_AlertaIngreso> createState() => _AlertaIngresoState();
}

class _AlertaIngresoState extends State<_AlertaIngreso>
		with SingleTickerProviderStateMixin {
	late final AnimationController _controller;
	late final Animation<double> _fade;
	late final Animation<Offset> _slide;

	@override
	void initState() {
		super.initState();
		_controller = AnimationController(
			vsync: this,
			duration: const Duration(milliseconds: 300),
		);
		_fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
		_slide = Tween<Offset>(
			begin: const Offset(0, 0.3),
			end: Offset.zero,
		).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

		_controller.forward();

		Future.delayed(const Duration(seconds: 2), () async {
			if (!mounted) return;
			await _controller.reverse();
			if (mounted) widget.onDismiss();
		});
	}

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Positioned(
			right: 24,
			bottom: 24,
			child: Material(
				color: Colors.transparent,
				child: FadeTransition(
					opacity: _fade,
					child: SlideTransition(
						position: _slide,
						child: Container(
							padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
							decoration: BoxDecoration(
								color: Colors.green.shade700,
								borderRadius: BorderRadius.circular(8),
								boxShadow: [
									BoxShadow(
										color: Colors.black.withOpacity(0.2),
										blurRadius: 8,
										offset: const Offset(0, 4),
									),
								],
							),
							child: Row(
								mainAxisSize: MainAxisSize.min,
								children: [
									const Icon(Icons.check_circle, color: Colors.white, size: 20),
									const SizedBox(width: 8),
									ConstrainedBox(
										constraints: const BoxConstraints(maxWidth: 260),
										child: Text(
											widget.mensaje,
											style: const TextStyle(
												color: Colors.white,
												fontSize: 14,
												fontWeight: FontWeight.w500,
											),
										),
									),
								],
							),
						),
					),
				),
			),
		);
	}
}