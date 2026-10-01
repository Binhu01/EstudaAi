import { BadRequestException, HttpException, ServiceUnavailableException } from '@nestjs/common';
import { StudyCatalog, StudySource } from '../catalog/study-catalog';
import { QuotaReservation, SteveQuota } from './quota.repository';
import { ChatMessage, ProviderReply, SteveProvider } from './steve.provider';
import { buildSteveInstructions } from './steve.prompt';
export interface SteveInput {topicId:string;message:string;history:ChatMessage[]}
export interface SteveReply extends ProviderReply {topicId:string;sources:readonly StudySource[];quota:{remaining:number;resetAt:string};requestId:string}
export class SteveService {
  private readonly inFlight = new Set<string>();
  private readonly minute = new Map<string,number[]>();
  constructor(private readonly catalog:StudyCatalog,private readonly quota:SteveQuota,private readonly provider?:SteveProvider,private readonly clock:()=>Date=()=>new Date()) {}
  async reply(userId:string,input:SteveInput,signal:AbortSignal,requestId:string):Promise<SteveReply> {
    const topic = this.catalog.find(input.topicId);
    if (!topic || typeof input.message!=='string' || !input.message.trim() || input.message.length>2000 ||
        !Array.isArray(input.history) || input.history.length>8 || input.history.some(m=>!m || !['user','assistant'].includes(m.role) || typeof m.text!=='string' || !m.text.trim() || m.text.length>2000) ||
        input.history.reduce((sum,m)=>sum+m.text.length,0)>12000) throw new BadRequestException();
    if (!this.provider || this.provider.configured===false || signal.aborted) throw new ServiceUnavailableException();
    if (this.inFlight.has(userId)) throw new HttpException('Aguarde a resposta atual.',429);
    const now=this.clock(), cutoff=now.getTime()-60_000;
    for (const [id, times] of this.minute) { if (times.every(t=>t<=cutoff)) this.minute.delete(id); }
    const recent=(this.minute.get(userId)??[]).filter(t=>t>cutoff);
    if (recent.length>=3) throw new HttpException('Aguarde um momento.',429);
    this.minute.set(userId,[...recent,now.getTime()]);
    this.inFlight.add(userId);
    let reservation:QuotaReservation|undefined, sent=false;
    try {
      reservation=await this.quota.reserve(userId,now);
      if (signal.aborted) throw new ServiceUnavailableException();
      sent=true;
      const result=await this.provider.generate({instructions:buildSteveInstructions(topic),message:input.message.trim(),history:input.history.map(m=>({role:m.role,text:m.text.trim()}))},signal);
      if (signal.aborted) throw new ServiceUnavailableException();
      return {...result,topicId:topic.id,sources:topic.sources,quota:{remaining:reservation.remaining,resetAt:reservation.resetAt},requestId};
    } catch (error) {
      if (error instanceof HttpException) throw error;
      throw new ServiceUnavailableException();
    } finally {
      try {
        if (reservation && !sent) await this.quota.releaseUnsent(reservation.id,userId);
      } catch { /* Retain uncertain reservation on database failure. */ }
      finally { this.inFlight.delete(userId); }
    }
  }
}
