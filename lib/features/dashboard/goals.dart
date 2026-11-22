import 'package:flutter/material.dart';
import '../../data/controller.dart';
Future<void> editGoals(BuildContext c,Controller s)async{
 final values=List<num>.from(s.settings['goals']??[30,10,4]);
 final form=GlobalKey<FormState>();
 final ok=await showDialog<bool>(context:c,builder:(ctx)=>AlertDialog(title:const Text('Mục tiêu tuần'),content:Form(key:form,child:Column(mainAxisSize:MainAxisSize.min,children:[
 for(var i=0;i<3;i++)TextFormField(initialValue:values[i].toString(),keyboardType:TextInputType.numberWithOptions(decimal:i==1),decoration:InputDecoration(labelText:['Bài giải','Giờ luyện','Contest'][i]),validator:(v){
 final n=num.tryParse((v??'').replaceAll(',','.'));return n==null||!n.isFinite||n<=0||(i!=1&&n!=n.round())?'Nhập mục tiêu dương hợp lệ':null;
 },onSaved:(v)=>values[i]=num.parse(v!.replaceAll(',','.'))) ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Hủy')),FilledButton(onPressed:(){if(form.currentState!.validate()){form.currentState!.save();Navigator.pop(ctx,true);}},child:const Text('Lưu'))]));
 if(ok==true)await s.setting('goals',values);
}
