import '../../data/models.dart';
DateTime date(DateTime t,[int offset=0]){final d=t.toLocal();return DateTime(d.year,d.month,d.day+offset);}
class Stats{
 Stats(Iterable<Submission> submissions,this.now){
  for(final s in submissions){
    if(s.submittedAt.isAfter(now))continue;
    final id='${s.platform}/${s.problemId}';
    if(s.ac){
      daily.putIfAbsent(date(s.submittedAt),()=>{}).add(id);
      final prior=solved[id];
      if(prior==null||s.submittedAt.isBefore(prior.submittedAt))solved[id]=s;
    }
    for(final t in s.tags.toSet()){
      final old=tags[t]??(0,0);tags[t]=(old.$1+(s.ac?1:0),old.$2+1);
    }
  }
 }
 final DateTime now;
 final daily=<DateTime,Set<String>>{};final solved=<String,Submission>{};
 final tags=<String,(int,int)>{};
 DateTime get monday=>date(now,1-now.weekday);
 int get weekSolved=>solved.values.where((s)=>!date(s.submittedAt).isBefore(monday)).length;
 int get streak{
  var d=date(now);if(!daily.containsKey(d))d=date(d,-1);
  var count=0;while(daily.containsKey(d)){count++;d=date(d,-1);}return count;
 }
 List<DateTime> get heat=>List.generate(84,(i)=>date(monday,i-77));
 int count(DateTime d)=>daily[d]?.length??0;
 int level(DateTime d)=>count(d).clamp(0,4).toInt();
 List<int> get difficulty{
  final bins=[0,0,0,0];for(final s in solved.values){final r=s.rating;if(r!=null)bins[r<1300?0:r<1700?1:r<2100?2:3]++;}return bins;
 }
}
