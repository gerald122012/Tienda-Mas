import json,urllib.request,urllib.parse,time,concurrent.futures
from pathlib import Path
folder=Path(r'D:/apli tienda/flutter_application_1/tools/catalogo_marcas')
queries=['arroz-costeno','azucar-cartanvio','aceite-primor','fideos-don-vittorio','lenteja-costeno','avena-quaker','sal-emsal','harina-blanca-flor','san-luis-sin-gas','san-mateo-con-gas','gaseosa-coca-cola-botella-500ml','inca-kola-500','frugos-durazno','cifrut','gatorade-tropical-fruit','free-tea-limon','leche-gloria-evaporada','leche-laive-uht','leche-gloria-light','leche-laive-sin-lactosa','yogurt-gloria-fresa','yogurt-laive-vainilla','queso-laive-edam','mantequilla-gloria','detergente-bolivar','lavavajilla-ayudin','lejia-clorox','limpiador-poett','suavizante-suavitel','jabon-bolivar','esponja-scotch-brite','bolsas-virutex','papas-lays','galletas-field-soda','chokosoda','mani-karinto','chifles-inka-chips','pop-corn-costeno','galleta-oreo','chocolate-sublime']
def fetch(item):
 i,q=item;p=folder/f'{i+1:02}_resultados.json'
 if p.exists():data=json.loads(p.read_text(encoding='utf8'))
 else:
  url='https://www.plazavea.com.pe/api/catalog_system/pub/products/search/'+urllib.parse.quote(q)+'?_from=0&_to=5'
  try:
   with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0','Accept':'application/json'}),timeout=30) as r:data=json.load(r)
   p.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf8')
  except Exception as e:return i+1,[],str(e)
 time.sleep(.5);return i+1,[{'id':p['productId'],'nombre':p['productName'],'marca':p['brand']} for p in data],''
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
 for i,rows,error in pool.map(fetch,enumerate(queries)):print(i,json.dumps(rows,ensure_ascii=True),error,flush=True)
