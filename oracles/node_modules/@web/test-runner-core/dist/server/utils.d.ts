import { Context } from '@web/dev-server-core';
import { TestRunnerCoreConfig } from '../config/TestRunnerCoreConfig.js';
export declare function toBrowserPath(filePath: string): string;
export declare function toFilePath(browserPath: string): string;
export declare function createTestFileImportPath(config: TestRunnerCoreConfig, context: Context, filePath: string, sessionId?: string): Promise<string>;
//# sourceMappingURL=utils.d.ts.map