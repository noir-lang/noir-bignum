import { TestSession } from '../test-session/TestSession.js';
import { TestRunnerCoreConfig } from '../config/TestRunnerCoreConfig.js';
import { TestRunnerGroupConfig } from '../config/TestRunnerGroupConfig.js';
import { BrowserLauncher } from '../browser-launcher/BrowserLauncher.js';
import { TestSessionGroup } from '../test-session/TestSessionGroup.js';
export declare function createTestSessions(config: TestRunnerCoreConfig, groupConfigs: TestRunnerGroupConfig[]): {
    sessionGroups: TestSessionGroup[];
    testSessions: TestSession[];
    testFiles: string[];
    browsers: BrowserLauncher[];
};
//# sourceMappingURL=createSessionGroups.d.ts.map