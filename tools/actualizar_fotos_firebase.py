import json,re,urllib.request,urllib.error
from pathlib import Path
root=Path(__file__).resolve().parents[1]
s=(root/'lib/firebase_options.dart').read_text(encoding='utf8')
project=re.search(r"projectId: '([^']+)'",s).group(1);key=re.search(r"apiKey: '([^']+)'",s).group(1)
base=f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'
def request(url,body=None):
 req=urllib.request.Request(url,data=json.dumps(body).encode() if body is not None else None,headers={'Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=40) as r:return json.load(r)
photos=json.loads((root/'tools/catalogo_imagenes.json').read_text(encoding='utf8'))
fields=['imagenUrl','imagenAsset','imagenAutor','imagenLicencia','imagenFuente']
try:
 data=request(f'{base}/productos_mass?pageSize=1000&key={key}')
 docs={d['name'].rsplit('/',1)[-1]:d for d in data.get('documents',[])}
 backup=root/'tools/imagenes_catalogo/firestore_antes_fotos.json'
 if not backup.exists():backup.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf8')
 writes=[];preservados=[]
 for photo in photos:
  doc=docs.get(photo['id'])
  if not doc:preservados.append(photo['id']+': documento inexistente');continue
  old=doc.get('fields',{}).get('imagenUrl',{}).get('stringValue','')
  if old and old!=photo['imagenUrl']:preservados.append(photo['id']+': conserva imagen personalizada');continue
  if all(doc['fields'].get(k,{}).get('stringValue','')==photo[k] for k in fields):continue
  writes.append({'update':{'name':doc['name'],'fields':{k:{'stringValue':photo[k]} for k in fields}},'updateMask':{'fieldPaths':fields},'currentDocument':{'updateTime':doc['updateTime']}})
 if writes:request(f'{base}:commit?key={key}',{'writes':writes})
 verified=request(f'{base}/productos_mass?pageSize=1000&key={key}')
 ids={p['id'] for p in photos}
 count=sum(d['name'].rsplit('/',1)[-1] in ids and any(d.get('fields',{}).get(k,{}).get('stringValue') for k in ['imagenUrl','imagenAsset']) for d in verified.get('documents',[]))
 print(json.dumps({'actualizados':len(writes),'productos_con_foto':count,'conservados':preservados},ensure_ascii=False))
except urllib.error.HTTPError as e:
 print(json.dumps({'http':e.code,'error':json.loads(e.read()).get('error',{}).get('status')}));raise SystemExit(1)
