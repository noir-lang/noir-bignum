import { TestSession } from './TestSession.js';
import { TestSessionStatus } from './TestSessionStatus.js';
import { EventEmitter } from '../utils/EventEmitter.js';
import { DebugTestSession } from './DebugTestSession.js';
import { TestSessionGroup } from './TestSessionGroup.js';
import { BrowserLauncher } from '../browser-launcher/BrowserLauncher.js';
interface EventMap {
    'session-status-updated': TestSession;
    'session-updated': void;
}
export declare class TestSessionManager extends EventEmitter<EventMap> {
    private _groups;
    private sessionsMap;
    private debugSessions;
    constructor(groups: TestSessionGroup[], sessions: TestSession[]);
    addDebug(...sessions: DebugTestSession[]): void;
    updateStatus(session: TestSession, status: TestSessionStatus): void;
    update(session: TestSession): void;
    groups(): TestSessionGroup[];
    get(id: string): TestSession | undefined;
    all(): IterableIterator<TestSession>;
    filtered(filter: (s: TestSession) => unknown): Generator<TestSession, void, unknown>;
    forStatus(...statuses: TestSessionStatus[]): Generator<TestSession, void, unknown>;
    forStatusAndTestFile(testFile?: string, ...statuses: TestSessionStatus[]): Generator<TestSession, void, unknown>;
    forTestFile(...testFiles: string[]): Generator<TestSession, void, unknown>;
    forBrowser(browser: BrowserLauncher): Generator<TestSession, void, unknown>;
    forGroup(groupName: string): Generator<TestSession, void, unknown>;
    forBrowserName(browserName: string): Generator<TestSession, void, unknown>;
    forBrowserNames(browserNames: string[]): Generator<TestSession, void, unknown>;
    passed(): Generator<TestSession, void, unknown>;
    failed(): Generator<TestSession, void, unknown>;
    getDebug(id: string): DebugTestSession | undefined;
    getAllDebug(): IterableIterator<DebugTestSession>;
    setDebug(debugSession: DebugTestSession): void;
    removeDebug(id: string): void;
}
export {};
//# sourceMappingURL=TestSessionManager.d.ts.map