import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;
import '../models.dart';
class JudgeFailure implements Exception{
 JudgeFailure(this.reason,{this.retryAt});final String reason;final DateTime? retryAt;@override String toString()=>reason;
}
class Net{
 final Dio dio=Dio(BaseOptions(connectTimeout:const Duration(seconds:12),receiveTimeout:const Duration(seconds:24),headers:{'User-Agent':'CPAlarm/1.0 (iOS; public competitive programming profiles)'}));
 final cooldown=<String,DateTime>{};
 final cache=<String,(DateTime,dynamic)>{};final last=<String,DateTime>{};
 Future<dynamic> get(String url,{Map<String,dynamic>? query,Duration ttl=const Duration(minutes:2)}) async{
 final uri=Uri.parse(url).replace(queryParameters:query?.map((k,v)=>MapEntry(k,v.toString())));final key=uri.toString();
 final old=cache[key];if(old!=null&&DateTime.now().difference(old.$1)<ttl)return old.$2;
 final until=cooldown[uri.host];if(until!=null&&until.isAfter(DateTime.now()))throw JudgeFailure('OJ giới hạn tốc độ.',retryAt:until);
 final previous=last[uri.host];if(previous!=null){final delay=previous.add(Duration(milliseconds:uri.host=='codeforces.com'?2100:1100)).difference(DateTime.now());if(delay>Duration.zero)await Future.delayed(delay);}
 last[uri.host]=DateTime.now();
 try{final res=await dio.getUri(uri);dynamic data=res.data;if(data is String&&(data.trimLeft().startsWith('{')||data.trimLeft().startsWith('['))){try{data=jsonDecode(data);}on FormatException{/* Checked by the adapter below. */}}
 if(data is String&&RegExp('challenge-platform|cf-chl-|Just a moment',caseSensitive:false).hasMatch(data))throw JudgeFailure('Trang đang yêu cầu xác minh. Thử lại sau.');
 if(cache.length>=80)cache.remove(cache.keys.first);cache[key]=(DateTime.now(),data);return data;
 }on DioException catch(e){
 final status=e.response?.statusCode;
 if(status==429){final sec=int.tryParse(e.response?.headers.value('retry-after')??'')??300;final until=DateTime.now().add(Duration(seconds:sec));cooldown[uri.host]=until;throw JudgeFailure('OJ giới hạn tốc độ. Thử lại sau.',retryAt:until);}
 if(status==404||status==401||status==403)throw RouteError(status!);
 throw JudgeFailure('Không đọc được dữ liệu từ ${uri.host}${status==null?"":" (HTTP $status)"}.');}
 }
}
class RouteError extends JudgeFailure{RouteError(this.status):super('OJ trả HTTP $status.');final int status;}
class Update{
 final submissions=<Submission>[],ratings=<RatingPoint>[],contests=<Contest>[];
 final solvedIds=<String>{};String? warning;bool contestComplete=false;
 int completedSources=0;DateTime? retryAt;
 Future<void> source(String name,Future<void> Function() read)async{
 try{await read();completedSources++;}catch(e){
 final message='$name: $e';warning=warning==null?message:'$warning\n$message';
 if(e is JudgeFailure&&e.retryAt!=null)retryAt=e.retryAt;
 }
 }
 void requireAny(){if(completedSources==0)throw JudgeFailure(warning??'Không đọc được dữ liệu OJ.',retryAt:retryAt);}
}
abstract class Judge{
 Judge(this.net,this.platform);final Net net;final String platform;
 Future<void> verify(String u);
 Future<Update> fetch(String u,int since);
 String segment(String s)=>Uri.encodeComponent(s);
}
class Codeforces extends Judge{
 Codeforces(Net n):super(n,'Codeforces');
 Future<List> api(String name,Map<String,dynamic> q)async{
 final j=await net.get('https://codeforces.com/api/$name',query:q);
 if(j is! Map||j['status']!='OK'||j['result'] is! List)throw JudgeFailure('Codeforces chưa trả kết quả $name.');return j['result'] as List;
 }
 @override Future<void> verify(String u)async{final rows=await api('user.info',{'handles':u});if(rows.isEmpty||rows.first['handle'].toString().toLowerCase()!=u.toLowerCase())throw JudgeFailure('Không tìm thấy username.');}
 Submission parse(Json j){final p=j['problem'];return Submission(platform,'${j["id"]}','${p["contestId"]??p["problemsetName"]}/${p["index"]}',j['verdict']??'TESTING',instant(j['creationTimeSeconds']),j['programmingLanguage']??'',rating:p['rating'],tags:List<String>.from(p['tags']??[]));}
 @override Future<Update> fetch(String u,int since)async{
 final data=Update();await data.source('Bài nộp',()async{final rowsRead=<Submission>[];for(int page=1;;page+=500){final rows=await api('user.status',{'handle':u,'from':page,'count':500});
 for(final raw in rows){final s=parse(raw);if(utc(s.submittedAt)>=since)rowsRead.add(s);}
 if(rows.length<500||rows.last['creationTimeSeconds']<since)break;}data.submissions.addAll(rowsRead);});
 await data.source('Rating',()async{for(final r in await api('user.rating',{'handle':u})){data.ratings.add(RatingPoint(platform,instant(r['ratingUpdateTimeSeconds']),r['newRating']));}});
 await data.source('Contest',()async{for(final c in await api('contest.list',{'gym':false})){if(c['phase']=='BEFORE')data.contests.add(Contest(platform,'${c["id"]}',c['name'],instant(c['startTimeSeconds']),c['durationSeconds']~/60));}
 data.contestComplete=true;});data.requireAny();return data;
 }
}
class AtCoder extends Judge{
 AtCoder(Net n):super(n,'AtCoder');
 static const base='https://kenkoooo.com/atcoder';
 @override Future<void> verify(String u)async{
 final raw=await net.get('https://atcoder.jp/users/${segment(u)}');final doc=html.parse(raw.toString());
 if(!(doc.querySelector('title')?.text??'').toLowerCase().contains(u.toLowerCase())||doc.querySelector('a[href="/users/${segment(u)}"]')==null)throw JudgeFailure('Chưa xác minh được hồ sơ AtCoder.');
 }
 Submission parse(Json j)=>Submission(platform,'${j["id"]}',j['problem_id'],j['result'],instant(j['epoch_second']),j['language']??'');
 @override Future<Update> fetch(String u,int since)async{
 final out=Update();await out.source('Bài nộp',()async{final rowsRead=<Submission>[];int cursor=since;
 while(true){final rows=await net.get('$base/atcoder-api/v3/user/submissions',query:{'user':u,'from_second':cursor});
 if(rows is! List)throw JudgeFailure('Dữ liệu AtCoder Problems không hợp lệ.');
 for(final j in rows){rowsRead.add(parse(j));}
 if(rows.length<500)break;
 final last=rows.map((j)=>j['epoch_second'] as int).reduce((a,b)=>a>b?a:b);if(last<=cursor)throw JudgeFailure('Trang submissions không tiến thêm.');cursor=last;
 }
 out.submissions.addAll(rowsRead);});
 await out.source('Rating',()async{final ratings=await net.get('https://atcoder.jp/users/${segment(u)}/history/json');if(ratings is! List)throw JudgeFailure('Chưa đọc được lịch sử rating AtCoder.');
 for(final r in ratings){if(r['IsRated']==true)out.ratings.add(RatingPoint(platform,DateTime.parse(r['EndTime']).toUtc(),r['NewRating']));}});
 await out.source('Contest',()async{final contests=await net.get('$base/resources/contests.json',ttl:const Duration(hours:3));if(contests is! List)throw JudgeFailure('Không đọc được lịch contest.');
 for(final c in contests){final t=instant(c['start_epoch_second']);if(t.isAfter(DateTime.now()))out.contests.add(Contest(platform,c['id'],c['title'],t,c['duration_second']~/60));}
 out.contestComplete=true;});out.requireAny();return out;
 }
}
class Dmoj extends Judge{
 Dmoj(Net n,String p,this.base):super(n,p);final String base;
 Future<dynamic> publicApi(String path,{Map<String,dynamic>? q})async{
 try{final j=await net.get('$base/api/v2/$path',query:q);if(j is Map&&j['data'] is Map)return j['data'];}on RouteError catch(e){if(![401,403,404].contains(e.status))rethrow;}return null;
 }
 @override Future<void> verify(String u)async{
 final data=await publicApi('user/${segment(u)}');if(data?['object']?['username']?.toString().toLowerCase()==u.toLowerCase())return;
 final doc=html.parse((await net.get('$base/user/${segment(u)}')).toString());
 if(!(doc.querySelector('title')?.text??'').toLowerCase().contains(u.toLowerCase())||!doc.querySelectorAll('a[href]').any((a)=>(a.attributes['href']??'').replaceFirst(RegExp(r'/$'),'')=='/user/${segment(u)}'))throw JudgeFailure('Chưa xác minh được username $platform.');
 }
 Submission parse(Json j){
 final problem=j['problem'];final q=problem is Map?problem['code']:problem;
 if(q is! String||j['id']==null||j['date']==null)throw JudgeFailure('Thiếu mã bài hoặc thời điểm nộp.');return Submission(platform,'${j["id"]}',q,j['result']??j['status']??'',DateTime.parse(j['date']).toUtc(),'${j["language"]??""}');
 }
 Set<String> solvedHtml(String raw){
 final doc=html.parse(raw);
 return doc.querySelectorAll('main a[href*="/problem/"], #content a[href*="/problem/"], .problem-list a[href*="/problem/"]')
 .map((e)=>RegExp(r'^/problem/([^/?#]+)/?$').firstMatch(e.attributes['href']??'')?.group(1)).whereType<String>().toSet();
 }
 Future<Update> solvedOnly(Update out,String u)async{
 final raw=(await net.get('$base/user/${segment(u)}/solved')).toString();
 final ids=solvedHtml(raw);if(ids.isEmpty)throw JudgeFailure('Chưa đọc được lịch sử nộp hoặc danh sách bài đã giải.');
 out.solvedIds.addAll(ids);out.warning='Đã đọc danh sách bài đã giải. Hồ sơ chưa cung cấp ngày nộp để tính chuỗi.';return out;
 }
 List<Submission> parseHtml(String raw){
 final doc=html.parse(raw);final out=<Submission>[];
 for(final row in doc.querySelectorAll('tr,.submission-row,.submission')){
 final a=row.querySelector('a[href*="/problem/"]'),b=row.querySelector('a[href*="/submission/"]');
 final tm=row.querySelector('time[datetime], [data-unix]');final stamp=tm?.attributes['datetime'];final n=int.tryParse(tm?.attributes['data-unix']??'');
 final at=n!=null?instant(n):DateTime.tryParse(stamp??'');final verdict=row.querySelector('.result,.status,.sub-result');
 if(a==null||b==null||at==null||verdict==null)continue;
 out.add(Submission(platform,b.attributes['href']!.split('/').where((s)=>s.isNotEmpty).last,a.attributes['href']!.split('/').where((s)=>s.isNotEmpty).last,verdict.text.trim(),at.toUtc(),row.querySelector('.language')?.text.trim()??''));}return out;
 }
 @override Future<Update> fetch(String u,int since)async{
 final out=Update();
 for(int page=1;;page++){final data=await publicApi('submissions',q:{'user':u,'page':page});
 if(data?['objects'] is! List){
 if(page>1)throw JudgeFailure('OJ chưa trả đủ các trang submissions.');
 final url='$base/submissions/${segment(u)}/';final seen=<String>{};var current=url;
 while(seen.add(current)){
 String raw;try{raw=(await net.get(current)).toString();}on RouteError{return solvedOnly(out,u);}final pageRows=parseHtml(raw);
 if(pageRows.isEmpty)return solvedOnly(out,u);
 out.submissions.addAll(pageRows.where((s)=>utc(s.submittedAt)>=since));
 if(pageRows.any((s)=>utc(s.submittedAt)<since))return out;
 final next=html.parse(raw).querySelector('a[rel="next"],.pagination .next a')?.attributes['href'];if(next==null)return out;
 final uri=Uri.parse(current).resolve(next);if(uri.origin!=Uri.parse(base).origin)throw JudgeFailure('Liên kết phân trang không hợp lệ.');current=uri.toString();
 }throw JudgeFailure('OJ lặp lại trang submissions.');
 }
 final rows=data['objects'] as List;for(final j in rows){if(j['user'] is! String||j['user'].toString().toLowerCase()!=u.toLowerCase())throw JudgeFailure('OJ không trả lịch sử riêng của username.');final s=parse(j);if(utc(s.submittedAt)>=since)out.submissions.add(s);}
 if(rows.isEmpty||data['has_more']==false||(data['total_pages'] is int&&page>=data['total_pages'])||(data['has_more']==null&&data['total_pages']==null)||utc(parse(rows.last).submittedAt)<since)break;
 }
 return out;
 }
}
Judge judge(Net net,String p,String base)=>switch(p){'Codeforces'=>Codeforces(net),'AtCoder'=>AtCoder(net),'VNOJ'=>Dmoj(net,p,'https://oj.vnoi.info'),_=>Dmoj(net,p,base)};
