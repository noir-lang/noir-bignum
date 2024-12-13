import { TestRunnerPlugin } from '@web/test-runner-core';
export interface Media {
    media?: 'screen' | 'print';
    colorScheme?: 'dark' | 'light' | 'no-preference';
    reducedMotion?: 'reduce' | 'no-preference';
    forcedColors?: 'active' | 'none';
}
export declare function emulateMediaPlugin(): TestRunnerPlugin;
//# sourceMappingURL=emulateMediaPlugin.d.ts.map