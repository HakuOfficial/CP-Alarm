import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models.dart';
class SystemAlarms{
 static const channel=MethodChannel('cp_alarm/system');
 final plugin=FlutterLocalNotificationsPlugin();Bell? launch;
 IOSFlutterLocalNotificationsPlugin? get ios=>plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
 Future<void> init(void Function(Bell) tap)async{
 tzdata.initializeTimeZones();const options=DarwinInitializationSettings(requestAlertPermission:false,requestBadgePermission:false,requestSoundPermission:false,defaultPresentAlert:false,defaultPresentSound:false,defaultPresentBanner:false,defaultPresentList:false);
 await plugin.initialize(settings:const InitializationSettings(iOS:options),onDidReceiveNotificationResponse:(r){if(r.payload!=null)tap(Bell.from(jsonDecode(r.payload!)));});
 final started=await plugin.getNotificationAppLaunchDetails();final payload=started?.notificationResponse?.payload;if(started?.didNotificationLaunchApp==true&&payload!=null)launch=Bell.from(jsonDecode(payload));
 }
 Future<void> request()async{try{await channel.invokeMethod<bool>('authorize');}on PlatformException{/* Local notifications have independent authorization. */}await ios?.requestPermissions(alert:true,sound:true,badge:false);}
 Future<String?> replace(List<Bell> bells)async{
 final native=await channel.invokeMethod<bool>('authorized')??false;
 final local=(await ios?.checkPermissions())?.isEnabled??false;
 await plugin.cancelAllPendingNotifications();
 final ids=await channel.invokeListMethod<String>('keys')??[];
 final wanted=bells.where((b)=>native&&!b.reminder).map((b)=>b.key).toSet();
 for(final id in ids.where((k)=>!wanted.contains(k))){try{await channel.invokeMethod('cancel',{'key':id});}on PlatformException{if(native)rethrow;}}
 int fallback=0,missing=0;
 for(var i=0;i<bells.length;i++){
 final b=bells[i];if(!b.at.isAfter(DateTime.now()))continue;
 if(native&&!b.reminder){
 try{await channel.invokeMethod('schedule',b.json);continue;}on PlatformException{fallback++;}
 }
 if(!local){missing++;continue;}
 await plugin.zonedSchedule(id:i+1,title:b.title,body:b.reminder?'Bắt đầu sau ${b.start.difference(b.at).inMinutes} phút':'Đã đến giờ bắt đầu',
 scheduledDate:tz.TZDateTime.from(b.at,tz.UTC),notificationDetails:NotificationDetails(iOS:DarwinNotificationDetails(sound:'${b.sound}.wav',presentSound:false,presentAlert:false,presentBanner:false,presentList:false)),androidScheduleMode:AndroidScheduleMode.exactAllowWhileIdle,payload:jsonEncode(b.json));
 }
 if(missing>0)return '$missing mốc chưa được đặt. Hãy bật quyền trong Cài đặt.';
 if(fallback>0)return 'Đã chuyển $fallback báo thức sang thông báo iOS.';
 if(!native&&bells.isNotEmpty&&local)return 'Đang dùng thông báo iOS. Âm thanh phụ thuộc chế độ im lặng và Tập trung.';
 return null;
 }
}
