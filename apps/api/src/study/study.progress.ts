import {StudyProgress} from './study.models';

export function studyConsistency(activeDates:string[],today:string):Pick<StudyProgress,'activeDays'|'currentStreak'|'bestStreak'>{
 const dates=[...new Set(activeDates)].filter(date=>date<=today).sort();
 let run=0,bestStreak=0,previous:number|undefined;
 for(const date of dates){
  const day=Date.parse(`${date}T00:00:00Z`);
  run=previous!==undefined&&day-previous===86400000?run+1:1;
  bestStreak=Math.max(bestStreak,run);previous=day;
 }
 const todayDay=Date.parse(`${today}T00:00:00Z`);
 const currentStreak=previous!==undefined&&todayDay-previous<=86400000?run:0;
 return {activeDays:dates.length,currentStreak,bestStreak};
}
