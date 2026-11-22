import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/glass/glass_card.dart';
import '../../core/theme/theme.dart';
import '../../data/controller.dart';
import '../../data/models.dart';
class Accounts extends StatelessWidget{
 const Accounts(this.s,{super.key});final Controller s;
 Future<void> link(BuildContext c,String p)async{
 String u='',base=s.base;final ok=await showDialog<bool>(context:c,builder:(ctx)=>AlertDialog(title:Text('Liên kết $p'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(autocorrect:false,onChanged:(v)=>u=v,decoration:const InputDecoration(labelText:'Username')),if(p=='ChuyênTin')TextFormField(initialValue:base,onChanged:(v)=>base=v,decoration:const InputDecoration(labelText:'Địa chỉ HTTPS của OJ'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Hủy')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Liên kết'))]));
 if(ok==true)await s.link(p,u.trim(),base.trim());
 }
 @override Widget build(BuildContext c)=>PageBody('Liên kết tài khoản',[const Text('Chỉ cần username, không cần mật khẩu.'),for(final p in platforms.keys)GlassCard(padding:16,radius:22,child:Row(children:[Container(width:46,height:46,alignment:Alignment.center,decoration:BoxDecoration(color:platforms[p],borderRadius:BorderRadius.circular(15)),child:Text(p.substring(0,2).toUpperCase(),style:const TextStyle(color:Colors.black,fontWeight:FontWeight.w800))),const SizedBox(width:12),
 Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p,style:const TextStyle(fontWeight:FontWeight.w700)),Text(s.accounts[p]==null?'Chưa liên kết':'@${s.accounts[p]!["u"]}'),if(s.syncing.contains(p))const Text('Đang đồng bộ…'),if(s.accounts[p]?['last']!=null)Text('Lần cuối ${DateFormat("dd/MM HH:mm").format(instant(s.accounts[p]!["last"] as int).toLocal())}',style:const TextStyle(fontSize:12)),if(s.accounts[p]?['error']!=null)Text(s.accounts[p]!['error'] as String)])),
 if(s.accounts[p]==null)TextButton(onPressed:s.syncing.contains(p)?null:()=>link(c,p),child:const Text('Liên kết')) else PopupMenuButton<String>(tooltip:'Tùy chọn $p',enabled:!s.syncing.contains(p),onSelected:(v)async{if(v=='sync'){await s.sync(p);}else{await s.unlink(p);}},itemBuilder:(_)=>const [PopupMenuItem(value:'sync',child:Text('Đồng bộ')),PopupMenuItem(value:'unlink',child:Text('Ngắt liên kết'))])])),
 const Text('Dữ liệu được đồng bộ trực tiếp từ hồ sơ công khai. CP Alarm không bao giờ yêu cầu mật khẩu nền tảng.')]);
}
