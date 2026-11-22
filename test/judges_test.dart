import 'package:flutter_test/flutter_test.dart';
import 'package:cp_alarm/data/judges/judge.dart';
class FixtureNet extends Net{
 FixtureNet(this.routes);final Map<String,dynamic> routes;
 @override Future<dynamic> get(String url,{Map<String,dynamic>? query,Duration ttl=const Duration(minutes:2)}) async{
 if(!routes.containsKey(url))throw StateError('Unexpected $url');return routes[url];
 }
}
void main(){
 test('Codeforces giữ verdict, rating và tag',()async{
 final n=FixtureNet({'https://codeforces.com/api/user.status':{'status':'OK','result':[{'id':1,'creationTimeSeconds':1000,'programmingLanguage':'C++','problem':{'contestId':9,'index':'A','rating':800,'tags':['dp']},'verdict':'OK'}]},'https://codeforces.com/api/user.rating':{'status':'OK','result':[]},'https://codeforces.com/api/contest.list':{'status':'OK','result':[]}});
 final s=(await Codeforces(n).fetch('sample',100)).submissions.single;expect(s.problemId,'9/A');expect(s.ac,true);expect(s.tags,['dp']);expect(s.rating,800);
 });
 test('AtCoder Problems giữ epoch và không gán độ khó giả',()async{
 final n=FixtureNet({'https://kenkoooo.com/atcoder/atcoder-api/v3/user/submissions':[{'id':2,'problem_id':'abc_a','result':'AC','epoch_second':500,'language':'C++'}],'https://atcoder.jp/users/sample/history/json':[],'https://kenkoooo.com/atcoder/resources/contests.json':[]});
 final s=(await AtCoder(n).fetch('sample',400)).submissions.single;expect(s.rating,isNull);expect(s.submittedAt.isUtc,true);
 });
 test('VNOJ chỉ nhận đúng tài khoản',()async{
 final n=FixtureNet({'https://oj.vnoi.info/api/v2/submissions':{'data':{'objects':[{'user':'user','problem':'graph','result':'AC','id':1,'date':'2026-01-01T00:00:00Z'}],'total_pages':1}}});
 final j=Dmoj(n,'VNOJ','https://oj.vnoi.info');expect((await j.fetch('user',0)).submissions.single.ac,true);await expectLater(j.fetch('other',0),throwsA(isA<JudgeFailure>()));
 });
 test('ChuyênTin HTML công khai',(){
 const raw='<table><tr><td><a href="/submission/5">5</a></td><td><a href="/problem/dp">DP</a></td><td class="result">AC</td><td><time datetime="2026-01-01T00:00:00Z"></time></td></tr></table>';
 final j=Dmoj(FixtureNet({}),'ChuyênTin','https://oj.chuyentin.net');expect(j.parseHtml(raw).single.problemId,'dp');expect(j.parseHtml('<h1>Đăng nhập</h1>'),isEmpty);
 });
}
