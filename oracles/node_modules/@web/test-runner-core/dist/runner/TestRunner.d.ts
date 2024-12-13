import { TestRunnerCoreConfig } from '../config/TestRunnerCoreConfig.js';
import { TestSession } from '../test-session/TestSession.js';
import { TestCoverage } from '../coverage/getTestCoverage.js';
import { TestSessionManager } from '../test-session/TestSessionManager.js';
import { EventEmitter } from '../utils/EventEmitter.js';
import { BrowserLauncher } from '../browser-launcher/BrowserLauncher.js';
import { TestRunnerGroupConfig } from '../config/TestRunnerGroupConfig.js';
interface EventMap {
    'test-run-started': {
        testRun: number;
    };
    'test-run-finished': {
        testRun: number;
        testCoverage?: TestCoverage;
    };
    finished: boolean;
    stopped: boolean;
}
export declare class TestRunner extends EventEmitter<EventMap> {
    config: TestRunnerCoreConfig;
    sessions: TestSessionManager;
    testFiles: string[];
    browsers: BrowserLauncher[];
    browserNames: string[];
    startTime: number;
    testRun: number;
    started: boolean;
    stopped: boolean;
    running: boolean;
    passed: boolean;
    focusedTestFile: string | undefined;
    private scheduler;
    private server;
    private pendingSessions;
    constructor(config: TestRunnerCoreConfig, groupConfigs?: TestRunnerGroupConfig[]);
    start(): Promise<void>;
    runTests(sessions: Iterable<TestSession>): Promise<void>;
    stop(error?: any): Promise<void>;
    startDebugBrowser(testFile: string): void;
    private onSessionFinished;
}
export {};
//# sourceMappingURL=TestRunner.d.ts.map