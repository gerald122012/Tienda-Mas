import json,urllib.request,re,html
from pathlib import Path
folder=Path(r'D:/apli tienda/flutter_application_1/tools/catalogo_marcas')
url='https://www.plazavea.com.pe/api/catalog_system/pub/products/search/coca-cola?_from=0&_to=49'
with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=30) as r:d=json.load(r)
(folder/'coca_todos.json').write_text(json.dumps(d,ensure_ascii=False,indent=2),encoding='utf8')
print('COCA',json.dumps([{'id':p['productId'],'nombre':p['productName']} for p in d if '500' in p['productName']],ensure_ascii=True))
url='https://www.plazavea.com.pe/gaseosa-coca-cola-botella-500ml/p'
try:
 with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=30) as r:s=r.read().decode(errors='replace')
 (folder/'coca_500_pagina.html').write_text(s,encoding='utf8')
 print('META',json.dumps(re.findall(r'<meta[^>]+(?:og:image|og:title)[^>]*>',s),ensure_ascii=True)[:1300])
except Exception as e:print('Pagina',str(e))
for n,pid in [(3,'100425974'),(35,'1900')]:
 p=next(p for p in json.loads((folder/f'{n:02}_resultados.json').read_text(encoding='utf8')) if p['productId']==pid)
 print('PRESENTACION',pid,json.dumps({k:v for k,v in p.items() if 'present' in k.lower() or k in ['allSpecifications','allSpecificationsGroups']},ensure_ascii=True))
