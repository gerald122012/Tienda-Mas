"""Actualiza exclusivamente las referencias y créditos de las fotografías."""
import json
import re
import urllib.request
from pathlib import Path

root = Path(__file__).resolve().parents[1]
folder = root / 'tools/catalogo_marcas'
rows = json.loads((folder / 'productos_verificados.json').read_text(encoding='utf8'))
options = (root / 'lib/firebase_options.dart').read_text(encoding='utf8')
project = re.search(r"projectId: '([^']+)'", options).group(1)
key = re.search(r"apiKey: '([^']+)'", options).group(1)
base = f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'
fields = ['imagenUrl', 'imagenAsset', 'imagenAutor', 'imagenLicencia', 'imagenFuente']

def request(url, body=None):
    req = urllib.request.Request(url, data=json.dumps(body).encode() if body is not None else None, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=40) as response:
        return json.load(response)

data = request(f'{base}/productos_mass?pageSize=1000&key={key}')
before = {d['name'].rsplit('/', 1)[-1]: d for d in data.get('documents', [])}
backup = folder / 'firestore_antes_fotos_limpias.json'
if not backup.exists():
    backup.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf8')
writes = []
for row in rows:
    doc = before[row['id']]
    desired = {k: {'stringValue': row[k]} for k in fields}
    if all(doc['fields'].get(k) == v for k, v in desired.items()):
        continue
    writes.append({'update': {'name': doc['name'], 'fields': desired}, 'updateMask': {'fieldPaths': fields}, 'currentDocument': {'updateTime': doc['updateTime']}})
if writes:
    request(f'{base}:commit?key={key}', {'writes': writes})
after = {d['name'].rsplit('/', 1)[-1]: d for d in request(f'{base}/productos_mass?pageSize=1000&key={key}').get('documents', [])}
for row in rows:
    old = before[row['id']]['fields']
    new = after[row['id']]['fields']
    assert all(new[k]['stringValue'] == row[k] for k in fields), row['id']
    assert {k: v for k, v in old.items() if k not in fields} == {k: v for k, v in new.items() if k not in fields}, row['id']
print(json.dumps({'fotos_actualizadas': len(writes), 'productos_verificados': len(rows), 'otros_campos_conservados': True}))
