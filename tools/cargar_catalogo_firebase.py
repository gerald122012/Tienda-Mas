import json,re,urllib.request,urllib.error
from pathlib import Path
from datetime import datetime,timezone
root=Path(__file__).resolve().parents[1]
s=(root/'lib/firebase_options.dart').read_text(encoding='utf8')
project=re.search(r"projectId: '([^']+)'",s).group(1)
key=re.search(r"apiKey: '([^']+)'",s).group(1)
base=f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'
rows=json.loads((root/'tools/catalogo_40.json').read_text(encoding='utf8'))
def request(url,body=None):
 req=urllib.request.Request(url,data=json.dumps(body).encode() if body is not None else None,headers={'Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=30) as response:return json.load(response)
def field(value):
 if isinstance(value,bool):return {'booleanValue':value}
 if isinstance(value,int):return {'integerValue':str(value)}
 if isinstance(value,float):return {'doubleValue':value}
 if isinstance(value,list):return {'arrayValue':{'values':[field(v) for v in value]}}
 return {'stringValue':value}
try:
 existing=set();page=''
 while True:
  data=request(f'{base}/productos_mass?pageSize=1000&key={key}'+('&pageToken='+page if page else ''))
  existing.update(d['name'].rsplit('/',1)[-1] for d in data.get('documents',[]))
  page=data.get('nextPageToken','')
  if not page:break
 writes=[]
 photos={r['id']:r for r in json.loads((root/'tools/catalogo_imagenes.json').read_text(encoding='utf8'))} if (root/'tools/catalogo_imagenes.json').exists() else {}
 for row in rows:
  if row['id'] in existing:continue
  product=dict(nombre=row['nombre'],descripcion=row.get('descripcion',row['nombre']),marca=row['marca'],precio=float(row['precio']),stock=row['stock'],categoria=row['categoria'],disponible=True,presentaciones=[row['presentacion']],valoracion=5.0,imagenUrl='',esEjemplo=True)
  photo=photos.get(row['id'],{})
  product.update({k:photo[k] for k in ['imagenUrl','imagenAsset','imagenAutor','imagenLicencia','imagenFuente'] if k in photo})
  fields={k:field(v) for k,v in product.items()}
  fields['fechaRegistro']={'timestampValue':datetime.now(timezone.utc).isoformat()}
  writes.append({'update':{'name':f'projects/{project}/databases/(default)/documents/productos_mass/{row["id"]}','fields':fields},'currentDocument':{'exists':False}})
 if writes:request(f'{base}:commit?key={key}',{'writes':writes})
 print(json.dumps({'productos_agregados':len(writes),'productos_previos_conservados':len(existing)},ensure_ascii=False))
except urllib.error.HTTPError as error:
 data=json.loads(error.read());print(json.dumps({'http':error.code,'error':data.get('error',{}).get('status')}));raise SystemExit(1)
