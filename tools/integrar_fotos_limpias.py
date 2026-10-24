"""Integra fotografías revisadas sin modificar la información del inventario."""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT.parent / 'catalogo_revision/fotos_limpias'
FIELDS = ['imagenUrl', 'imagenAsset', 'imagenAutor', 'imagenLicencia', 'imagenFuente']

def save(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf8')

def main():
    path = ROOT / 'tools/catalogo_marcas/productos_verificados.json'
    rows = json.loads(path.read_text(encoding='utf8'))
    backup = ROOT / 'tools/catalogo_marcas/productos_antes_fotos_limpias.json'
    if not backup.exists():
        shutil.copy2(path, backup)
    candidates = json.loads((REVIEW / 'seleccion_limpias.json').read_text(encoding='utf8'))
    clean = {r['id']: r for r in candidates if int(r['id'][-3:]) in [4, 24, 31, 32]}
    row28 = rows[27].copy()
    original = json.loads((ROOT / 'tools/catalogo_marcas/28_resultados.json').read_text(encoding='utf8'))
    product = next(p for p in original if str(p['productId']) == row28['fuenteId'])
    row28['imagenUrl'] = product['items'][0]['images'][1]['imageUrl']
    row28['imagenAsset'] = 'assets/productos/marcas/catalogo_028-limpia.jpg'
    shutil.copy2(REVIEW / '28_1.jpg', ROOT / row28['imagenAsset'])
    clean[row28['id']] = row28
    edits = json.loads((ROOT / 'tools/catalogo_marcas/ediciones_fotos_limpias.json').read_text(encoding='utf8'))
    edited = {e['id']: e for e in edits}
    for row in rows:
        if row['id'] in clean:
            row.update({k: clean[row['id']][k] for k in FIELDS})
        if row['id'] in edited:
            e = edited[row['id']]
            row['imagenAsset'] = f"assets/productos/marcas/{row['id']}-limpia.png"
            shutil.copy2(e['archivoGenerado'], ROOT / row['imagenAsset'])
            row['imagenUrl'] = ''
            row['imagenAutor'] = 'Foto comercial de plazaVea; fondo y paneles exteriores editados con IA'
    save(path, rows)
    save(ROOT / 'tools/catalogo_40.json', rows)
    save(ROOT / 'tools/catalogo_imagenes.json', [{k: r[k] for k in ['id', 'nombre'] + FIELDS} for r in rows])
    model = ROOT / 'lib/models/producto.dart'
    prefix = model.read_text(encoding='utf8').split('  // Productos comerciales verificados.')[0]
    q = lambda v: json.dumps(v, ensure_ascii=False).replace('$', r'\$')
    lines = ['  // Productos comerciales verificados. Los precios son referenciales.', '  static List<Producto> ejemplos() {', '    final hoy = DateTime.now();', '    return [']
    for row in rows:
        lines.append('      Producto(')
        for key in ['id', 'nombre', 'descripcion', 'marca'] + FIELDS:
            lines.append(f'        {key}: {q(row[key])},')
        lines += [f"        precio: {float(row['precio'])},", f"        stock: {row['stock']},", f"        categoria: {q(row['categoria'])},", '        disponible: true,', '        fechaRegistro: hoy,', f"        presentaciones: [{q(row['presentacion'])}],", '        valoracion: 5,', '        esEjemplo: true,', '      ),']
    model.write_text(prefix + '\n'.join(lines + ['    ];', '  }', '}', '']), encoding='utf8')
    sources = '# Fotografías del catálogo\n\nLas imágenes muestran el empaque sobre fondo blanco. Se conservaron las fotografías limpias originales y se sustituyeron las que tenían carteles externos.\n\nEn 20 fotografías se retiraron los paneles externos mediante edición de IA; pueden existir pequeñas diferencias de representación respecto de la fotografía original. El registro de entradas y resultados está en `tools/catalogo_marcas/ediciones_fotos_limpias.json`. Las marcas y fotografías pertenecen a sus respectivos titulares.\n\n'
    sources += '\n'.join(f"- {r['id']}: {r['nombre']} — {r['imagenAutor']}. Fuente: {r['imagenFuente']}" for r in rows)
    (ROOT / 'assets/productos/marcas/FUENTES.md').write_text(sources + '\n', encoding='utf8')
    print(json.dumps({'fotos_reemplazadas': len(clean) + len(edited), 'productos': len(rows)}))

if __name__ == '__main__':
    main()
