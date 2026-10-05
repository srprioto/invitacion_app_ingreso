import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ListScreen extends StatefulWidget {
	const ListScreen({super.key});
	@override
	State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
	late final File _file;
	List<Map<String, dynamic>> _data = [];
	bool _loading = true;
	final Set<int> _editing = {};
	final TextEditingController _searchController = TextEditingController();
	String _searchQuery = '';

	@override
	void initState() {
		super.initState();
		_init();
		_searchController.addListener(() {
			setState(() => _searchQuery = _searchController.text.toLowerCase());
		});
	}

	@override
	void dispose() {
		_searchController.dispose();
		super.dispose();
	}

	Future<void> _init() async {
		_file = await _resolveFile();
		if (!await _file.exists()) {
			final raw = await DefaultAssetBundle.of(context)
					.loadString('lib/data/invitados.json');
			await _file.writeAsString(raw);
		}
		await _load();
	}

	Future<File> _resolveFile() async {
		if (kDebugMode) {
			final f = File('lib/data/invitados.json');
			if (await f.exists()) return f;
		}
		final exeDir = File(Platform.resolvedExecutable).parent.path;
		return File('$exeDir/invitados.json');
	}

	Future<void> _load() async {
		final raw = await _file.readAsString();
		setState(() {
			_data = List<Map<String, dynamic>>.from(jsonDecode(raw));
			_loading = false;
		});
	}

	Future<void> _save() async {
		await _file.writeAsString(jsonEncode(_data));
	}

	Future<void> _export() async {
		await _save();

		final jsonStr = const JsonEncoder.withIndent('  ').convert(_data);
		final bytes = utf8.encode(jsonStr);

		final Uri? outputUri = await FilePicker.saveFile(
			dialogTitle: 'Guardar invitados.json',
			fileName: 'invitados_export.json',
			bytes: bytes,
			type: FileType.custom,
			allowedExtensions: ['json'],
		);

		if (outputUri == null) return;

		if (!mounted) return;
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text('Exportado en: ${outputUri.path}')),
		);
	}

	String _formatNombre(String s) {
		return s.trim().toUpperCase();
	}

	Future<void> _toggleEdit(int i) async {
		if (_editing.contains(i)) {
			await _save();
			setState(() => _editing.remove(i));
		} else {
			setState(() => _editing.add(i));
		}
	}

	List<Map<String, dynamic>> get _filteredData {
		if (_searchQuery.isEmpty) return _data;
		return _data.where((item) {
			final nombre = (item['nombre'] ?? '').toString().toLowerCase();
			final codigo = (item['codigo'] ?? '').toString().toLowerCase();
			final dni = (item['DNI'] ?? '').toString().toLowerCase();
			final telefono = (item['telefono'] ?? '').toString().toLowerCase();
			return nombre.contains(_searchQuery) ||
					codigo.contains(_searchQuery) ||
					dni.contains(_searchQuery) ||
					telefono.contains(_searchQuery);
		}).toList();
	}

	@override
	Widget build(BuildContext context) {
		if (_loading) {
			return const Scaffold(body: Center(child: CircularProgressIndicator()));
		}
		final filtered = _filteredData;
		return Scaffold(
			body: Column(
				children: [
					Padding(
						padding: const EdgeInsets.all(8.0),
						child: Row(
							children: [
								Expanded(
									child: TextField(
										controller: _searchController,
										decoration: InputDecoration(
											hintText: 'Buscar por nombre, código, DNI o teléfono...',
											prefixIcon: const Icon(Icons.search),
											suffixIcon: _searchQuery.isNotEmpty
													? IconButton(
															icon: const Icon(Icons.clear),
															onPressed: () => _searchController.clear(),
														)
													: null,
											border: const OutlineInputBorder(),
											isDense: true,
										),
									),
								),
								const SizedBox(width: 8),
								IconButton(
									icon: const Icon(Icons.download),
									tooltip: 'Exportar',
									onPressed: _export,
								),
							],
						),
					),
					Expanded(
						child: Scrollbar(
							thumbVisibility: true,
							child: SingleChildScrollView(
								scrollDirection: Axis.horizontal,
								child: SingleChildScrollView(
									primary: true,
									child: DataTable(
										columns: const [
											DataColumn(label: Text('Nombre')),
											DataColumn(label: Text('Código')),
											DataColumn(label: Text('Teléfono')),
											DataColumn(label: Text('DNI')),
											DataColumn(label: Text('Acceso')),
											DataColumn(label: Text('Pagado')),
											DataColumn(label: Text('Observación')),
											DataColumn(label: Text('')),
										],
										rows: List.generate(filtered.length, (i) {
											final item = filtered[i];
											final originalIndex = _data.indexOf(item);
											final isEditing = _editing.contains(originalIndex);
											return DataRow(cells: [
												DataCell(Text(_formatNombre(item['nombre'] ?? ''))),
												DataCell(Text(item['codigo'] ?? '')),
												DataCell(Text(item['telefono'] ?? '')),
												DataCell(_field(originalIndex, 'DNI', isEditing, width: 120)),
												DataCell(Switch(
													value: (item['acceso'] ?? 0) == 1,
													onChanged: isEditing
															? (v) => setState(() => _data[originalIndex]['acceso'] = v ? 1 : 0)
															: null,
												)),
												DataCell(Switch(
													value: (item['pagado'] ?? 0) == 1,
													onChanged: isEditing
															? (v) => setState(() => _data[originalIndex]['pagado'] = v ? 1 : 0)
															: null,
												)),
												DataCell(_field(originalIndex, 'observacion', isEditing, width: 200)),
												DataCell(IconButton(
													icon: Icon(isEditing ? Icons.check : Icons.edit),
													onPressed: () => _toggleEdit(originalIndex),
												)),
											]);
										}),
									),
								),
							),
						),
					),
				],
			),
		);
	}

	Widget _field(int i, String key, bool isEditing, {double width = 150}) {
		if (!isEditing) {
			return SizedBox(
				width: width,
				child: Text((_data[i][key] ?? '').toString()),
			);
		}
		return SizedBox(
			width: width,
			child: TextFormField(
				initialValue: (_data[i][key] ?? '').toString(),
				decoration: const InputDecoration(isDense: true),
				onChanged: (v) => _data[i][key] = v,
			),
		);
	}
}