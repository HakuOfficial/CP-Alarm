import 'dart:ui';
import 'package:flutter/material.dart';
class GlassCard extends StatelessWidget {
  const GlassCard({super.key,required this.child,this.radius=28,this.padding=20});
  final Widget child;
  final double radius,padding;
  @override Widget build(BuildContext context){
    final dark=Theme.of(context).brightness==Brightness.dark;
    final corners=BorderRadius.circular(radius);
    return DecoratedBox(decoration:BoxDecoration(borderRadius:corners,boxShadow:[
      BoxShadow(color:Colors.black.withValues(alpha:dark ? .22 : .08),blurRadius:32,offset:const Offset(0,12))]),
      child:ClipRRect(borderRadius:corners,child:BackdropFilter(filter:ImageFilter.blur(sigmaX:30,sigmaY:30),
        child:Container(padding:EdgeInsets.all(padding),decoration:BoxDecoration(borderRadius:corners,
          gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:dark?
            [const Color(0xb7292a30),const Color(0xa31c1d22)]:[const Color(0xcaffffff),const Color(0xa8ffffff)]),
          border:Border.all(color:dark?Colors.white12:Colors.black12)),child:child))));
  }
}
class PageBody extends StatelessWidget{
  const PageBody(this.title,this.items,{super.key,this.subtitle,this.action});
  final String title;final String? subtitle;final Widget? action;final List<Widget> items;
  @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.fromLTRB(18,14,18,112),children:[
    if(subtitle!=null) Text(subtitle!),Row(children:[Expanded(child:Text(title,style:Theme.of(c).textTheme.headlineMedium)),?action]),
    const SizedBox(height:18),for(final w in items) Padding(padding:const EdgeInsets.only(bottom:16),child:w)]);
}
Widget heading(BuildContext c,String s)=>Text(s,style:Theme.of(c).textTheme.titleLarge);
