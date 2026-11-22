import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/glass/glass_card.dart';
import '../../core/theme/theme.dart';
import '../../data/controller.dart';
import '../../data/models.dart';
import '../schedule/editor.dart';
class Alarms extends StatelessWidget{
 const Alarms(this.s,{super.key});final Controller s;
 @override Widget build(BuildContext c){
 final alarms=s.entries.where((e)=>e.alarm).toList()..sort((a,b)=>clock(a.start).compareTo(clock(b.start)));
 final next=s.pending.where((b)=>b.at.isAfter(DateTime.now())).firstOrNull;
 final left=next?.at.difference(DateTime.now());
 return PageBody('Báo thức',[Wrap(spacing:12,crossAxisAlignment:WrapCrossAlignment.center,children:[Text(left==null?'Chưa có báo thức sắp tới':'Báo thức tiếp theo sau ${left.inHours} giờ ${left.inMinutes%60} phút'),TextButton(onPressed:s.testBell,child:const Text('Thử chuông'))]),
 GlassCard(child:Column(children:[if(alarms.isEmpty)const Text('Chưa có báo thức'),for(final e in alarms)Row(children:[
 Expanded(child:InkWell(onTap:()=>editEntry(c,s,entry:e,alarm:true),child:Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(clock(e.days.isEmpty?e.start:DateTime(2000,1,1,e.wallHour??e.start.hour,e.wallMinute??e.start.minute)),style:const TextStyle(fontSize:32,fontWeight:FontWeight.w500)),Text(e.title),Text('${e.days.isEmpty?"Một lần":e.days.map((n)=>weekdays[n-1]).join(", ")}, âm ${e.sound}',style:const TextStyle(fontSize:12))])))),
 Semantics(label:'Bật báo thức ${e.title}',child:CupertinoSwitch(value:e.enabled,activeTrackColor:Theme.of(c).colorScheme.primary,onChanged:(v)async{HapticFeedback.selectionClick();if(v)await s.ask(c);await s.save(e.change({'enabled':v}));}))])])),
 GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading(c,'Nhắc trước contest'),const Text('Chọn các mốc nhắc trước giờ thi.'),Wrap(spacing:6,children:[for(final n in [30,10,5])FilterChip(label:Text('$n phút'),selected:s.leads.contains(n),onSelected:(v)async{if(v)await s.ask(c);final ls=s.leads.toSet();if(v){ls.add(n);}else{ls.remove(n);}await s.setting('contestLeads',ls.toList());})])])),
 if(s.settings['asked']==true)TextButton(onPressed:s.openSettings,child:const Text('Quyền báo thức và thông báo trong Cài đặt'))],
 action:TextButton.icon(onPressed:()=>editEntry(c,s,alarm:true),icon:const Icon(Icons.add),label:const Text('Thêm')));
 }
}
