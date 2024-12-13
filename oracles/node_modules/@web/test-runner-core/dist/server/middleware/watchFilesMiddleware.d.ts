import { Middleware } from '@web/dev-server-core';
import { FSWatcher } from 'chokidar';
import { TestSessionManager } from '../../test-session/TestSessionManager.js';
import { TestSession } from '../../test-session/TestSession.js';
export type RunSessions = (sessions: Iterable<TestSession>) => void;
export interface DependencyGraphMiddlewareArgs {
    sessions: TestSessionManager;
    rootDir: string;
    fileWatcher: FSWatcher;
    testFrameworkImport?: string;
    runSessions: RunSessions;
}
export declare function watchFilesMiddleware({ rootDir, fileWatcher, sessions, runSessions, testFrameworkImport, }: DependencyGraphMiddlewareArgs): Middleware;
//# sourceMappingURL=watchFilesMiddleware.d.ts.map