import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/glass/glass_card.dart';
import '../../core/theme/theme.dart';
import '../../data/controller.dart';
import '../../data/models.dart';
import 'editor.dart';
class Schedule extends StatefulWidget{const Schedule(this.s,{super.key});final Controller s;@override State<Schedule> createState()=>_Schedule();}
class _Schedule extends State<Schedule>{
 DateTime selected=day(DateTime.now());bool? weekMode;double dx=0;
 @override Widget build(BuildContext c){
 final week=weekMode??MediaQuery.sizeOf(c).width>=720;
 final monday=day(selected,1-selected.weekday);final dates=week?List.generate(5,(i)=>day(monday,i)):[selected];
 final entries=widget.s.entries.where((e)=>!e.alarm&&dates.contains(day(e.start))).toList();
 final first=entries.fold<int>(8,(a,e)=>math.min(a,e.start.hour));final last=entries.fold<int>(20,(a,e)=>math.max(a,(e.start.hour+(e.start.minute+e.minutes)/60).ceil().clamp(1,24).toInt()));
 const hour=60.0;final height=(last-first)*hour;
 Widget dayColumn(DateTime d)=>Expanded(child:Column(children:[SizedBox(height:48,child:Center(child:Text('${weekdays[d.weekday-1]}, ${d.day}',style:TextStyle(color:d==day(DateTime.now())?Theme.of(c).colorScheme.primary:null)))),
 Builder(builder:(target)=>DragTarget<Entry>(onAcceptWithDetails:(details){
 final box=target.findRenderObject() as RenderBox;final y=box.globalToLocal(details.offset).dy;
 final m=((first*60+y/hour*60)/15).round().clamp(0,95)*15;
 widget.s.save(details.data.change({'start':utc(DateTime(d.year,d.month,d.day,0,m.toInt()))}));HapticFeedback.mediumImpact();
 },builder:(_,over,__)=>Container(height:height,decoration:BoxDecoration(border:Border(left:BorderSide(color:Theme.of(c).dividerColor)),color:over.isEmpty?null:Theme.of(c).colorScheme.primary.withValues(alpha:.07)),child:Stack(children:[
 for(var i=0;i<last-first;i++)Positioned(left:0,right:0,top:i*hour,child:const Divider(height:1)),
 for(final e in entries.where((e)=>day(e.start)==d))Positioned(top:(e.start.hour-first+e.start.minute/60)*hour,left:3,right:2,height:math.max(44.0,math.min(e.minutes.toDouble(),height-(e.start.hour-first+e.start.minute/60)*hour)),child:LongPressDraggable<Entry>(data:e,feedback:Material(borderRadius:BorderRadius.circular(12),child:Padding(padding:const EdgeInsets.all(12),child:Text(e.title))),child:InkWell(onTap:()=>editEntry(c,widget.s,entry:e),child:Container(padding:const EdgeInsets.all(5),decoration:BoxDecoration(color:platforms[e.platform]!.withValues(alpha:.11),border:Border(left:BorderSide(color:platforms[e.platform]!,width:3)),borderRadius:BorderRadius.circular(8)),child:SingleChildScrollView(physics:const NeverScrollableScrollPhysics(),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(clock(e.start),style:const TextStyle(fontSize:11)),Text(e.title,style:const TextStyle(fontWeight:FontWeight.w700)),Text(e.platform,style:const TextStyle(fontSize:11))]))))))]))))]));
 void shift(int n)=>setState(()=>selected=day(selected,n));
 return PageBody('Thời khóa biểu',[Wrap(alignment:WrapAlignment.spaceBetween,crossAxisAlignment:WrapCrossAlignment.center,children:[
 SegmentedButton<bool>(segments:const [ButtonSegment(value:true,label:Text('Tuần')),ButtonSegment(value:false,label:Text('Ngày'))],selected:{week},onSelectionChanged:(v)=>setState(()=>weekMode=v.first)),
 TextButton.icon(onPressed:()=>editEntry(c,widget.s,initial:DateTime(selected.year,selected.month,selected.day,9)),icon:const Icon(Icons.add),label:const Text('Thêm buổi'))]),
 GlassCard(padding:8,child:Column(children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[IconButton(tooltip:'Trước',onPressed:()=>shift(week?-7:-1),icon:const Icon(Icons.chevron_left)),Text(week?'${monday.day} - ${day(monday,6).day} tháng ${day(monday,6).month}':'${selected.day} tháng ${selected.month}'),IconButton(tooltip:'Sau',onPressed:()=>shift(week?7:1),icon:const Icon(Icons.chevron_right))]),
 GestureDetector(onHorizontalDragStart:(_)=>dx=0,onHorizontalDragUpdate:(v)=>dx+=v.delta.dx,onHorizontalDragEnd:(_){if(dx.abs()>36)shift((dx<0?1:-1)*(week?7:1));},child:SingleChildScrollView(scrollDirection:Axis.horizontal,physics:week?null:const NeverScrollableScrollPhysics(),child:SizedBox(width:math.max(week?650.0:0.0,MediaQuery.sizeOf(c).width-(MediaQuery.sizeOf(c).width>=720?260:56)),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Column(children:[const SizedBox(height:48),for(var i=first;i<last;i++)SizedBox(height:hour,child:Text('${i.toString().padLeft(2,"0")}:00',style:const TextStyle(fontSize:11)))]),for(final d in dates)dayColumn(d)]))))])),
 const Text('Giữ và kéo một buổi luyện để đổi ngày',textAlign:TextAlign.center)]);
 }
}
