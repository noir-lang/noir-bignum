import { LaunchOptions, devices } from 'playwright';
import * as playwright from 'playwright';
import { PlaywrightLauncher, ProductType, CreateBrowserContextFn, CreatePageFn } from './PlaywrightLauncher';
export { ProductType, playwright };
export interface PlaywrightLauncherArgs {
    product?: ProductType;
    launchOptions?: LaunchOptions;
    createBrowserContext?: CreateBrowserContextFn;
    createPage?: CreatePageFn;
    __experimentalWindowFocus__?: boolean;
    concurrency?: number;
}
export { PlaywrightLauncher, devices };
export declare function playwrightLauncher(args?: PlaywrightLauncherArgs): PlaywrightLauncher;
//# sourceMappingURL=index.d.ts.map