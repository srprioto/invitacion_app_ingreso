import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

final class _DocInfo1 extends Struct {
	external Pointer<Utf16> pDocName;
	external Pointer<Utf16> pOutputFile;
	external Pointer<Utf16> pDatatype;
}

typedef _OpenPrinterN = Int32 Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer<Void>);
typedef _OpenPrinterD = int Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer<Void>);

typedef _StartDocN = Uint32 Function(IntPtr, Uint32, Pointer<Void>);
typedef _StartDocD = int Function(int, int, Pointer<Void>);

typedef _HandleN = Int32 Function(IntPtr);
typedef _HandleD = int Function(int);

typedef _WriteN = Int32 Function(IntPtr, Pointer<Void>, Uint32, Pointer<Uint32>);
typedef _WriteD = int Function(int, Pointer<Void>, int, Pointer<Uint32>);

class RawPrinter {
	static final DynamicLibrary _lib = DynamicLibrary.open('winspool.drv');

	static final _openPrinter =
			_lib.lookupFunction<_OpenPrinterN, _OpenPrinterD>('OpenPrinterW');
	static final _startDoc =
			_lib.lookupFunction<_StartDocN, _StartDocD>('StartDocPrinterW');
	static final _startPage =
			_lib.lookupFunction<_HandleN, _HandleD>('StartPagePrinter');
	static final _writePrinter =
			_lib.lookupFunction<_WriteN, _WriteD>('WritePrinter');
	static final _endPage =
			_lib.lookupFunction<_HandleN, _HandleD>('EndPagePrinter');
	static final _endDoc =
			_lib.lookupFunction<_HandleN, _HandleD>('EndDocPrinter');
	static final _closePrinter =
			_lib.lookupFunction<_HandleN, _HandleD>('ClosePrinter');

	/// Busca una impresora Zebra instalada (ZDesigner / ZD230 / Zebra).
	static Future<String?> detectarZebra() async {
		final r = await Process.run('powershell', [
			'-NoProfile',
			'-Command',
			r"Get-Printer | Where-Object { $_.Name -match 'ZDesigner|ZD230|Zebra' } | Select-Object -First 1 -ExpandProperty Name",
		]);
		final name = (r.stdout as String).trim();
		return name.isEmpty ? null : name;
	}

	/// Envía ZPL en bruto (RAW) a una impresora instalada en Windows.
	static void enviar(String nombreImpresora, String zpl) {
		final bytes = utf8.encode(zpl);

		final hPrinter = calloc<IntPtr>();
		final namePtr = nombreImpresora.toNativeUtf16();
		final docInfo = calloc<_DocInfo1>();
		final docName = 'Ticket'.toNativeUtf16();
		final dataType = 'RAW'.toNativeUtf16();
		final buffer = calloc<Uint8>(bytes.length);
		final written = calloc<Uint32>();
		var abierta = false;

		try {
			if (_openPrinter(namePtr, hPrinter, nullptr) == 0) {
				throw Exception('No se pudo abrir la impresora "$nombreImpresora"');
			}
			abierta = true;
			final h = hPrinter.value;

			docInfo.ref.pDocName = docName;
			docInfo.ref.pOutputFile = nullptr;
			docInfo.ref.pDatatype = dataType;

			if (_startDoc(h, 1, docInfo.cast()) == 0) {
				throw Exception('StartDocPrinter falló');
			}
			_startPage(h);

			buffer.asTypedList(bytes.length).setAll(0, bytes);
			final ok = _writePrinter(h, buffer.cast(), bytes.length, written);

			_endPage(h);
			_endDoc(h);

			if (ok == 0 || written.value != bytes.length) {
				throw Exception(
						'Escritura incompleta (${written.value}/${bytes.length})');
			}
		} finally {
			if (abierta) _closePrinter(hPrinter.value);
			calloc.free(hPrinter);
			calloc.free(namePtr);
			calloc.free(docInfo);
			calloc.free(docName);
			calloc.free(dataType);
			calloc.free(buffer);
			calloc.free(written);
		}
	}
}