import { TestRunnerPlugin } from '@web/test-runner-core';
type TypePayload = {
    type: string;
};
type PressPayload = {
    press: string;
};
type DownPayload = {
    down: string;
};
type UpPayload = {
    up: string;
};
export type SendKeysPayload = TypePayload | PressPayload | DownPayload | UpPayload;
export declare function sendKeysPlugin(): TestRunnerPlugin<SendKeysPayload>;
export {};
//# sourceMappingURL=sendKeysPlugin.d.ts.map