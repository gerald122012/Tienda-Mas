import urllib.request,urllib.parse,json
from pathlib import Path
out=Path(r'D:/apli tienda/flutter_application_1/tools/catalogo_marcas')
for q in ['coca cola 500','chokosoda','arroz costeno']:
 url='https://www.plazavea.com.pe/api/catalog_system/pub/products/search?'+urllib.parse.urlencode({'ft':q,'_from':0,'_to':7})
 try:
  req=urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0','Accept':'application/json'})
  with urllib.request.urlopen(req,timeout=25) as r:data=json.load(r)
  (out/(q.replace(' ','_')+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf8')
  print(q,json.dumps([{'id':p.get('productId'),'nombre':p.get('productName'),'marca':p.get('brand'),'img':p.get('items',[{}])[0].get('images',[{}])[0].get('imageUrl')} for p in data],ensure_ascii=True),flush=True)
 except Exception as e:print(q,str(e),flush=True)
