import { ServiceUnavailableException } from '@nestjs/common';
import { ChatMessage, ProviderReply, SteveProvider } from './steve.provider';
export class OpenAiSteveProvider implements SteveProvider {
  constructor(private readonly key:string,private readonly model:string,private readonly fetcher:typeof fetch=fetch,private readonly timeoutMs=30_000) {}
  get configured() { return !!this.key.trim() && !!this.model.trim(); }
  async generate(input:{instructions:string;message:string;history:ChatMessage[]},signal:AbortSignal):Promise<ProviderReply> {
    if (!this.configured || signal.aborted) throw new ServiceUnavailableException();
    const timeout = new AbortController();
    const timer = setTimeout(()=>timeout.abort(),this.timeoutMs);
    try {
      const response = await this.fetcher('https://api.openai.com/v1/responses',{
        method:'POST',redirect:'error',signal:AbortSignal.any([signal,timeout.signal]),
        headers:{Authorization:'Bearer '+this.key,'Content-Type':'application/json'},
        body:JSON.stringify({model:this.model,instructions:input.instructions,store:false,max_output_tokens:800,
          input:[...input.history.map(m=>({role:m.role,content:m.text})),{role:'user',content:input.message}]}),
      });
      if (!response.ok) throw new ServiceUnavailableException();
      const payload:unknown = await response.json();
      if (!payload || typeof payload !== 'object' || Array.isArray(payload)) throw new ServiceUnavailableException();
      const root = payload as Record<string,unknown>;
      if (!['completed','incomplete'].includes(String(root.status)) || !Array.isArray(root.output)) throw new ServiceUnavailableException();
      const messages = root.output.filter((item):item is Record<string,unknown> => !!item && typeof item==='object' && item.type==='message' && item.role==='assistant');
      const hasFinal = messages.some(item=>item.phase==='final_answer');
      const texts:string[] = [], refusals:string[] = [];
      for (const item of messages) {
        if (item.phase==='commentary' || (hasFinal && item.phase && item.phase!=='final_answer')) continue;
        if (!Array.isArray(item.content)) throw new ServiceUnavailableException();
        for (const part of item.content) {
          if (!part || typeof part !== 'object') throw new ServiceUnavailableException();
          if (part.type==='output_text') {
            if (typeof part.text!=='string') throw new ServiceUnavailableException();
            texts.push(part.text);
          } else if (part.type==='refusal') {
            if (typeof part.refusal!=='string' || !part.refusal.trim()) throw new ServiceUnavailableException();
            refusals.push(part.refusal);
          }
        }
      }
      const text = texts.join('').trim();
      if (text.length>16000 || signal.aborted || timeout.signal.aborted) throw new ServiceUnavailableException();
      if (refusals.length) return {status:'refused',text:refusals.join('\n').slice(0,16000)};
      if (root.status==='incomplete') return {status:'incomplete',text};
      if (!text) throw new ServiceUnavailableException();
      return {status:'completed',text};
    } catch { throw new ServiceUnavailableException(); }
    finally { clearTimeout(timer); }
  }
}
