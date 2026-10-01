export interface ChatMessage {role:'user'|'assistant';text:string}
export interface ProviderReply {status:'completed'|'refused'|'incomplete';text:string}
export interface SteveProvider {
  readonly configured?:boolean;
  generate(input:{instructions:string;message:string;history:ChatMessage[]},signal:AbortSignal):Promise<ProviderReply>;
}
