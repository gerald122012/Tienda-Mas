import json,re,urllib.request,urllib.error
from pathlib import Path
root=Path(__file__).resolve().parents[1];folder=root/'tools/catalogo_marcas'
rows=json.loads((folder/'productos_verificados.json').read_text(encoding='utf8'))
s=(root/'lib/firebase_options.dart').read_text(encoding='utf8');project=re.search(r"projectId: '([^']+)'",s).group(1);key=re.search(r"apiKey: '([^']+)'",s).group(1)
base=f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'
def request(url,body=None):
 req=urllib.request.Request(url,data=json.dumps(body).encode() if body is not None else None,headers={'Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=40) as r:return json.load(r)
def field(v):
 if isinstance(v,bool):return {'booleanValue':v}
 if isinstance(v,float):return {'doubleValue':v}
 if isinstance(v,list):return {'arrayValue':{'values':[field(x) for x in v]}}
 return {'stringValue':str(v)}
try:
 data=request(f'{base}/productos_mass?pageSize=1000&key={key}');docs={d['name'].rsplit('/',1)[-1]:d for d in data.get('documents',[])}
 backup=folder/'firestore_antes_marcas.json'
 if not backup.exists():backup.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf8')
 writes=[]
 for row in rows:
  doc=docs.get(row['id'])
  if not doc:raise RuntimeError('Falta documento '+row['id'])
  desired={k:row[k] for k in ['nombre','marca','descripcion','precio','imagenUrl','imagenAsset','imagenAutor','imagenLicencia','imagenFuente']}
  desired['presentaciones']=[row['presentacion']]
  if all(doc['fields'].get(k)==field(v) for k,v in desired.items()):continue
  writes.append({'update':{'name':doc['name'],'fields':{k:field(v) for k,v in desired.items()}},'updateMask':{'fieldPaths':list(desired)},'currentDocument':{'updateTime':doc['updateTime']}})
 if writes:request(f'{base}:commit?key={key}',{'writes':writes})
 data=request(f'{base}/productos_mass?pageSize=1000&key={key}');after={d['name'].rsplit('/',1)[-1]:d for d in data.get('documents',[])}
 verified=0
 for row in rows:
  f=after[row['id']]['fields'];old=docs[row['id']]['fields']
  assert all(f[k]['stringValue']==row[k] for k in ['nombre','marca','imagenUrl','imagenAsset','imagenFuente']),row['id']
  assert f['presentaciones']==field([row['presentacion']]),row['id']
  assert all(f.get(k)==old.get(k) for k in ['stock','disponible','fechaRegistro','valoracion','categoria']),row['id']
  verified+=1
 print(json.dumps({'productos_corregidos':len(writes),'productos_verificados':verified,'inventario_conservado':True}))
except urllib.error.HTTPError as e:
 print(json.dumps({'http':e.code,'error':json.loads(e.read()).get('error',{}).get('status')}));raise SystemExit(1)
