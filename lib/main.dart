import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/theme.dart';
import 'core/glass/glass_card.dart';
import 'data/controller.dart';
import 'data/models.dart';
import 'features/dashboard/dashboard.dart';
import 'features/schedule/schedule.dart';
import 'features/alarms/alarms.dart';
import 'features/alarms/ringing.dart';
import 'features/progress/progress.dart';
import 'features/accounts/accounts.dart';

Future<void> main() async{
 WidgetsFlutterBinding.ensureInitialized();await initializeDateFormatting('vi');
 final model=await Controller.open();runApp(ProviderScope(overrides:[app.overrideWith((ref)=>model)],child:const Application()));
}
final navigator=GlobalKey<NavigatorState>();
final messages=GlobalKey<ScaffoldMessengerState>();
class Application extends ConsumerWidget{
 const Application({super.key});
 @override Widget build(BuildContext c,WidgetRef ref){
 final mode=ref.watch(app.select((s)=>s.settings['theme'] as String?));
 return MaterialApp(title:'CP Alarm',debugShowCheckedModeBanner:false,navigatorKey:navigator,scaffoldMessengerKey:messages,
 theme:appearance(Brightness.light),darkTheme:appearance(Brightness.dark),themeMode:ThemeMode.values.byName(mode??'system'),
 locale:const Locale('vi'),supportedLocales:const [Locale('vi')],localizationsDelegates:GlobalMaterialLocalizations.delegates,home:const Home());
 }
}
class Home extends ConsumerStatefulWidget{const Home({super.key});@override ConsumerState<Home> createState()=>_Home();}
class _Home extends ConsumerState<Home> with WidgetsBindingObserver{
 int tab=0;bool expanded=false,ringing=false;late final StreamSubscription<Bell> sub;
 final names=['Hôm nay','Lịch','Báo thức','Tiến độ','Kết nối'];
 final icons=[Icons.schedule,Icons.calendar_month_outlined,Icons.alarm,Icons.bar_chart,Icons.person_outline];
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);final s=ref.read(app);
 sub=s.alerts.stream.listen(showRing);WidgetsBinding.instance.addPostFrameCallback((_){s.resume();});}
 @override void didChangeAppLifecycleState(AppLifecycleState state){final s=ref.read(app);s.active=state==AppLifecycleState.resumed;if(s.active)s.resume();}
 @override void dispose(){sub.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();}
 Future<void> showRing(Bell b)async{
 if(ringing)return;ringing=true;final s=ref.read(app);
 try{await navigator.currentState!.push(MaterialPageRoute(fullscreenDialog:true,builder:(_)=>Ringing(b,s)));}finally{ringing=false;}
 }
 @override Widget build(BuildContext c){
 final s=ref.watch(app);final wide=MediaQuery.sizeOf(c).width>=720;
 final pages=[Dashboard(s,(i)=>setState(()=>tab=i)),Schedule(s),Alarms(s),Progress(s),Accounts(s)];
 Widget nav(int i,{bool side=false})=>Tooltip(message:names[i],child:Semantics(selected:i==tab,button:true,child:InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>setState(()=>tab=i),
 child:ConstrainedBox(constraints:const BoxConstraints(minHeight:56,minWidth:44),child:side?Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icons[i],color:i==tab?Theme.of(c).colorScheme.primary:null),if(expanded)Padding(padding:const EdgeInsets.all(8),child:Text(names[i]))]):Column(mainAxisSize:MainAxisSize.min,mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icons[i],size:21,color:i==tab?Theme.of(c).colorScheme.primary:null),Text(names[i],style:const TextStyle(fontSize:11))])))));
 final theme=PopupMenuButton<String>(tooltip:'Giao diện',icon:const Icon(Icons.brightness_6_outlined),onSelected:(v)=>s.setting('theme',v),itemBuilder:(_)=>['system','light','dark'].asMap().entries.map((e)=>PopupMenuItem(value:e.value,child:Text(['Theo hệ thống','Giao diện sáng','Giao diện tối'][e.key]))).toList());
 return Scaffold(body:DecoratedBox(decoration:BoxDecoration(gradient:RadialGradient(center:const Alignment(-1,-1),radius:1.45,colors:[Theme.of(c).colorScheme.primary.withValues(alpha:.09),Colors.transparent])),
 child:SafeArea(child:Row(children:[
 if(wide)Padding(padding:const EdgeInsets.all(12),child:GlassCard(padding:8,child:SizedBox(width:expanded?164:56,child:Column(children:[IconButton(tooltip:'Thu gọn hoặc mở rộng',icon:const Icon(Icons.menu),onPressed:()=>setState(()=>expanded=!expanded)),const Text('CP'),for(var i=0;i<5;i++)nav(i,side:true),const Spacer(),theme])))),
 Expanded(child:Stack(children:[Column(children:[if(!wide)Align(alignment:Alignment.centerRight,child:theme),if(s.notice!=null)MaterialBanner(content:Text(s.notice!),actions:[TextButton(onPressed:s.clearNotice,child:const Text('Đóng'))]),Expanded(child:pages[tab])]),
 if(!wide)Positioned(bottom:6,left:10,right:10,child:GlassCard(radius:25,padding:5,child:Row(children:[for(var i=0;i<5;i++)Expanded(child:nav(i))]))) ]))]))));
 }
}
