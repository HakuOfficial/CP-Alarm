import 'package:flutter_test/flutter_test.dart';
import 'package:cp_alarm/data/models.dart';
import 'package:cp_alarm/features/progress/stats.dart';
void main(){
 test('Streak theo ngày địa phương, AC lặp và ranh giới tuần',(){
 final now=DateTime(2026,11,23,9);
 Submission row(int n,int d,String v)=>Submission('CF','$n','A',v,DateTime(2026,11,23+d,0,1).toUtc(),'C++',rating:1400,tags:['dp']);
 final stats=Stats([row(1,-2,'AC'),row(2,-1,'AC'),row(3,-1,'WA'),row(4,-1,'AC')],now);
 expect(stats.streak,2);expect(stats.solved.length,1);expect(stats.heat.length,84);expect(stats.heat.first.weekday,1);expect(stats.tags['dp'],(3,4));expect(stats.weekSolved,0);expect(stats.difficulty,[0,1,0,0]);
 });
 test('64 mốc gần nhất theo giờ, gồm nhắc trước và thứ lặp',(){
 final now=DateTime(2026,11,23,8);final alarms=List.generate(20,(i)=>Entry('$i','Luyện',DateTime(2026,11,23,9,i),days:[1,2,3,4,5],leads:[30,10,5],alarm:true));
 final result=plan(alarms,[],now,[]);expect(result.length,64);expect(result.first.at,DateTime(2026,11,23,8,30));for(var i=1;i<64;i++){expect(result[i].at.isBefore(result[i-1].at),false);}
 });
}
