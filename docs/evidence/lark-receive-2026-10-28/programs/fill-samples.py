from probe import accounts,request,OUT
import json,datetime,uuid
A=accounts();marker='DJ-FILL-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ');group='oc_demo_debug_group';report={'marker':marker,'started_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sent':[]}
for source,target in [('repair','ou_demo_self_app_a'),('other','ou_demo_self_app_b')]:
 name=A[source]['bot']['bot']['app_name']
 for kind in ['private','group_mention_user']:
  text='🤖 DJ 收发验证 ['+marker+'] '+name+('→本人私聊' if kind=='private' else '→群里@本人')+'。仅核对通信，无需回复或执行任务。'
  if kind!='private':text='<at user_id="'+target+'">本人</at> '+text
  q='open_id' if kind=='private' else 'chat_id';r=request('/open-apis/im/v1/messages?receive_id_type='+q,A[source]['token'],{'receive_id':target if kind=='private' else group,'msg_type':'text','content':json.dumps({'text':text},ensure_ascii=False),'uuid':str(uuid.uuid4())})
  report['sent'].append({'source':name,'kind':kind,'code':r.get('code'),'msg':r.get('msg'),'message_id':r.get('data',{}).get('message_id'),'chat_id':r.get('data',{}).get('chat_id'),'sender':r.get('data',{}).get('sender')});print(json.dumps(report['sent'][-1],ensure_ascii=False),flush=True)
# A fresh positive control confirms the observer sees bot-authored WebSocket events.
target=A['repair']['bot']['bot']['open_id'];text='<at user_id="'+target+'">维修机器人</at> 🤖 ['+marker+'] 机器人实时收件阳性对照。只核对通信，无需回复或执行任务。';r=request('/open-apis/im/v1/messages?receive_id_type=chat_id',A['other']['token'],{'receive_id':group,'msg_type':'text','content':json.dumps({'text':text},ensure_ascii=False),'uuid':str(uuid.uuid4())});report['sent'].append({'source':'机器人B','kind':'group_mention_repair_bot','code':r.get('code'),'msg':r.get('msg'),'message_id':r.get('data',{}).get('message_id')});print(json.dumps(report['sent'][-1],ensure_ascii=False),flush=True)
p=OUT/'fill-samples.private.json';p.write_text(json.dumps(report,ensure_ascii=False,indent=2));p.chmod(0o600)
