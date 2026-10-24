import urllib.request,urllib.parse,json
for q in ['cocacola','coca-cola','costeño','costeno']:
 url='https://www.plazavea.com.pe/api/catalog_system/pub/products/search/'+urllib.parse.quote(q)+'?_from=0&_to=4'
 try:
  with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'}),timeout=25) as r:d=json.load(r)
  print(q,json.dumps([{'nombre':p['productName'],'marca':p['brand'],'id':p['productId']} for p in d],ensure_ascii=True),flush=True)
 except urllib.error.HTTPError as e: print(q,e.code,e.read(200).decode(errors='replace'),flush=True)
