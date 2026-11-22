import 'package:flutter/material.dart';
class RollingDigit extends StatelessWidget{
 const RollingDigit(this.digit,{super.key}); final int digit;
 @override Widget build(BuildContext c)=>SizedBox(width:36,height:72,child:ClipRect(child:TweenAnimationBuilder<double>(
  tween:Tween<double>(end:digit.toDouble()),duration:Duration(milliseconds:MediaQuery.disableAnimationsOf(c)?0:420),curve:Curves.easeOutExpo,
  builder:(c,v,_)=>Stack(clipBehavior:Clip.none,children:[for(var i=0;i<10;i++)Positioned(top:(i-v)*72,left:0,right:0,height:72,
    child:Center(child:Text('$i',style:const TextStyle(fontSize:50,height:1.15,fontWeight:FontWeight.w500,fontFeatures:[FontFeature.tabularFigures()]))))]))));
}
