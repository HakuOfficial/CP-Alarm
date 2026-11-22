import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../data/controller.dart';
import '../../data/models.dart';
Future<void> editEntry(BuildContext c,Controller s,{Entry? entry,DateTime? initial,bool alarm=false})async{
 final now=DateTime.now();var at=entry?.start??initial??now.add(const Duration(hours:1));
 if(entry!=null&&entry.days.isNotEmpty){at=DateTime(at.year,at.month,at.day,entry.wallHour??at.hour,entry.wallMinute??at.minute);}
 final title=TextEditingController(text:entry?.title);final minutes=TextEditingController(text:(entry?.minutes??60).toString());
 var platform=entry?.platform??'Codeforces',sound=entry?.sound??'Radar',done=entry?.done??false;
 final days={...?entry?.days},leads={...?entry?.leads};String? error;
 final result=await showModalBottomSheet<String>(context:c,isScrollControlled:true,useSafeArea:true,builder:(ctx)=>StatefulBuilder(builder:(ctx,update)=>Padding(
 padding:EdgeInsets.fromLTRB(20,16,20,MediaQuery.viewInsetsOf(ctx).bottom+16),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
 Text('${entry==null?"Thêm":"Sửa"} ${alarm?"báo thức":"buổi luyện"}',style:Theme.of(ctx).textTheme.titleLarge),
 TextField(controller:title,decoration:InputDecoration(labelText:'Tiêu đề',errorText:error)),Wrap(spacing:12,children:[
 TextButton(onPressed:()async{final d=await showDatePicker(context:ctx,initialDate:at,firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null)update(()=>at=DateTime(d.year,d.month,d.day,at.hour,at.minute));},child:Text('${at.day}/${at.month}/${at.year}')),
 TextButton(onPressed:()async{final t=await showTimePicker(context:ctx,initialTime:TimeOfDay.fromDateTime(at));if(t!=null)update(()=>at=DateTime(at.year,at.month,at.day,t.hour,t.minute));},child:Text(clock(at)))]),
 if(!alarm)...[DropdownButton<String>(value:platform,items:[for(final p in platforms.keys)DropdownMenuItem(value:p,child:Text(p))],onChanged:(v)=>update(()=>platform=v!)),
 TextField(controller:minutes,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Thời lượng (phút)')),
 if(!at.isAfter(now))CheckboxListTile(value:done,onChanged:(v)=>update(()=>done=v!),title:const Text('Đã hoàn thành'))],
 if(alarm)...[const Text('Lặp'),Wrap(spacing:4,children:[for(var i=1;i<=7;i++)FilterChip(label:Text(weekdays[i-1]),selected:days.contains(i),onSelected:(v)=>update((){if(v){days.add(i);}else{days.remove(i);}}))])],
 const Text('Nhắc trước'),Wrap(spacing:8,children:[for(final i in [30,10,5])FilterChip(label:Text('$i phút'),selected:leads.contains(i),onSelected:(v)=>update((){if(v){leads.add(i);}else{leads.remove(i);}}))]),
 DropdownButton<String>(value:sound,items:[for(final a in ['Radar','Apex'])DropdownMenuItem(value:a,child:Text('Âm $a'))],onChanged:(v)=>update(()=>sound=v!)),
 Row(children:[if(entry!=null)TextButton(onPressed:()=>Navigator.pop(ctx,'delete'),child:const Text('Xóa')),const Spacer(),FilledButton(onPressed:(){
 if(title.text.trim().isEmpty||(int.tryParse(minutes.text)??0)<=0||(alarm&&days.isEmpty&&!at.isAfter(DateTime.now()))){update(()=>error='Kiểm tra tiêu đề, thời lượng và thời điểm báo thức.');return;}Navigator.pop(ctx,'save');},child:const Text('Lưu'))])])))));
 if(result=='delete'&&entry!=null){await s.remove(entry.id);}
 if(result=='save'){if(c.mounted&&!done)await s.ask(c);
 await s.save(Entry(entry?.id??now.microsecondsSinceEpoch.toString(),title.text.trim(),at,platform:platform,minutes:int.parse(minutes.text),alarm:alarm,enabled:entry?.enabled??true,days:days.toList()..sort(),leads:leads.toList(),sound:sound,done:done));}
 // The bottom sheet retains its text fields during its reverse animation.
 Future.delayed(const Duration(milliseconds:500),(){title.dispose();minutes.dispose();});
}
