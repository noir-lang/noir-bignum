import { DevServerCoreConfig, FSWatcher, Plugin as WdsPlugin, Context, ResolveOptions } from '@web/dev-server-core';
import { PluginContext, MinimalPluginContext, TransformPluginContext, CustomPluginOptions, ModuleInfo } from 'rollup';
export declare function createRollupPluginContextAdapter<T extends PluginContext | MinimalPluginContext | TransformPluginContext>(pluginContext: T, wdsPlugin: WdsPlugin, config: DevServerCoreConfig, fileWatcher: FSWatcher, context: Context, pluginMetaPerModule: Map<string, CustomPluginOptions>): T & {
    getModuleInfo(id: string): Partial<ModuleInfo>;
    addWatchFile(id: string): void;
    emitAsset(): never;
    emitFile(): never;
    getAssetFileName(): never;
    getFileName(): never;
    setAssetSource(): never;
    resolve(source: string, importer: string, options: ResolveOptions): Promise<{
        id: string;
    } | undefined>;
    resolveId(source: string, importer: string, options: {
        isEntry: boolean;
        skipSelf: boolean;
        custom: Record<string, unknown>;
    }): Promise<string | undefined>;
};
//# sourceMappingURL=createRollupPluginContextAdapter.d.ts.map