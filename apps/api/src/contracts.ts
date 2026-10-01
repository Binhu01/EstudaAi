export type Identity = Readonly<{ externalId: string }>;
export type User = Readonly<{ id: string }>;
export interface IdentityVerifier { verify(token: string): Promise<Identity>; }
export interface UserRepository { resolve(externalId: string): Promise<User>; }
export interface AppDependencies {
  identity: IdentityVerifier;
  users: UserRepository;
  ready: () => Promise<boolean>;
  origins: string[];
  rateLimit?: number;
  log?: (event: Readonly<Record<string, unknown>>) => void;
}
