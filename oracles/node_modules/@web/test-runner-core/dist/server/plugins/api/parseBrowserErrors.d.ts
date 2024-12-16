import { MapStackLocation } from '@web/browser-logs';
import { MapBrowserUrl } from '@web/browser-logs';
import { TestRunnerCoreConfig } from '../../../config/TestRunnerCoreConfig.js';
import { TestResultError, TestSession } from '../../../test-session/TestSession.js';
export declare function replaceErrorStack(error: TestResultError, mapBrowserUrl: MapBrowserUrl, mapStackLocation: MapStackLocation, rootDir: string): Promise<void>;
export declare function parseSessionErrors(config: TestRunnerCoreConfig, mapBrowserUrl: MapBrowserUrl, mapStackLocation: MapStackLocation, result: Partial<TestSession>): Promise<void>;
export declare function parseTestResults(config: TestRunnerCoreConfig, mapBrowserUrl: MapBrowserUrl, mapStackLocation: MapStackLocation, result: Partial<TestSession>): Promise<void>;
//# sourceMappingURL=parseBrowserErrors.d.ts.map