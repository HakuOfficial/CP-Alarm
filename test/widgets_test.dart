import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cp_alarm/core/glass/glass_card.dart';
import 'package:cp_alarm/features/dashboard/rolling.dart';
void main(){
 testWidgets('GlassCard giữ nội dung và vùng blur',(t)async{
 await t.pumpWidget(const MaterialApp(home:GlassCard(child:Text('Thời khóa biểu'))));expect(find.text('Thời khóa biểu'),findsOneWidget);expect(find.byType(BackdropFilter),findsOneWidget);
 });
 testWidgets('Số lăn dừng ở chữ số mới khi giảm chuyển động',(t)async{
 Widget digit(int n)=>MaterialApp(home:MediaQuery(data:const MediaQueryData(disableAnimations:true),child:Center(child:RollingDigit(n))));
 await t.pumpWidget(digit(1));await t.pumpWidget(digit(8));await t.pump();
 expect(t.getCenter(find.text('8')).dy,closeTo(t.getCenter(find.byType(RollingDigit)).dy,1));
 });
}
