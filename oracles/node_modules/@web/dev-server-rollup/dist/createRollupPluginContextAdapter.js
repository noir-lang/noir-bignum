"use strict";
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createRollupPluginContextAdapter = void 0;
const path_1 = __importDefault(require("path"));
function createRollupPluginContextAdapter(pluginContext, wdsPlugin, config, fileWatcher, context, pluginMetaPerModule) {
    return Object.assign(Object.assign({}, pluginContext), { getModuleInfo(id) {
            var _a;
            return {
                id,
                code: context.body,
                ast: null,
                dynamicallyImportedIds: [],
                dynamicallyImportedIdResolutions: [],
                dynamicImporters: [],
                hasDefaultExport: false,
                implicitlyLoadedBefore: [],
                implicitlyLoadedAfterOneOf: [],
                importedIds: [],
                importedIdResolutions: [],
                importers: [],
                isEntry: false,
                isExternal: false,
                isIncluded: false,
                moduleSideEffects: false,
                syntheticNamedExports: false,
                meta: (_a = pluginMetaPerModule.get(id)) !== null && _a !== void 0 ? _a : {},
            };
        },
        addWatchFile(id) {
            const filePath = path_1.default.join(process.cwd(), id);
            fileWatcher.add(filePath);
        },
        emitAsset() {
            throw new Error('Emitting files is not yet supported');
        },
        emitFile() {
            throw new Error('Emitting files is not yet supported');
        },
        getAssetFileName() {
            throw new Error('Emitting files is not yet supported');
        },
        getFileName() {
            throw new Error('Emitting files is not yet supported');
        },
        setAssetSource() {
            throw new Error('Emitting files is not yet supported');
        },
        async resolve(source, importer, options) {
            var _a, _b;
            if (!context)
                throw new Error('Context is required.');
            const { skipSelf } = options, resolveOptions = __rest(options, ["skipSelf"]);
            if (skipSelf)
                (_a = wdsPlugin.resolveImportSkip) === null || _a === void 0 ? void 0 : _a.call(wdsPlugin, context, source, importer);
            for (const pl of (_b = config.plugins) !== null && _b !== void 0 ? _b : []) {
                if (pl.resolveImport && (!skipSelf || pl !== wdsPlugin)) {
                    const result = await pl.resolveImport({
                        source,
                        context,
                        resolveOptions,
                    });
                    let resolvedId;
                    if (typeof result === 'string') {
                        resolvedId = result;
                    }
                    else if (typeof result === 'object') {
                        resolvedId = result === null || result === void 0 ? void 0 : result.id;
                    }
                    if (resolvedId) {
                        const importerDir = path_1.default.dirname(importer);
                        return {
                            id: path_1.default.isAbsolute(resolvedId) ? resolvedId : path_1.default.join(importerDir, resolvedId),
                        };
                    }
                }
            }
        },
        async resolveId(source, importer, options) {
            const resolveResult = await this.resolve(source, importer, options);
            if (typeof resolveResult === 'string') {
                return resolveResult;
            }
            if (typeof resolveResult === 'object') {
                return resolveResult === null || resolveResult === void 0 ? void 0 : resolveResult.id;
            }
            return resolveResult;
        } });
}
exports.createRollupPluginContextAdapter = createRollupPluginContextAdapter;
//# sourceMappingURL=createRollupPluginContextAdapter.js.map