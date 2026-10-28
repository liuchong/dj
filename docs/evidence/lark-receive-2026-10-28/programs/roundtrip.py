from probe import accounts,request,OUT,ROOT
import json,time,sqlite3,uuid,datetime
A=accounts();group='oc_demo_debug_group'
start=time.time();marker='DJ-MATRIX-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ');report={'marker':marker,'started_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sent':[],'received':[],'history':[],'notes':'Existing service WebSockets only; no extra consumer; no recovery or replay'}
db=sqlite3.connect('file:'+str(ROOT/'state/dj.sqlite')+'?mode=ro',uri=True)
seq=db.execute('select coalesce(max(ingress_seq),0) from events').fetchone()[0]
def save():
 p=OUT/'roundtrip.private.json';p.write_text(json.dumps(report,ensure_ascii=False,indent=2));p.chmod(0o600)
def send(label,token,target,kind='chat_id',mention=None):
 text='🤖 DJ 收发验证 ['+marker+'] '+label+'。仅核对通信，请勿创建任务或回复。'
 if mention:text='<at user_id="'+mention+'">接收机器人</at> '+text
 r=request('/open-apis/im/v1/messages?receive_id_type='+kind,token,{'receive_id':target,'msg_type':'text','content':json.dumps({'text':text},ensure_ascii=False),'uuid':str(uuid.uuid4())})
 data=r.get('data',{});report['sent'].append({'label':label,'code':r.get('code'),'msg':r.get('msg'),'message_id':data.get('message_id'),'chat_id':data.get('chat_id'),'sender':data.get('sender'),'error':r.get('error')});save();print(json.dumps(report['sent'][-1],ensure_ascii=False),flush=True)
# Different OAuth app for the same human user versus repair application.
send('本人B→维修机器人A私聊',A['other']['credential']['user_access_token'],'oc_demo_user_bot_a_dm')
send('维修机器人A→本人私聊',A['repair']['token'],'ou_demo_self_app_a','open_id')
# Bot to bot, explicit mention and plain group broadcasts in the authorized debug group.
for source,target in [('other','repair'),('repair','other')]:
 s=A[source];t=A[target]['bot']['bot'];label=s['bot']['bot']['app_name']+'→'+t['app_name']
 send(label+'群聊@',s['token'],group,mention=t['open_id'])
 send(label+'群聊普通消息',s['token'],group)
 send(label+'私聊',s['token'],t['open_id'],'open_id')
# Human own group echo is a separate dimension.
send('本人B→群本人回声',A['other']['credential']['user_access_token'],group)
seen=set()
while time.time()-start<65:
 for eid,con,mid,at,p in db.execute('select event_id,connection_id,native_message_id,received_at,payload from events where ingress_seq>? order by ingress_seq limit 1000',(seq,)):
  if eid in seen:continue
  seen.add(eid);e=json.loads(p)
  if marker not in e.get('content',{}).get('text',''):continue
  r={'event_id':eid,'connection_id':con,'message_id':mid,'received_at':at,'source_time':e.get('source_time'),'sender':e.get('sender'),'chat_type':e.get('chat_type'),'receive_transport':e.get('receive_transport','websocket_existing_service'),'text':e.get('content',{}).get('text')};report['received'].append(r);save();print('RECEIVED '+json.dumps(r,ensure_ascii=False),flush=True)
 time.sleep(1)
# Official HTTP readback does not feed or recover anything into DJ.
for s in report['sent']:
 if not s.get('message_id'):continue
 for name,token in [('userB',A['other']['credential']['user_access_token']),('repairBotA',A['repair']['token']),('otherBotB',A['other']['token'])]:
  r=request('/open-apis/im/v1/messages/'+s['message_id'],token);items=r.get('data',{}).get('items',[])
  report['history'].append({'label':s['label'],'reader':name,'code':r.get('code'),'message_id':s['message_id'],'senders':[x.get('sender') for x in items],'msg':r.get('msg')})
report['finished_at']=datetime.datetime.now(datetime.timezone.utc).isoformat();save()
print('DONE '+json.dumps({'sent':len(report['sent']),'received':len(report['received'])}),flush=True)
