import { TestRunner, TestRunnerCoreConfig } from './index.js';
import { TestSession } from './test-session/TestSession.js';
import { TestRunnerGroupConfig } from './config/TestRunnerGroupConfig.js';
export declare function runTests(config: Partial<TestRunnerCoreConfig>, groupConfigs?: TestRunnerGroupConfig[], { allowFailure, reportErrors, }?: {
    allowFailure?: boolean;
    reportErrors?: boolean;
}): Promise<{
    runner: TestRunner;
    sessions: TestSession[];
}>;
//# sourceMappingURL=test-helpers.d.ts.map