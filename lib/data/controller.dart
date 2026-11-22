import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sqflite/sqflite.dart';
import 'db/store.dart';
import 'judges/judge.dart';
import 'models.dart';
import '../features/progress/stats.dart';
import '../features/alarms/system_alarms.dart';
final app=ChangeNotifierProvider<Controller>((_)=>throw StateError('Chưa mở SQLite'));
class Controller extends ChangeNotifier{
 Controller(this.store);final Store store;
 final sys=SystemAlarms(),net=Net(),alerts=StreamController<Bell>.broadcast();
 final syncing=<String>{};final settings=<String,dynamic>{};final accounts=<String,Json>{};
 final knownSolved=<String,Set<String>>{};
 List<Entry> entries=[];List<Submission> submissions=[];List<RatingPoint> ratings=[];List<Contest> contests=[];List<Bell> pending=[];
 bool active=true;String? notice;Timer? timer;Future<void> _tail=Future.value();
 Stats? _stats;
 Stats get stats{final now=DateTime.now();if(_stats==null||date(_stats!.now)!=date(now))_stats=Stats(submissions,now);return _stats!;}String get base=>settings['base']??'https://oj.chuyentin.net';
 List<int> get leads=>List<int>.from(settings['contestLeads']??[30,10,5]);
 static Future<Controller> open()async{
 final c=Controller(await Store.open());await c.sys.init(c.alerts.add);await c.load();return c;
 }
 Future<void> load()async{
 final db=store.db;final snapshot=await db.transaction((t)async=>[for(final table in ['settings','accounts','entries','submissions','ratings','contests','solved'])await t.query(table)]);
 knownSolved.clear();for(final r in snapshot[6]){knownSolved.putIfAbsent(r['p'] as String,()=>{}).add(r['q'] as String);}
 settings.clear();for(final r in snapshot[0]){settings[r['k'] as String]=jsonDecode(r['v'] as String);}
 accounts.clear();for(final r in snapshot[1]){accounts[r['p'] as String]=Map<String,dynamic>.from(r);}
 entries=snapshot[2].map((r)=>Entry.from(jsonDecode(r['v'] as String))).toList();
 _stats=null;submissions=snapshot[3].map((r)=>Submission.from(jsonDecode(r['v'] as String))).toList();
 ratings=snapshot[4].map((r)=>RatingPoint(r['p'] as String,instant(r['t'] as int),r['v'] as int)).toList();
 contests=snapshot[5].map((r)=>Contest(r['p'] as String,r['id'] as String,r['title'] as String,instant(r['t'] as int),r['d'] as int)).toList();notifyListeners();
 }
 void clearNotice(){notice=null;notifyListeners();}
 Future<void> resume()async{
 await rebuild();final start=sys.launch;sys.launch=null;if(start!=null)alerts.add(start);
 for(final p in accounts.keys.toList()){final a=accounts[p];if(a!=null&&utc(DateTime.now())-(a['last']??0)>180)await sync(p);}
 }
 Future<void> rebuild(){
 final run=_tail.then((_)async{await load();final now=DateTime.now();
 final bells=plan(entries,contests,now,leads);final saved=settings['snoozes'] as List? ?? [];final extra=saved.map((j)=>Bell.from(j)).where((b)=>b.at.isAfter(now)).toList();
 if(extra.length!=saved.length)await store.put('snoozes',extra.map((b)=>b.json).toList());
 pending=([...bells,...extra]..sort((a,b)=>a.at.compareTo(b.at))).take(64).toList();arm();
 if(settings['asked']==true){final msg=await sys.replace(pending);if(msg!=null)notice=msg;}notifyListeners();});
 _tail=run.catchError((Object e){notice='Không thể cập nhật lịch báo: $e';notifyListeners();});return _tail;
 }
 void arm(){timer?.cancel();if(pending.isEmpty)return;final b=pending.first;timer=Timer(b.at.difference(DateTime.now()),(){
 pending.removeAt(0);if(active&&DateTime.now().difference(b.at).inSeconds<5)alerts.add(b);arm();notifyListeners();
 });}
 Future<void> ask(BuildContext c)async{
 if(settings['asked']==true)return;
 final ok=await showDialog<bool>(context:c,builder:(ctx)=>AlertDialog(title:const Text('Cho phép nhắc giờ?'),content:const Text('CP Alarm đặt báo thức và nhắc trước contest trên iPhone. Trên iOS 26, anh có thể cho phép chuông reo cả khi bật Tập trung.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Để sau')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Tiếp tục'))]));
 if(ok==true){await sys.request();await store.put('asked',true);settings['asked']=true;}else{notice='Chưa bật nhắc giờ ngoài ứng dụng.';notifyListeners();}
 }
 Future<void> openSettings()=>SystemAlarms.channel.invokeMethod('settings');
 Future<void> save(Entry e)async{await store.save(e);await rebuild();}
 Future<void> remove(String id)async{await store.remove(id);await rebuild();}
 Future<void> setting(String k,dynamic v)async{await store.put(k,v);if(k=='theme'){await load();}else{await rebuild();}}
 void testBell(){final now=DateTime.now();alerts.add(Bell('test','Codeforces Round 964',now,now.add(const Duration(minutes:30)),'Radar'));}
 Future<void> beginRinging(Bell b)async{try{await SystemAlarms.channel.invokeMethod('cancel',{'key':b.key});}on Exception{/* A local notification may already have fired. */}await sound(b.sound);}
 Future<void> silence()=>SystemAlarms.channel.invokeMethod('silence');
 Future<void> sound(String name)=>SystemAlarms.channel.invokeMethod('sound',{'sound':name});
 Future<void> dismiss(Bell b)async{await silence();await SystemAlarms.channel.invokeMethod('cancel',{'key':b.key});}
 Future<void> snooze(Bell b)async{final at=DateTime.now().add(const Duration(minutes:5));final bell=Bell('repeat/${utc(at)}/${b.key}',b.title,at,b.start,b.sound);
 await setting('snoozes',[...?(settings['snoozes'] as List?),bell.json]);}
 Future<void> link(String p,String u,String host)async{
 if(syncing.contains(p))return;syncing.add(p);notifyListeners();
 try{if(u.isEmpty||u.length>100||u.contains(RegExp(r'[/#?\s]')))throw JudgeFailure('Username không hợp lệ.');
 if(p=='ChuyênTin'){final uri=Uri.tryParse(host);if(uri==null||uri.scheme!='https'||uri.host.isEmpty||uri.userInfo.isNotEmpty||uri.path.length>1||uri.hasQuery||uri.hasFragment)throw JudgeFailure('Địa chỉ OJ phải là một tên miền HTTPS.');host=uri.origin;}
 await judge(net,p,host).verify(u);
 await store.db.transaction((tx)async{if(p=='ChuyênTin')await tx.insert('settings',{'k':'base','v':jsonEncode(host)},conflictAlgorithm:ConflictAlgorithm.replace);await tx.insert('accounts',{'p':p,'u':u});});await load();
 }catch(e){notice='Chưa liên kết $p: $e';notifyListeners();return;}finally{syncing.remove(p);notifyListeners();}
 await sync(p);
 }
 Future<void> unlink(String p)async{if(syncing.contains(p))return;await store.unlink(p);await rebuild();}
 Future<void> sync(String p)async{
 final row=accounts[p];if(row==null||syncing.contains(p))return;final now=utc(DateTime.now());if((row['retry']??0)>now){notice='OJ đang tạm nghỉ giữa các lần đồng bộ.';notifyListeners();return;}
 syncing.add(p);notifyListeners();
 try{final data=await judge(net,p,base).fetch(row['u'],math.max(0,(row['cursor'] as int)-300));
 int cursor=row['cursor'];await store.db.transaction((tx)async{final batch=tx.batch();for(final s in data.submissions){cursor=math.max(cursor,utc(s.submittedAt));batch.insert('submissions',{'p':p,'id':s.id,'v':jsonEncode(s.json)},conflictAlgorithm:ConflictAlgorithm.replace);}
 for(final q in data.solvedIds){batch.insert('solved',{'p':p,'q':q},conflictAlgorithm:ConflictAlgorithm.ignore);}
 for(final r in data.ratings){batch.insert('ratings',{'p':p,'t':utc(r.at),'v':r.value},conflictAlgorithm:ConflictAlgorithm.replace);}
 if(data.contestComplete)batch.delete('contests',where:'p=?',whereArgs:[p]);
 for(final c in data.contests){batch.insert('contests',{'p':p,'id':c.id,'title':c.title,'t':utc(c.start),'d':c.minutes},conflictAlgorithm:ConflictAlgorithm.replace);}
 batch.update('accounts',{'last':now,'cursor':cursor,'failures':data.warning==null?0:(row['failures'] as int)+1,'retry':data.warning==null?0:math.max(now+math.min(3600,60*(1<<math.min(row['failures'] as int,6))),data.retryAt==null?0:utc(data.retryAt!)),'error':data.warning},where:'p=?',whereArgs:[p]);await batch.commit(noResult:true);});
 }catch(e){final failures=(row['failures'] as int)+1;final until=now+math.min(3600,30*(1<<math.min(failures,7)));await store.db.update('accounts',{'error':e.toString(),'failures':failures,'retry':math.max(until,e is JudgeFailure&&e.retryAt!=null?utc(e.retryAt!):0)},where:'p=?',whereArgs:[p]);}
 finally{syncing.remove(p);await rebuild();}
 }
 @override void dispose(){timer?.cancel();alerts.close();super.dispose();}
}
