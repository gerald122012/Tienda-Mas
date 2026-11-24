import 'package:flutter/material.dart';

import '../../services/lectura_escaner.dart';
import '../../tema/tema_mass.dart';

class ArchivoSesion {
  final String nombre;
  final String extension;
  final int tamanoBytes;
  final String categoria;
  final String resultado;

  const ArchivoSesion({
    required this.nombre,
    required this.extension,
    required this.tamanoBytes,
    required this.categoria,
    required this.resultado,
  });
}

class SelectorArchivosMass extends StatelessWidget {
  static const categorias = [
    'Comprobante de pago',
    'Boleta / Factura',
    'Documento de local',
    'Otro documento',
  ];

  final String categoria;
  final ValueChanged<String> alElegirCategoria;
  final VoidCallback? alSeleccionar;
  final bool procesando;
  final String? error;
  final List<ArchivoSesion> archivos;
  final ValueChanged<ArchivoSesion> alQuitar;

  const SelectorArchivosMass({
    super.key,
    required this.categoria,
    required this.alElegirCategoria,
    required this.alSeleccionar,
    required this.procesando,
    required this.error,
    required this.archivos,
    required this.alQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          'Adjunta un comprobante',
          style: textoMass(
            tamano: 16,
            peso: FontWeight.w700,
            color: tokens.profundo,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG, PNG, PDF, DOC, DOCX o TXT. Máximo 8 MB. Se registran metadatos, no el archivo. No se ejecuta ni se envía al asistente.',
          style: textoMass(tamano: 12, color: tokens.tintaSuave),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('tipo-archivo'),
          initialValue: categoria,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Tipo de documento',
            isDense: true,
          ),
          items: [
            for (final item in categorias)
              DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: procesando
              ? null
              : (valor) {
                  if (valor != null) alElegirCategoria(valor);
                },
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('seleccionar-archivo'),
          onPressed: procesando ? null : alSeleccionar,
          style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            textStyle: textoMass(peso: FontWeight.w700, color: Colors.white),
          ),
          icon: procesando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.attach_file_rounded, color: Colors.white),
          label: Text(procesando ? 'Procesando' : 'Seleccionar archivo'),
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            style: textoMass(
              tamano: 13,
              peso: FontWeight.w700,
              color: tokens.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'En esta sesión',
          style: textoMass(
            tamano: 14,
            peso: FontWeight.w700,
            color: tokens.profundo,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quitar una entrada solo la saca de esta lista. No borra un documento ya registrado.',
          style: textoMass(tamano: 12, color: tokens.tintaSuave),
        ),
        const SizedBox(height: 8),
        if (archivos.isEmpty)
          Text(
            'Aún no hay archivos en esta sesión.',
            style: textoMass(tamano: 13, color: tokens.tintaSuave),
          )
        else
          for (final archivo in archivos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.superficie,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.linea),
                ),
                child: ListTile(
                  title: Text(
                    archivo.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textoMass(tamano: 14, peso: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${archivo.categoria} · ${archivo.extension.toUpperCase()} · ${textoTamanoArchivo(archivo.tamanoBytes)}\n${archivo.resultado}',
                    style: textoMass(tamano: 12, color: tokens.tintaSuave),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip:
                        'Quitar de la sesión. No borra un registro en la nube.',
                    onPressed: () => alQuitar(archivo),
                    icon: Icon(Icons.close_rounded, color: tokens.tintaSuave),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
