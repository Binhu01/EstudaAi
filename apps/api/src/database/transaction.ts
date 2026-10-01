import { SqlExecutor } from '../goals/goal.repository';
export interface SqlTransactionProvider { transaction<T>(work:(tx:SqlExecutor)=>Promise<T>):Promise<T> }
