import json,urllib.request,urllib.parse
from pathlib import Path
folder=Path(r'D:/apli tienda/flutter_application_1/tools/catalogo_marcas')
queries={2:'https://www.plazavea.com.pe/api/catalog_system/pub/products/search/azucar-cartavio?_from=0&_to=9',11:'https://www.plazavea.com.pe/api/catalog_system/pub/products/search?fq=skuId%3A281027'}
for i,url in queries.items():
 try:
  with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=30) as r:d=json.load(r)
  (folder/f'{i:02}_resultados.json').write_text(json.dumps(d,ensure_ascii=False,indent=2),encoding='utf8')
  print(i,json.dumps([{'id':p['productId'],'nombre':p['productName'],'marca':p['brand']} for p in d],ensure_ascii=True))
 except Exception as e:print(i,str(e))
p=json.loads((folder/'35_resultados.json').read_text(encoding='utf8'))[1]
print('DETALLE',json.dumps({k:v for k,v in p.items() if k not in ['items','description','categories']},ensure_ascii=True)[:2500])
