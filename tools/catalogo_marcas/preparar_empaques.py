import json,urllib.request,concurrent.futures,time,re
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(r'D:/apli tienda/flutter_application_1');folder=root/'tools/catalogo_marcas';dest=root/'assets/productos/marcas';dest.mkdir(exist_ok=True)
ids=['836','60863','100425974','101424810','3963','100009101','26702','31148','100419812','5188','5369','15227','101115739','101066579','5448','100167885','101021451','100909743','101021391','100909738','100531708','13076','8669','100909749','101178419','101165616','7175','100099475','277','101066680','12069','101548237','100693836','100454668','1900','100114566','101442256','3966','101061880','30878']
backup=folder/'respaldo_generico';backup.mkdir(exist_ok=True)
import shutil
for name in ['tools/catalogo_40.json','tools/catalogo_imagenes.json','lib/models/producto.dart','lib/widgets/producto_catalogo_card.dart','lib/screens/precios_mass/productos_screen.dart']:
 out=backup/name;out.parent.mkdir(parents=True,exist_ok=True)
 if not out.exists():shutil.copy2(root/name,out.with_suffix(out.suffix+'.bak'))
old=json.loads((root/'tools/catalogo_40.json').read_text(encoding='utf8'))
products={}
for p in folder.glob('*_resultados.json'):
 for product in json.loads(p.read_text(encoding='utf8')):products[product['productId']]=product
for product in json.loads((folder/'coca_todos.json').read_text(encoding='utf8')):products[product['productId']]=product
fallback=[20,4.5,9.5,3.5,5,5.5,2,6,2.5,2.8,3.5,4.8,5,1.8,3.5,3,27,5.5,5.5,6,5.5,4.5,10,9,22,10,7,5,9,3,5,6,6,5.5,6.5,3,2,4,4.5,6]
def download(item):
 i,pid=item;p=products[pid];sku=p['items'][0];image=sku['images'][0]
 # La variación 600x600 la sirve la misma tienda; conserva el empaque sin recortes.
 url=re.sub(r'/ids/(\d+)/',r'/ids/\1-600-600/',image['imageUrl']).split('?')[0]
 path=dest/f'catalogo_{i+1:03}.jpg'
 if not path.exists():
  req=urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'})
  for attempt in range(4):
   try:
    with urllib.request.urlopen(req,timeout=40) as r:body=r.read()
    break
   except urllib.error.HTTPError as error:
    if error.code!=429 or attempt==3:raise
    time.sleep(10*(attempt+1))
  path.write_bytes(body)
 with Image.open(path) as im:im.verify()
 offers=sku.get('sellers',[{}])[0].get('commertialOffer',{})
 price=offers.get('Price') or offers.get('ListPrice') or fallback[i]
 presentation=(p.get('Presentación unitarios vitrina') or [None])[0]
 if not presentation:
  match=re.search(r'(?:Botella|Bolsa|Caja|Paquete|Pote|Frasco|Lata|Taco|Doypack|Vaso|Galonera)\s.*$',p['productName'],re.I)
  presentation=match.group(0) if match else sku.get('name','Unidad')
 row=dict(id=f'catalogo_{i+1:03}',nombre=p['productName'],marca=p['brand'],categoria=old[i]['categoria'],presentacion=presentation,precio=round(float(price),2),stock=old[i]['stock'],descripcion=p['productName'],imagenUrl=url,imagenAsset='assets/productos/marcas/'+path.name,imagenAutor='Imagen comercial publicada por plazaVea',imagenLicencia='Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.',imagenFuente=p['link'],fuenteId=pid,skuId=sku['itemId'])
 print(row['id'],json.dumps(row['nombre'],ensure_ascii=True),path.stat().st_size,flush=True);time.sleep(1.2);return row
with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:rows=list(pool.map(download,enumerate(ids)))
(folder/'productos_verificados.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')
qa=Path(r'D:/apli tienda/catalogo_revision/marcas');qa.mkdir(exist_ok=True)
for start in range(0,40,20):
 sheet=Image.new('RGB',(1200,1120),'white');draw=ImageDraw.Draw(sheet)
 for j,row in enumerate(rows[start:start+20]):
  im=Image.open(root/row['imagenAsset']).convert('RGB');im.thumbnail((220,210));x=j%5*240;y=j//5*280
  sheet.paste(im,(x+(240-im.width)//2,y+20+(210-im.height)//2));draw.text((x+5,y+2),row['id'],fill='black');draw.text((x+5,y+235),row['marca'],fill='black');draw.text((x+5,y+250),row['presentacion'][:34],fill='black')
 sheet.save(qa/f'empaques-{start//20+1}.jpg')
print('Empaques descargados:',len(rows),flush=True)
