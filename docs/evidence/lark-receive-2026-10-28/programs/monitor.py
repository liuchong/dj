import collections,datetime,hashlib,json,os,pathlib,signal,sqlite3,subprocess,threading,time,urllib.request,urllib.error,urllib.parse
ROOT=pathlib.Path.home()/'.dj'; RUN=pathlib.Path.home()/'.local/state/dj/evidence-monitor';RUN.mkdir(parents=True,exist_ok=True); SERVICE_DB=ROOT/'state/dj.sqlite'; STOP=threading.Event(); LOCK=threading.RLock(); START=time.time(); START_ISO=datetime.datetime.fromtimestamp(START,datetime.timezone.utc).isoformat(); START_MS=int(START*1000)
GROUP='oc_demo_debug_group'; DM='oc_demo_user_bot_a_dm'; TOKENS={}; LAST_REQUEST=0.; CHATS={DM:'机器人与本人私聊'}; HEALTH={}; REQUESTS=collections.Counter(); CYCLES=collections.Counter(); LAST_WS_SEQ=0
SELF={'lark-user-b':'ou_demo_self_app_b','lark-bot-a':'ou_demo_self_app_a'}
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def atomic(name,value):
 tmp=RUN/(name+'.new');tmp.write_text(json.dumps(value,ensure_ascii=False,indent=2));tmp.chmod(0o600);os.replace(tmp,RUN/name)
def database():
 c=sqlite3.connect(RUN/'observations.sqlite',timeout=5);c.execute('pragma busy_timeout=5000');return c
def log(value):
 path=RUN/'monitor.ndjson'
 if path.exists() and path.stat().st_size>8*1024*1024:
  for i in range(3,0,-1):
   old=RUN/('monitor.ndjson' if i==1 else 'monitor.ndjson.'+str(i-1));new=RUN/('monitor.ndjson.'+str(i))
   if old.exists():os.replace(old,new)
 with path.open('a') as f:f.write(json.dumps(value,ensure_ascii=False)+'\n')
 path.chmod(0o600)
def observe(connection,channel,message,observed_at=None):
 mid=message.get('message_id') or message.get('native_message_id')
 if not mid:return
 stamp=message.get('create_time')
 if stamp and int(stamp)<START_MS:return
 sender=message.get('sender',{});sid=sender.get('id');kind=sender.get('sender_type',sender.get('kind','unknown'))
 kind='human' if kind in ('user','human') else 'bot' if kind in ('app','bot') else kind
 identity='self' if kind=='human' and (sid==SELF.get(connection) or any(i.get('id')=='demo_self_user' and i.get('scope','').endswith('user_id') for i in sender.get('identities',[]))) else 'other' if kind=='human' else kind
 cid=message.get('chat_id') or message.get('conversation',{}).get('native_chat_id');typ=message.get('chat_type','unknown');text=message.get('content',{});text=text.get('text','') if isinstance(text,dict) else text
 body=message.get('body',{}).get('content')
 if body:
  try:text=json.loads(body).get('text',body)
  except (ValueError,AttributeError):text=body
 seen_at=observed_at or now();source=message.get('source_time') or (datetime.datetime.fromtimestamp(int(stamp)/1000,datetime.timezone.utc).isoformat() if stamp else None)
 with LOCK:
  c=database();new=c.execute('insert or ignore into observations values(?,?,?,?,?,?,?,?,?,?,?)',(connection,mid,channel,seen_at,source,cid,typ,kind,identity,sid,str(text or '')[:400])).rowcount;c.commit();c.close()
  if new:
   v={'at':seen_at,'connection':connection,'channel':channel,'message_id':mid,'source_time':source,'chat_id':cid,'chat_name':CHATS.get(cid),'chat_type':typ,'sender_kind':kind,'sender_identity':identity,'sender_id':sid,'preview':str(text or '')[:160]};log(v);print(json.dumps(v,ensure_ascii=False),flush=True)
  if cid and connection=='lark-bot-a':CHATS.setdefault(cid,cid)
def wire(path,token=None,body=None,identity='system'):
 global LAST_REQUEST
 wait=.55-(time.monotonic()-LAST_REQUEST)
 if wait>0:STOP.wait(wait)
 if STOP.is_set():raise InterruptedError()
 LAST_REQUEST=time.monotonic();REQUESTS[identity]+=1
 req=urllib.request.Request('https://open.larksuite.com'+path,data=None if body is None else json.dumps(body).encode(),headers={'Content-Type':'application/json',**({'Authorization':'Bearer '+token} if token else {})})
 try:
  with urllib.request.urlopen(req,timeout=12) as r:data=json.load(r)
 except urllib.error.HTTPError as e:data=json.load(e)
 if data.get('code',0)!=0:raise RuntimeError(json.dumps({'code':data.get('code'),'msg':data.get('msg','')[:160]},ensure_ascii=False))
 return data
LAST_REFRESH=0.
def credential(identity):
 global LAST_REFRESH
 if identity=='lark-user-b':
  p=ROOT/'secrets/lark-user-b.json';c=json.loads(p.read_text());expiry=datetime.datetime.fromisoformat(c['expires_at'].replace('Z','+00:00')).timestamp()
  if expiry<time.time()+120 and time.monotonic()-LAST_REFRESH>30:
   LAST_REFRESH=time.monotonic();runtime=ROOT/'runtime/bun-1.4.4/bin/bun';cli=ROOT/'current/dist/src/interfaces/cli.mjs'
   result=subprocess.run([str(runtime),str(cli),'conversation','resolve','--input','-','--json'],input=json.dumps({'connection_id':'lark-user-b','chat_id':GROUP}),text=True,capture_output=True,timeout=25)
   reply=json.loads(result.stdout)
   if not reply.get('ok'):raise RuntimeError('DJ credential renewal unavailable: '+str(reply.get('error',{}).get('code')))
   c=json.loads(p.read_text())
  return c['user_access_token']
 if identity not in TOKENS or TOKENS[identity][1]<time.time()+120:
  c=json.loads((ROOT/'secrets/lark-app.json').read_text());r=wire('/open-apis/auth/v3/tenant_access_token/internal',body={'app_id':c['app_id'],'app_secret':c['app_secret']},identity=identity);TOKENS[identity]=(r['tenant_access_token'],time.time()+r.get('expire',3600))
 return TOKENS[identity][0]
def api(identity,path,body=None):return wire(path,credential(identity),body,identity)
def ws_monitor():
 global LAST_WS_SEQ
 source=sqlite3.connect('file:'+str(SERVICE_DB)+'?mode=ro',uri=True,timeout=3);source.execute('pragma busy_timeout=3000')
 LAST_WS_SEQ=source.execute('select coalesce(max(ingress_seq),0) from events').fetchone()[0]
 while not STOP.is_set():
  try:
   for seq,con,payload in source.execute('select ingress_seq,connection_id,payload from events where ingress_seq>? order by ingress_seq limit 256',(LAST_WS_SEQ,)):
    LAST_WS_SEQ=seq;e=json.loads(payload)
    if con not in SELF or e.get('event_kind')!='message.created':continue
    if e.get('received_at','')<START_ISO[:19] or (e.get('source_time') and e['source_time']<START_ISO[:19]):continue
    # Existing deployment receives these IM events from its application WebSockets.
    channel=e.get('receive_transport','websocket');observe(con,channel,e,e.get('received_at'));HEALTH[con+':websocket']={'last_new_message_at':now(),'last_message_id':e.get('native_message_id')}
  except Exception as e:HEALTH['websocket_reader']={'error':type(e).__name__,'at':now()}
  STOP.wait(.5)
 source.close()
def status():
 with LOCK:
  c=database();counts=[dict(zip(('connection','channel','sender_kind','sender_identity','chat_type','count'),r)) for r in c.execute('select connection,channel,sender_kind,sender_identity,chat_type,count(*) from observations group by 1,2,3,4,5')]
  comparison=[]
  for con in SELF:
   rs=c.execute("select message_id,max(channel='websocket'),max(channel='http'),min(first_seen),max(first_seen) from observations where connection=? group by message_id",(con,)).fetchall();ctr=collections.Counter('both' if w and h else 'websocket_only_so_far' if w else 'http_only_so_far' for _,w,h,_,_ in rs);comparison.append({'connection':con,**dict(ctr)})
  c.close();atomic('status.json',{'state':'stopping' if STOP.is_set() else 'running','started_at':START_ISO,'updated_at':now(),'pid':os.getpid(),'websocket_source':'existing service connections; no duplicate WebSocket consumer','http_source':'official APIs read only; never ingested or replayed','last_ingress_seq':LAST_WS_SEQ,'counts':counts,'comparison':comparison,'http_requests':dict(REQUESTS),'completed_http_windows':dict(CYCLES),'health':HEALTH,'bot_chats':CHATS})
def main():
 c=database();c.execute('pragma journal_mode=wal');c.execute('create table if not exists observations(connection text,message_id text,channel text,first_seen text,source_time text,chat_id text,chat_type text,sender_kind text,sender_identity text,sender_id text,preview text,primary key(connection,message_id,channel))');c.commit();c.close();(RUN/'observations.sqlite').chmod(0o600)
 atomic('control.json',{'pid':os.getpid(),'started_at':START_ISO,'script':str(pathlib.Path(__file__).resolve()),'stop_file':str(RUN/'STOP'),'until':'explicit user termination; no total timeout'})
 worker=threading.Thread(target=ws_monitor,name='service-event-observer');worker.start();jobs={};chat_page=None;next_chats=0.;last_status=0
 print(json.dumps({'state':'started','started_at':START_ISO,'directory':str(RUN),'pid':os.getpid()}),flush=True)
 try:
  while not STOP.is_set() and not (RUN/'STOP').exists():
   if time.time()-last_status>2:status();last_status=time.time()
   try:
    if time.time()>=next_chats:
     r=api('lark-bot-a','/open-apis/im/v1/chats?page_size=100'+('&page_token='+urllib.parse.quote(chat_page) if chat_page else ''));d=r.get('data',{});CHATS.update({x['chat_id']:x.get('name',x['chat_id']) for x in d.get('items',[])});chat_page=d.get('page_token') if d.get('has_more') else None;next_chats=time.time()+(1 if chat_page else 60)
    for typ in ('p2p_chat','group_chat'):jobs.setdefault(('lark-user-b',typ),{'until':int(START),'due':0})
    with LOCK:chat_ids=list(CHATS)
    for cid in chat_ids:jobs.setdefault(('lark-bot-a',cid),{'until':int(START),'due':0})
    due=[(k,j) for k,j in jobs.items() if j['due']<=time.time()]
    if not due:STOP.wait(.5);continue
    key,j=min(due,key=lambda pair:pair[1]['due']);con,scope=key
    if 'end' not in j:j.update(begin=max(int(START),j['until']-120),end=max(int(START),int(time.time())-2),page=None)
    if j['end']<=j['begin']:j.pop('end');j['due']=time.time()+3;continue
    if con=='lark-user-b':
     r=api(con,'/open-apis/search/v2/message?'+urllib.parse.urlencode({'page_size':50,**({'page_token':j['page']} if j['page'] else {})}),{'query':'','chat_type':scope,'start_time':str(j['begin']),'end_time':str(j['end'])});d=r.get('data',{})
     for item in d.get('items',[]):
      mid=item if isinstance(item,str) else item.get('message_id')
      with LOCK:
       c=database();exists=c.execute("select 1 from observations where connection=? and message_id=? and channel='http'",(con,mid)).fetchone();c.close()
      if exists:continue
      details=api(con,'/open-apis/im/v1/messages/'+mid)
      for m in details.get('data',{}).get('items',[]):m['chat_type']='p2p' if scope=='p2p_chat' else 'group';observe(con,'http',m)
    else:
     q={'container_id_type':'chat','container_id':scope,'start_time':str(j['begin']),'end_time':str(j['end']),'sort_type':'ByCreateTimeAsc','page_size':50}
     if j['page']:q['page_token']=j['page']
     r=api(con,'/open-apis/im/v1/messages?'+urllib.parse.urlencode(q));d=r.get('data',{})
     for m in d.get('items',[]):m.setdefault('chat_type','p2p' if scope==DM else 'group');observe(con,'http',m)
    HEALTH[con+':http']={'state':'ok','last_success_at':now()};j['due']=time.time()+.1
    if d.get('has_more'):
     token=d.get('page_token')
     if not token or token==j.get('page'):raise RuntimeError('invalid HTTP pagination token')
     j['page']=token
    else:j['until']=j.pop('end');j['due']=time.time()+5;CYCLES[con]+=1
   except InterruptedError:break
   except Exception as e:
    name=key[0] if 'key' in locals() else 'lark-bot-a';HEALTH[name+':http']={'state':'error','at':now(),'error':str(e)[:220]};log({'at':now(),'type':'http_error','connection':name,'error':str(e)[:220]})
    if 'j' in locals():j['due']=time.time()+10
    next_chats=max(next_chats,time.time()+10);STOP.wait(2)
 finally:
  STOP.set();worker.join(timeout=5);status();x=json.loads((RUN/'status.json').read_text());x['state']='stopped';x['stopped_at']=now();atomic('status.json',x);print(json.dumps({'state':'stopped','at':now()}),flush=True)
for sig in (signal.SIGINT,signal.SIGTERM):signal.signal(sig,lambda *_:STOP.set())
if __name__=='__main__':main()
