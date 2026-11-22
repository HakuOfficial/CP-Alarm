import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models.dart';
const demoMode=bool.fromEnvironment('CP_DEMO');
Future<void> seedDemo(Database db)async{
 if(!demoMode)return;
 await db.transaction((tx)async{
 if((await tx.query('settings',where:'k=?',whereArgs:['demoSeed'])).isNotEmpty)return;
 final now=DateTime.now();final monday=DateTime(now.year,now.month,now.day-now.weekday+1);
 final batch=tx.batch();void entry(Entry e)=>batch.insert('entries',{'id':e.id,'v':jsonEncode(e.json)});
 final titles=['DP nâng cao','Graph theory','Virtual contest','Cấu trúc dữ liệu','Speed solving'];
 final ps=['AtCoder','Codeforces','Codeforces','VNOJ','ChuyênTin'];
 for(var i=0;i<5;i++){entry(Entry('s$i',titles[i],DateTime(monday.year,monday.month,monday.day+i,[9,11,9,14,10][i],i==2||i==4?30:0),platform:ps[i],minutes:[100,80,120,95,80][i]));}
 entry(Entry('next','Dynamic Programming',now.add(const Duration(hours:3)),platform:'AtCoder',minutes:120));
 for(var i=0;i<4;i++){entry(Entry('a$i',['Morning problem','Luyện tập buổi tối','Codeforces Round 964','Virtual contest'][i],DateTime(now.year,now.month,now.day+1,[6,18,21,9][i],[30,45,5,0][i]),alarm:true,days:[[1,2,3,4,5],[1,2,3,4,5,6,7],<int>[],[6]][i],leads:i==2?[30,10,5]:[],enabled:i!=3,sound:i==3?'Apex':'Radar'));}
 batch.insert('contests',{'p':'Codeforces','id':'demo','title':'Codeforces Round 964','t':utc(now.add(const Duration(hours:2,minutes:17,seconds:42))),'d':120});
 for(var i=0;i<84;i++){final n=i<18?1+i%4:(i*17)%5;for(var j=0;j<n;j++){final id='$i-$j';final s=Submission(ps[i%5],id,id,j==3?'WA':'AC',DateTime(now.year,now.month,now.day-i).toUtc(),'C++',rating:800+i%16*100,tags:[['dp','graphs','trees','greedy','math'][i%5]]);batch.insert('submissions',{'p':s.platform,'id':id,'v':jsonEncode(s.json)});}}
 for(var i=0;i<10;i++){batch.insert('ratings',{'p':'Codeforces','t':utc(now.subtract(Duration(days:12*i))),'v':1842-32*i+(i%3)*11});}
 batch.insert('settings',{'k':'demoSeed','v':'true'});await batch.commit(noResult:true);
 });
}
