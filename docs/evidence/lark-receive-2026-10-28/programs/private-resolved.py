from probe import accounts,request,OUT,ROOT
import json,uuid,sqlite3,time
A=accounts();p=OUT/'roundtrip.private.json';r=json.loads(p.read_text());target=next(x['sender']['id'] for x in r['received'] if x['sender']['kind']=='bot' and x['connection_id']=='lark-bot-a')
body={'receive_id':target,'msg_type':'text','content':json.dumps({'text':'🤖 DJ 收发验证 [DJ-BOT-DM-RESOLVED-20261028] 维修机器人→另一应用机器人。仅核对通信，无需回复。'},ensure_ascii=False),'uuid':str(uuid.uuid4())}
x=request('/open-apis/im/v1/messages?receive_id_type=open_id',A['repair']['token'],body)
report={'target_from':'actual sender open_id in receiving app WebSocket event','result':x}
print(json.dumps(report,ensure_ascii=False),flush=True)
p=OUT/'resolved-bot-dm.private.json';p.write_text(json.dumps(report,ensure_ascii=False,indent=2));p.chmod(0o600)
