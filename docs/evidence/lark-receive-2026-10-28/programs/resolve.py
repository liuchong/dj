from probe import accounts,request,OUT
import json
A=accounts();group='oc_demo_debug_group';report={}
for k,v in A.items():
 r=request('/open-apis/im/v1/chats/'+group+'/members?member_id_type=open_id&page_size=100',v['token']);report[k]=r
 print(k,json.dumps(r,ensure_ascii=False))
p=OUT/'members.private.json';p.write_text(json.dumps(report,ensure_ascii=False,indent=2));p.chmod(0o600)
