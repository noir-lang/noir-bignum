import { TestRunnerPlugin } from '@web/test-runner-core';
type SelectByValuePayload = {
    selector: string;
    value: string;
};
type SelectByLabelPayload = {
    selector: string;
    label: string;
};
type SelectMultipleValuesPayload = {
    selector: string;
    values: string[];
};
export type SelectOptionPayload = SelectByLabelPayload | SelectByValuePayload | SelectMultipleValuesPayload;
export declare function selectOptionPlugin(): TestRunnerPlugin<SelectOptionPayload>;
export {};
//# sourceMappingURL=selectOptionPlugin.d.ts.map