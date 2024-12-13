import playwright, { Browser, Page, LaunchOptions, BrowserContext } from 'playwright';
import { BrowserLauncher, TestRunnerCoreConfig } from '@web/test-runner-core';
import { PlaywrightLauncherPage } from './PlaywrightLauncherPage';
export type ProductType = 'chromium' | 'firefox' | 'webkit';
interface CreateArgs {
    browser: Browser;
    config: TestRunnerCoreConfig;
}
export type CreateBrowserContextFn = (args: CreateArgs) => BrowserContext | Promise<BrowserContext>;
export type CreatePageFn = (args: CreateArgs & {
    context: BrowserContext;
}) => Promise<Page>;
export declare class PlaywrightLauncher implements BrowserLauncher {
    name: string;
    type: string;
    concurrency?: number;
    private product;
    private launchOptions;
    private createBrowserContextFn;
    private createPageFn;
    private config?;
    private testFiles?;
    private browser?;
    private debugBrowser?;
    private activePages;
    private activeDebugPages;
    private testCoveragePerSession;
    private __launchBrowserPromise?;
    __experimentalWindowFocus__: boolean;
    constructor(product: ProductType, launchOptions: LaunchOptions, createBrowserContextFn: CreateBrowserContextFn, createPageFn: CreatePageFn, __experimentalWindowFocus__?: boolean, concurrency?: number);
    initialize(config: TestRunnerCoreConfig, testFiles: string[]): Promise<void>;
    stop(): Promise<void>;
    startSession(sessionId: string, url: string): Promise<void>;
    isActive(sessionId: string): boolean;
    getBrowserUrl(sessionId: string): string;
    startDebugSession(sessionId: string, url: string): Promise<void>;
    createNewPage(browser: Browser): Promise<PlaywrightLauncherPage>;
    stopSession(sessionId: string): Promise<import("@web/test-runner-core").SessionResult>;
    private getOrStartBrowser;
    getPage(sessionId: string): playwright.Page;
}
export {};
//# sourceMappingURL=PlaywrightLauncher.d.ts.map