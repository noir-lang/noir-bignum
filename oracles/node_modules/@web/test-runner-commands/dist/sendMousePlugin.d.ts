import { TestRunnerPlugin } from '@web/test-runner-core';
type MousePosition = [number, number];
type MouseButton = 'left' | 'middle' | 'right';
export type SendMousePayload = MovePayload | ClickPayload | DownPayload | UpPayload;
export type MovePayload = {
    type: 'move';
    position: MousePosition;
};
export type ClickPayload = {
    type: 'click';
    position: MousePosition;
    button?: MouseButton;
};
export type DownPayload = {
    type: 'down';
    button?: MouseButton;
};
export type UpPayload = {
    type: 'up';
    button?: MouseButton;
};
export declare function sendMousePlugin(): TestRunnerPlugin<SendMousePayload>;
export {};
//# sourceMappingURL=sendMousePlugin.d.ts.map