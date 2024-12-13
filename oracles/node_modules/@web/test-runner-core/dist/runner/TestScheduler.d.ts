import { TestRunnerCoreConfig } from '../config/TestRunnerCoreConfig.js';
import { TestSessionManager } from '../test-session/TestSessionManager.js';
import { TestSession, TestResultError } from '../test-session/TestSession.js';
import { BrowserLauncher } from '../browser-launcher/BrowserLauncher.js';
export declare class TestScheduler {
    private config;
    private sessions;
    private timeoutHandler;
    private browsers;
    private finishedBrowsers;
    private stopPromises;
    private browserStartTimeoutMsg;
    constructor(config: TestRunnerCoreConfig, sessions: TestSessionManager, browsers: BrowserLauncher[]);
    /**
     * Schedules a session for execution. Execution is batched, the session
     * will be queued until there is a browser page available.
     */
    schedule(testRun: number, sessionsToSchedule: Iterable<TestSession>): void;
    stop(): Promise<unknown>;
    /** Runs the next batch of scheduled sessions, if any. */
    private runNextScheduled;
    private startSession;
    private setSessionFailed;
    stopSession(session: TestSession, errors?: TestResultError[]): Promise<void>;
    private getScheduledSessions;
    private getRunningSessions;
    private getUnfinishedSessions;
}
//# sourceMappingURL=TestScheduler.d.ts.map