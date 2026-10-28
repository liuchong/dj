from probe import accounts,request,OUT
import json
A=accounts()
for k,v in A.items():
 r=request('/open-apis/im/v1/chats?page_size=100',v['token']);print(k,'code',r.get('code'),'has_more',r.get('data',{}).get('has_more'),'chats',[{'chat_id':x.get('chat_id'),'name':x.get('name')} for x in r.get('data',{}).get('items',[])])
 p=OUT/(k+'-chats.private.json');p.write_text(json.dumps(r,ensure_ascii=False,indent=2));p.chmod(0o600)
