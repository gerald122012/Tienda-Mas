import json,re,urllib.request,urllib.error
from pathlib import Path
root=Path(__file__).resolve().parents[1]
options=(root/'lib/firebase_options.dart').read_text(encoding='utf8')
project=re.search(r"projectId: '([^']+)'",options).group(1)
key=re.search(r"apiKey: '([^']+)'",options).group(1)
base=f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'
try:
 req=urllib.request.Request(f'{base}/productos_mass?pageSize=1000&key={key}')
 with urllib.request.urlopen(req,timeout=25) as response: data=json.load(response)
 docs=data.get('documents',[])
 print(json.dumps({'documentos_actuales':len(docs),'ejemplos_ya_guardados':sum(d['name'].rsplit('/',1)[-1].startswith('catalogo_') for d in docs),'pagina_adicional':bool(data.get('nextPageToken'))}))
except urllib.error.HTTPError as error:
 data=json.loads(error.read());print(json.dumps({'http':error.code,'error':data.get('error',{}).get('status')}))
