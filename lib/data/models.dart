typedef Json = Map<String,dynamic>;
int utc(DateTime d)=>d.toUtc().millisecondsSinceEpoch~/1000;
DateTime instant(int n)=>DateTime.fromMillisecondsSinceEpoch(n*1000,isUtc:true);
class Submission{
 const Submission(this.platform,this.id,this.problemId,this.verdict,this.submittedAt,this.language,{this.rating,this.tags=const []});
 final String platform,id,problemId,verdict,language;
 final DateTime submittedAt;final int? rating; final List<String> tags;
 bool get ac=>const {'AC','OK','ACCEPTED'}.contains(verdict.toUpperCase());
 Json get json=>{'id':id,'p':platform,'q':problemId,'v':verdict,'t':utc(submittedAt),'l':language,'r':rating,'tags':tags};
 factory Submission.from(Json j)=>Submission(j['p'],j['id'],j['q'],j['v'],instant(j['t']),j['l'],rating:j['r'],tags:List<String>.from(j['tags']));
}
class RatingPoint{
 const RatingPoint(this.platform,this.at,this.value);
 final String platform;final DateTime at;final int value;
}
class Contest{
 const Contest(this.platform,this.id,this.title,this.start,this.minutes);
 final String platform,id,title;final DateTime start;final int minutes;
}
class Entry{
 Entry(this.id,this.title,this.start,{this.platform='Codeforces',this.minutes=60,this.alarm=false,this.enabled=true,this.days=const [],this.leads=const [],this.sound='Radar',this.done=false,this.wallHour,this.wallMinute});
 final String id,title,platform,sound; final DateTime start;
 final int? wallHour,wallMinute;
 final int minutes;final bool alarm,enabled,done;final List<int> days,leads;
 Json get json=>{'id':id,'title':title,'start':utc(start),'p':platform,'minutes':minutes,'alarm':alarm,'enabled':enabled,'days':days,'leads':leads,'sound':sound,'done':done,'wallHour':wallHour??start.hour,'wallMinute':wallMinute??start.minute};
 factory Entry.from(Json j)=>Entry(j['id'],j['title'],instant(j['start']).toLocal(),platform:j['p'],minutes:j['minutes'],alarm:j['alarm'],enabled:j['enabled'],days:List<int>.from(j['days']),leads:List<int>.from(j['leads']),sound:j['sound'],done:j['done']??false,wallHour:j['wallHour'],wallMinute:j['wallMinute']);
 Entry change(Json patch)=>Entry.from({...json,...patch});
}
class Bell{
 Bell(this.key,this.title,this.at,this.start,this.sound,{this.reminder=false});
 final String key,title,sound;final DateTime at,start;final bool reminder;
 Json get json=>{'key':key,'title':title,'at':utc(at),'start':utc(start),'sound':sound,'reminder':reminder};
 factory Bell.from(Json j)=>Bell(j['key'],j['title'],instant(j['at']).toLocal(),instant(j['start']).toLocal(),j['sound'],reminder:j['reminder']==true);
}
List<Bell> plan(Iterable<Entry> entries,Iterable<Contest> contests,DateTime now,List<int> contestLeads){
 final result=<Bell>[];
 void add(String id,String title,DateTime start,String sound,Iterable<int> offsets){
   for(final n in offsets.toSet()){
     final at=start.subtract(Duration(minutes:n));
     if(at.isAfter(now))result.add(Bell('$id/${utc(start)}/$n',title,at,start,sound,reminder:n>0));
   }
 }
 for(final e in entries.where((x)=>x.enabled)){
   if(e.days.isEmpty){add(e.id,e.title,e.start,e.sound,[0,...e.leads]);continue;}
   for(var i=0;i<=14;i++){
     final d=DateTime(now.year,now.month,now.day+i,e.wallHour??e.start.hour,e.wallMinute??e.start.minute);
     if(e.days.contains(d.weekday)&&!d.isBefore(e.start))add(e.id,e.title,d,e.sound,[0,...e.leads]);
   }
 }
 for(final c in contests){add('${c.platform}/${c.id}',c.title,c.start,'Radar',contestLeads);}
 result.sort((a,b){final n=a.at.compareTo(b.at);return n!=0?n:a.key.compareTo(b.key);});return result.take(64).toList();
}
