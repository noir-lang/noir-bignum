import { Page, BrowserContext } from 'playwright';
import { TestRunnerCoreConfig } from '@web/test-runner-core';
import { SessionResult } from '@web/test-runner-core';
import { ProductType } from './PlaywrightLauncher';
export declare class PlaywrightLauncherPage {
    private config;
    private testFiles;
    private product;
    playwrightContext: BrowserContext;
    playwrightPage: Page;
    private nativeInstrumentationEnabledOnPage;
    constructor(config: TestRunnerCoreConfig, product: ProductType, testFiles: string[], playwrightContext: BrowserContext, playwrightPage: Page);
    runSession(url: string, coverage: boolean): Promise<void>;
    stopSession(): Promise<SessionResult>;
    private collectTestCoverage;
}
//# sourceMappingURL=PlaywrightLauncherPage.d.ts.map