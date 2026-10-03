function civil(now:Date,timezone:string){
 const parts=new Intl.DateTimeFormat('en-CA',{timeZone:timezone,year:'numeric',month:'2-digit',day:'2-digit'}).formatToParts(now);
 const get=(type:string)=>parts.find(p=>p.type===type)!.value;
 return `${get('year')}-${get('month')}-${get('day')}`;
}
function midnight(date:string,timezone:string){
 const desired=Date.parse(date+'T00:00:00Z');let timestamp=desired;
 const fmt=new Intl.DateTimeFormat('en-CA',{timeZone:timezone,year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit',hourCycle:'h23'});
 for(let i=0;i<3;i++){
  const p=fmt.formatToParts(new Date(timestamp));const v=(type:string)=>p.find(x=>x.type===type)!.value;
  const wall=Date.parse(`${v('year')}-${v('month')}-${v('day')}T${v('hour')}:${v('minute')}:${v('second')}Z`);
  timestamp+=desired-wall;
 }
 return new Date(timestamp);
}
export function studyDates(now:Date,timezone:string):{date:string;start:Date;end:Date}[]{
 const today=Date.parse(civil(now,timezone)+'T00:00:00Z');
 return Array.from({length:7},(_,i)=>{
  const date=new Date(today-(6-i)*86400000).toISOString().slice(0,10),next=new Date(today-(5-i)*86400000).toISOString().slice(0,10);
  return {date,start:midnight(date,timezone),end:midnight(next,timezone)};
 });
}
