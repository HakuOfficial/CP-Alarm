import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/glass/glass_card.dart';
import '../../core/theme/theme.dart';
import '../../data/controller.dart';
import '../../data/models.dart';
import 'stats.dart';
class Progress extends StatefulWidget{const Progress(this.s,{super.key});final Controller s;@override State<Progress> createState()=>_Progress();}
class _Progress extends State<Progress>{
 String filter='Tất cả';DateTime? cell;
 @override Widget build(BuildContext c){
 final s=widget.s,now=DateTime.now();bool accepts(String p)=>filter=='Tất cả'||filter==p;
 final stats=Stats(s.submissions.where((e)=>accepts(e.platform)),now);
 final total={...stats.solved.keys,for(final p in s.knownSolved.keys.where(accepts))for(final q in s.knownSolved[p]!)'$p/$q'}.length;
 final points=s.ratings.where((r)=>accepts(r.platform)).toList()..sort((a,b)=>a.at.compareTo(b.at));
 final latest=points.lastOrNull;final bins=stats.difficulty;
 final mins=s.entries.where((e)=>e.done&&!e.alarm&&accepts(e.platform)).fold<int>(0,(a,e)=>a+e.minutes);
 final tags=stats.tags.entries.toList()..sort((a,b)=>(b.value.$1/b.value.$2).compareTo(a.value.$1/a.value.$2));
 final accent=Theme.of(c).colorScheme.primary;
 return PageBody('Tiến độ',[DropdownButton<String>(value:filter,items:[for(final p in ['Tất cả',...platforms.keys])DropdownMenuItem(value:p,child:Text(p))],onChanged:(v)=>setState((){filter=v!;cell=null;})),
 GlassCard(radius:20,padding:14,child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[for(final pair in [('Rating hiện tại',latest?.value.toString()??'—'),('Bài đã giải','$total'),('Thời gian luyện','${(mins/60).toStringAsFixed(1)}h')])Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(pair.$1,style:const TextStyle(fontSize:12)),Text(pair.$2,style:Theme.of(c).textTheme.titleLarge),if(pair.$1=='Rating hiện tại'&&filter=='Tất cả'&&latest!=null)Text(latest.platform,style:const TextStyle(fontSize:11))]))])),
 GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading(c,'Rating 5 tháng gần đây'),if(latest==null)const Text('Chưa có lịch sử rating') else for(final p in points.map((e)=>e.platform).toSet())...[
 Text(p),RatingChart(points.where((r)=>r.platform==p&&!r.at.isBefore(DateTime(now.year,now.month-4))).toList(),platforms[p]!)] ])),
 GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading(c,'Phân bố độ khó'),for(var i=0;i<4;i++)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(children:[SizedBox(width:90,child:Text(['≤ 1200','1300–1600','1700–2000','2100+'][i])),Expanded(child:LinearProgressIndicator(value:bins[i]/bins.fold<int>(1,math.max),color:i==3?accent:Theme.of(c).colorScheme.outline)),SizedBox(width:32,child:Text('${bins[i]}',textAlign:TextAlign.end))]))])),
 GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading(c,'Số bài mỗi ngày'),Text('${stats.streak} ngày liên tiếp'),const SizedBox(height:12),
 SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[Column(children:[for(final d in weekdays)SizedBox(height:44,child:Center(child:Text(d,style:const TextStyle(fontSize:11))))]),for(var w=0;w<12;w++)Column(children:[for(var j=0;j<7;j++)Builder(builder:(ctx){
 final d=stats.heat[w*7+j],n=stats.level(d);return Semantics(label:'${DateFormat("dd/MM").format(d)}, ${stats.count(d)} bài',button:true,child:InkWell(onTap:()=>setState(()=>cell=d),child:SizedBox.square(dimension:44,child:Center(child:Container(width:28,height:28,decoration:BoxDecoration(borderRadius:BorderRadius.circular(5),border:d==cell?Border.all(color:accent,width:2):null,color:n==0?Theme.of(c).colorScheme.onSurface.withValues(alpha:.07):accent.withValues(alpha:[0,.28,.48,.70,1][n].toDouble())))))));})])])),Text(cell==null?'12 tuần, từ thứ Hai đến Chủ nhật':'${DateFormat("dd/MM/yyyy").format(cell!)}: ${stats.count(cell!)} bài')])),
 GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading(c,'Chủ đề mạnh'),if(tags.isEmpty)const Text('Chưa có dữ liệu tag'),Wrap(spacing:8,children:[for(final t in tags)Chip(label:Text('${t.key}   ${(100*t.value.$1/t.value.$2).round()}%'))])])),
 ]);
 }
}
class RatingChart extends StatefulWidget{
 const RatingChart(this.points,this.color,{super.key});final List<RatingPoint> points;final Color color;
 @override State<RatingChart> createState()=>_RatingChart();
}
class _RatingChart extends State<RatingChart>{int? selected;
 @override Widget build(BuildContext c){
 final pts=widget.points;if(pts.isEmpty)return const Text('Chưa có dữ liệu trong kỳ này');
 final lo=pts.first.at.millisecondsSinceEpoch,span=math.max(1,pts.last.at.millisecondsSinceEpoch-lo);
 return LayoutBuilder(builder:(c,b)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[GestureDetector(onTapDown:(d){final t=lo+span*d.localPosition.dx/b.maxWidth;int best=0;for(var i=1;i<pts.length;i++){if((pts[i].at.millisecondsSinceEpoch-t).abs()<(pts[best].at.millisecondsSinceEpoch-t).abs())best=i;}setState(()=>selected=best);},
 child:TweenAnimationBuilder<double>(tween:Tween(begin:0,end:1),duration:Duration(milliseconds:MediaQuery.disableAnimationsOf(c)?0:350),builder:(c,v,_)=>CustomPaint(size:Size(b.maxWidth,130),painter:_Line(pts,widget.color,v,selected)))),
 Text(selected!=null&&selected!<pts.length?'${DateFormat("dd/MM/yyyy").format(pts[selected!].at.toLocal())}: ${pts[selected!].value}':'${DateFormat("dd/MM").format(pts.first.at.toLocal())} — ${DateFormat("dd/MM").format(pts.last.at.toLocal())}')]));
 }
}
class _Line extends CustomPainter{
 _Line(this.pts,this.color,this.progress,this.selected);final List<RatingPoint> pts;final Color color;final double progress;final int? selected;
 @override void paint(Canvas c,Size s){final ys=pts.map((p)=>p.value);final min=ys.reduce(math.min),max=ys.reduce(math.max);
 final span=math.max(1,pts.last.at.difference(pts.first.at).inSeconds);final path=Path();final pen=Paint()..color=color..strokeWidth=3..style=PaintingStyle.stroke;
 for(var i=0;i<pts.length;i++){final x=4+(s.width-8)*pts[i].at.difference(pts.first.at).inSeconds/span;final y=s.height-8-(s.height-16)*(pts[i].value-min)/math.max(1,max-min);
 if(i==0){path.moveTo(x,y);}else{path.lineTo(x,y);}if(i==selected||pts.length==1)c.drawCircle(Offset(x,y),4,Paint()..color=color);}
 c.clipRect(Rect.fromLTWH(0,0,s.width*progress,s.height));c.drawPath(path,pen);
 }
 @override bool shouldRepaint(_Line old)=>true;
}
