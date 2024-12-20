/// <reference types="mocha" />
import { TestSuiteResult, TestResultError } from '@web/test-runner-core/browser/session.js';
export declare function collectTestResults(mocha: BrowserMocha): {
    testResults: TestSuiteResult;
    hookErrors: TestResultError[];
    passed: boolean;
};
//# sourceMappingURL=collectTestResults.d.ts.map