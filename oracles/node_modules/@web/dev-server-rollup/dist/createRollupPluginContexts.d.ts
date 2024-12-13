import { InputOptions, NormalizedInputOptions, PluginContext, TransformPluginContext } from 'rollup';
export interface RollupPluginContexts {
    normalizedInputOptions: NormalizedInputOptions;
    pluginContext: PluginContext;
    minimalPluginContext: any;
    transformPluginContext: TransformPluginContext;
}
/**
 * Runs rollup with an empty module in order to capture the plugin context and
 * normalized options.
 * @param inputOptions
 */
export declare function createRollupPluginContexts(inputOptions: InputOptions): Promise<RollupPluginContexts>;
//# sourceMappingURL=createRollupPluginContexts.d.ts.map