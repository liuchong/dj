import json,urllib.request,urllib.error,pathlib
ROOT=pathlib.Path.home()/'.dj'; OUT=pathlib.Path.home()/'.local/state/dj/evidence-output';OUT.mkdir(parents=True,exist_ok=True)
def request(path,token=None,body=None):
 req=urllib.request.Request('https://open.larksuite.com'+path,data=None if body is None else json.dumps(body).encode(),headers={'Content-Type':'application/json',**({'Authorization':'Bearer '+token} if token else {})})
 try:
  with urllib.request.urlopen(req,timeout=15) as r:return json.load(r)
 except urllib.error.HTTPError as e:return json.load(e)
def accounts():
 result={}
 for name,file in [('repair','lark-app.json'),('other','lark-user-b.json')]:
  c=json.loads((ROOT/'secrets'/file).read_text());a=request('/open-apis/auth/v3/tenant_access_token/internal',body={'app_id':c['app_id'],'app_secret':c['app_secret']});t=a['tenant_access_token'];b=request('/open-apis/bot/v3/info',t);s=request('/open-apis/application/v6/scopes',t)
  result[name]={'credential':c,'token':t,'bot':b,'scopes':s}
 return result
if __name__=='__main__':
 a=accounts(); report={}
 for k,v in a.items():
  report[k]={'app_id':v['credential']['app_id'],'bot':v['bot'],'scopes':v['scopes']}; print(k,json.dumps(report[k],ensure_ascii=False))
 (OUT/'accounts.private.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));(OUT/'accounts.private.json').chmod(0o600)
