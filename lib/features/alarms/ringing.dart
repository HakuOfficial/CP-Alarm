import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/theme.dart';
import '../../data/models.dart';
import '../../data/controller.dart';
class Ringing extends StatefulWidget{const Ringing(this.b,this.s,{super.key});final Bell b;final Controller s;@override State<Ringing> createState()=>_Ringing();}
class _Ringing extends State<Ringing> with SingleTickerProviderStateMixin{
 late final AnimationController anim=AnimationController(vsync:this,duration:const Duration(seconds:3));double slide=0;bool done=false,busy=false;
 @override void initState(){super.initState();widget.s.beginRinging(widget.b);}
 @override void didChangeDependencies(){super.didChangeDependencies();if(MediaQuery.disableAnimationsOf(context)){anim.stop();}else{anim.repeat(reverse:true);}}
 @override void dispose(){anim.dispose();widget.s.silence();super.dispose();}
 Future<void> finish(bool snooze)async{if(busy)return;busy=true;
 try{if(snooze){await widget.s.ask(context);await widget.s.snooze(widget.b);}await widget.s.dismiss(widget.b);await HapticFeedback.mediumImpact();if(mounted)setState(()=>done=true);}finally{busy=false;}}
 @override Widget build(BuildContext c){final b=widget.b;return Scaffold(body:Stack(fit:StackFit.expand,children:[AnimatedBuilder(animation:anim,builder:(c,_)=>DecoratedBox(decoration:BoxDecoration(gradient:RadialGradient(center:Alignment(-.6+anim.value*.5,-.55+anim.value*.25),radius:.8,colors:[Theme.of(c).colorScheme.primary.withValues(alpha:.34),Colors.transparent])))),BackdropFilter(filter:ImageFilter.blur(sigmaX:20,sigmaY:20),child:const SizedBox.expand()),
 SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(30),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:done?[const Icon(Icons.check_circle_outline,size:64),Text('Đã tắt báo thức',style:Theme.of(c).textTheme.headlineMedium),const Text('Chúc thi tốt.'),TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Về trang chủ'))]:[
 Text(b.title),FittedBox(child:Text(clock(b.at),style:const TextStyle(fontSize:82,fontWeight:FontWeight.w600,letterSpacing:-4))),Text(b.start.isAfter(b.at)?'Contest bắt đầu sau ${b.start.difference(b.at).inMinutes} phút':'Đã đến giờ bắt đầu',textAlign:TextAlign.center,style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:10),const Text('Đăng nhập sẵn, kiểm tra compiler, rót cốc nước.',textAlign:TextAlign.center),
 SizedBox(height:90,child:AnimatedBuilder(animation:anim,builder:(_,__)=>Row(mainAxisAlignment:MainAxisAlignment.center,children:[for(var i=0;i<18;i++)Container(width:3,height:8+32*math.sin(i*.58+anim.value*5).abs(),margin:const EdgeInsets.symmetric(horizontal:2),decoration:BoxDecoration(color:Theme.of(c).colorScheme.primary,borderRadius:BorderRadius.circular(4)))]))),
 Semantics(label:'Trượt để tắt',onTap:()=>finish(false),child:LayoutBuilder(builder:(c,bounds)=>GestureDetector(onHorizontalDragUpdate:(d)=>setState(()=>slide=(slide+d.delta.dx/(bounds.maxWidth-56)).clamp(0,1).toDouble()),onHorizontalDragEnd:(_){if(slide>=.88){finish(false);}else{setState(()=>slide=0);}},child:Container(height:56,decoration:BoxDecoration(borderRadius:BorderRadius.circular(28),color:Theme.of(c).colorScheme.onSurface.withValues(alpha:.09)),child:Stack(alignment:Alignment.center,children:[const Text('Trượt để tắt'),Align(alignment:Alignment(slide*2-1,0),child:CircleAvatar(radius:26,backgroundColor:Theme.of(c).colorScheme.primary,child:const Icon(Icons.chevron_right,color:Colors.black)))]))))),
 TextButton(onPressed:()=>finish(true),child:const Text('Nhắc lại sau 5 phút'))]))))]));}
}
