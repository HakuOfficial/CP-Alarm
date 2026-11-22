import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/glass/glass_card.dart';
import '../../core/theme/theme.dart';
import '../../data/controller.dart';
import '../progress/stats.dart';
import 'rolling.dart';
import 'goals.dart';
class Dashboard extends StatefulWidget{
 const Dashboard(this.s,this.go,{super.key});final Controller s;final ValueChanged<int> go;
 @override State<Dashboard> createState()=>_Dashboard();
}
class _Dashboard extends State<Dashboard>{
 late final Timer timer;
 @override void initState(){super.initState();timer=Timer.periodic(const Duration(seconds:1),(_)=>setState((){}));}
 @override void dispose(){timer.cancel();super.dispose();}
 @override Widget build(BuildContext c){
 final s=widget.s,now=DateTime.now(),stats=s.stats;final sessions=s.entries.where((e)=>!e.alarm&&e.start.isAfter(now)).toList()..sort((a,b)=>a.start.compareTo(b.start));
 final events=[for(final e in sessions)(e.start,e.platform,e.title),for(final e in s.contests.where((e)=>e.start.isAfter(now)))(e.start.toLocal(),e.platform,e.title)]..sort((a,b)=>a.$1.compareTo(b.$1));
 final next=events.firstOrNull;final seconds=next?.$1.difference(now).inSeconds??0;
 final values=[seconds~/3600,seconds~/60%60,seconds%60];final scheme=Theme.of(c).colorScheme;
 final wide=MediaQuery.sizeOf(c).width>1000;
 final hero=GlassCard(radius:wide?48:32,padding:24,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Row(children:[Icon(Icons.circle,size:9,color:platforms[next?.$2]??scheme.primary),const SizedBox(width:8),Text(next?.$2??'Thời khóa biểu')]),Text(next?.$3??'Chưa có buổi luyện sắp tới'),
 SizedBox(height:wide?64:48),Semantics(label:'${values[0]} giờ ${values[1]} phút ${values[2]} giây',child:ExcludeSemantics(child:FittedBox(child:Row(children:[for(var i=0;i<3;i++)...[
 if(i>0)Padding(padding:const EdgeInsets.only(bottom:20),child:Text(':',style:TextStyle(fontSize:40,color:scheme.primary))),Column(children:[Row(children:[for(final n in values[i].toString().padLeft(2,'0').split(''))RollingDigit(int.parse(n))]),Text(['giờ','phút','giây'][i])])]])))),
 const SizedBox(height:24),const Divider(),Wrap(spacing:14,runSpacing:4,crossAxisAlignment:WrapCrossAlignment.center,children:[Text('Bắt đầu lúc\n${next==null?"—":clock(next.$1)}'),FilledButton(onPressed:()=>widget.go(2),child:const Text('Xem báo thức'))])]));
 final completed=s.entries.where((e)=>!e.alarm&&e.done&&!e.start.isBefore(stats.monday)&&!e.start.isAfter(now));
 final actual=[stats.weekSolved.toDouble(),completed.fold<int>(0,(a,e)=>a+e.minutes)/60,s.ratings.where((r)=>!r.at.isBefore(stats.monday)&&!r.at.isAfter(now)).length.toDouble()];
 final goals=List<num>.from(s.settings['goals']??[30,10,4]);final colors=[scheme.primary,scheme.onSurface,scheme.onSurface.withValues(alpha:.55)];
 final ratios=List.generate(3,(i)=>(actual[i]/goals[i]).clamp(0,1).toDouble());
 final week=GlassCard(radius:wide?34:28,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:heading(c,'Tuần này')),IconButton(tooltip:'Mục tiêu tuần',onPressed:()=>editGoals(c,s),icon:const Icon(Icons.tune,size:19))]),const SizedBox(height:16),Wrap(spacing:20,runSpacing:12,crossAxisAlignment:WrapCrossAlignment.center,children:[SizedBox.square(dimension:122,child:Stack(alignment:Alignment.center,children:[
 for(var i=0;i<3;i++)SizedBox.square(dimension:116-i*24.0,child:CircularProgressIndicator(semanticsLabel:['Bài giải','Giờ luyện','Contest'][i],value:ratios[i],strokeWidth:7,backgroundColor:scheme.onSurface.withValues(alpha:.09),color:colors[i])),
 Text('${(ratios.reduce((a,b)=>a+b)*100/3).round()}\nđiểm',textAlign:TextAlign.center)])),
 Column(crossAxisAlignment:CrossAxisAlignment.start,children:[for(var i=0;i<3;i++)Text('${["Bài giải","Giờ luyện","Contest"][i]}   ${NumberFormat("0.#").format(actual[i])}/${goals[i]}')])])]));
 final dates=List.generate(7,(i)=>date(now,i-6));final peak=dates.fold<int>(1,(a,d)=>math.max(a,stats.count(d)));
 final bars=GlassCard(radius:26,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading(c,'Chuỗi ${stats.streak} ngày'),const SizedBox(height:14),Row(children:[for(final d in dates)Expanded(child:Semantics(label:'${weekdays[d.weekday-1]}, ${stats.count(d)} bài',child:Column(children:[Container(width:18,height:68,alignment:Alignment.bottomCenter,decoration:BoxDecoration(color:scheme.onSurface.withValues(alpha:.06),borderRadius:BorderRadius.circular(12)),child:Container(height:68*stats.count(d)/peak,decoration:BoxDecoration(color:d==dates.last?scheme.primary:scheme.outline,borderRadius:BorderRadius.circular(12)))),Text(weekdays[d.weekday-1],style:const TextStyle(fontSize:12))])))])]));
 final e=sessions.firstOrNull;final following=GlassCard(radius:20,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Tiếp theo${e==null?"":", ${clock(e.start)}"}'),heading(c,e?.title??'Chưa có buổi luyện'),if(e!=null)Text('${e.platform}, ${e.minutes} phút'),TextButton(onPressed:()=>widget.go(1),child:const Text('Mở buổi luyện'))]));
 
 return PageBody('${now.hour<11?"Chào buổi sáng":now.hour<18?"Chào buổi chiều":"Chào buổi tối"}, Minh.',[if(wide)...[Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:170,child:hero),const SizedBox(width:18),Expanded(flex:80,child:week)]),Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(flex:170,child:bars),const SizedBox(width:18),Expanded(flex:80,child:following)])]else ...[hero,week,bars,following]],subtitle:DateFormat('EEEE, d MMMM','vi').format(now),action:IconButton(tooltip:'Thử chuông',onPressed:s.testBell,icon:const Icon(Icons.notifications_none)));
 }
}
