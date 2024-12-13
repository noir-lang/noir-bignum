import * as puppeteerCore from 'puppeteer-core';
import { ChromeLauncher, CreateBrowserContextFn, CreatePageFn } from './ChromeLauncher.js';
import { PuppeteerNodeLaunchOptions } from 'puppeteer-core';
export interface ChromeLauncherArgs {
    puppeteer?: typeof puppeteerCore;
    launchOptions?: PuppeteerNodeLaunchOptions;
    createBrowserContext?: CreateBrowserContextFn;
    createPage?: CreatePageFn;
    concurrency?: number;
}
export { ChromeLauncher, puppeteerCore };
export declare function chromeLauncher(args?: ChromeLauncherArgs): ChromeLauncher;
//# sourceMappingURL=index.d.ts.map