import { Page } from 'puppeteer-core';
import { TestRunnerCoreConfig } from '@web/test-runner-core';
import { SessionResult } from '@web/test-runner-core';
declare global {
    interface Window {
        __bringTabToFront: (id: string) => void;
        __releaseLock: (id: string) => void;
    }
}
export declare class ChromeLauncherPage {
    private config;
    private testFiles;
    private product;
    puppeteerPage: Page;
    private nativeInstrumentationEnabledOnPage;
    private patchAdded;
    private resolvers;
    constructor(config: TestRunnerCoreConfig, testFiles: string[], product: string, puppeteerPage: Page);
    runSession(url: string, coverage: boolean): Promise<void>;
    stopSession(): Promise<SessionResult>;
    private collectTestCoverage;
}
//# sourceMappingURL=ChromeLauncherPage.d.ts.map