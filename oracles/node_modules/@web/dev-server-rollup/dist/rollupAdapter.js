"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.rollupAdapter = void 0;
/* eslint-disable no-control-regex */
const path_1 = __importDefault(require("path"));
const whatwg_url_1 = __importDefault(require("whatwg-url"));
const dev_server_core_1 = require("@web/dev-server-core");
const dom5_1 = require("@web/dev-server-core/dist/dom5");
const parse5_1 = require("parse5");
const nanocolors_1 = require("nanocolors");
const utils_js_1 = require("./utils.js");
const createRollupPluginContextAdapter_js_1 = require("./createRollupPluginContextAdapter.js");
const createRollupPluginContexts_js_1 = require("./createRollupPluginContexts.js");
const NULL_BYTE_PARAM = 'web-dev-server-rollup-null-byte';
const VIRTUAL_FILE_PREFIX = '/__web-dev-server__/rollup';
const WDS_FILE_PREFIX = '/__web-dev-server__';
const OUTSIDE_ROOT_REGEXP = /\/__wds-outside-root__\/([0-9]+)\/(.*)/;
/**
 * Wraps rollup error in a custom error for web dev server.
 */
function wrapRollupError(filePath, context, error) {
    var _a, _b;
    if (typeof error == null || typeof error !== 'object') {
        return error;
    }
    if (typeof ((_a = error === null || error === void 0 ? void 0 : error.loc) === null || _a === void 0 ? void 0 : _a.line) === 'number' && typeof ((_b = error === null || error === void 0 ? void 0 : error.loc) === null || _b === void 0 ? void 0 : _b.column) === 'number') {
        return new dev_server_core_1.PluginSyntaxError(
        // replace file path in error message since it will be reported be the dev server
        error.message.replace(new RegExp(`(\\s*in\\s*)?(${filePath})`), ''), filePath, context.body, error.loc.line, error.loc.column);
    }
    return error;
}
const resolverCache = new WeakMap();
function rollupAdapter(rollupPlugin, rollupInputOptions = {}, adapterOptions = {}) {
    if (typeof rollupPlugin !== 'object') {
        throw new Error('rollupAdapter should be called with a rollup plugin object.');
    }
    const transformedFiles = new Set();
    const pluginMetaPerModule = new Map();
    let rollupPluginContexts;
    let fileWatcher;
    let config;
    let rootDir;
    let idResolvers = [];
    function savePluginMeta(id, { meta } = {}) {
        if (!meta) {
            return;
        }
        const previousMeta = pluginMetaPerModule.get(id);
        pluginMetaPerModule.set(id, Object.assign(Object.assign({}, previousMeta), meta));
    }
    const wdsPlugin = {
        name: rollupPlugin.name,
        async serverStart(args) {
            var _a, _b, _c;
            ({ fileWatcher, config } = args);
            ({ rootDir } = config);
            rollupPluginContexts = await (0, createRollupPluginContexts_js_1.createRollupPluginContexts)(rollupInputOptions);
            idResolvers = [];
            // call the options and buildStart hooks
            let transformedOptions;
            if (typeof rollupPlugin.options === 'function') {
                transformedOptions =
                    (_b = (await ((_a = rollupPlugin.options) === null || _a === void 0 ? void 0 : _a.call(rollupPluginContexts.minimalPluginContext, rollupInputOptions)))) !== null && _b !== void 0 ? _b : rollupInputOptions;
            }
            else {
                transformedOptions = rollupInputOptions;
            }
            if (typeof rollupPlugin.buildStart === 'function') {
                await ((_c = rollupPlugin.buildStart) === null || _c === void 0 ? void 0 : _c.call(rollupPluginContexts.pluginContext, rollupPluginContexts.normalizedInputOptions));
            }
            if (transformedOptions &&
                transformedOptions.plugins &&
                Array.isArray(transformedOptions.plugins)) {
                for (const subPlugin of transformedOptions.plugins) {
                    if (subPlugin && !Array.isArray(subPlugin)) {
                        const resolveId = subPlugin.resolveId;
                        if (resolveId) {
                            idResolvers.push(resolveId);
                        }
                    }
                }
            }
            if (rollupPlugin.resolveId) {
                idResolvers.push(rollupPlugin.resolveId);
            }
        },
        resolveImportSkip(context, source, importer) {
            var _a, _b;
            const resolverCacheForContext = (_a = resolverCache.get(context)) !== null && _a !== void 0 ? _a : new WeakMap();
            resolverCache.set(context, resolverCacheForContext);
            const resolverCacheForPlugin = (_b = resolverCacheForContext.get(wdsPlugin)) !== null && _b !== void 0 ? _b : new Set();
            resolverCacheForContext.set(wdsPlugin, resolverCacheForPlugin);
            resolverCacheForPlugin.add(`${source}:${importer}`);
        },
        async resolveImport({ source, context, code, column, line, resolveOptions }) {
            var _a, _b, _c;
            if (context.response.is('html') && source.startsWith('�')) {
                // when serving HTML a null byte gets parsed as an unknown character
                // we remap it to a null byte here so that it is handled properly downstream
                // this isn't a perfect solution
                source = source.replace('�', '\0');
            }
            // if we just transformed this file and the import is an absolute file path
            // we need to rewrite it to a browser path
            const injectedFilePath = path_1.default.normalize(source).startsWith(rootDir);
            if (!injectedFilePath && idResolvers.length === 0) {
                return;
            }
            const isVirtualModule = source.startsWith('\0');
            if (!injectedFilePath &&
                !path_1.default.isAbsolute(source) &&
                whatwg_url_1.default.parseURL(source) != null &&
                !isVirtualModule) {
                // don't resolve relative and valid urls
                return source;
            }
            const filePath = (0, dev_server_core_1.getRequestFilePath)(context.url, rootDir);
            try {
                const rollupPluginContext = (0, createRollupPluginContextAdapter_js_1.createRollupPluginContextAdapter)(rollupPluginContexts.pluginContext, wdsPlugin, config, fileWatcher, context, pluginMetaPerModule);
                let resolvableImport = source;
                let importSuffix = '';
                // we have to special case node-resolve because it doesn't support resolving
                // with hash/params at the moment
                if (rollupPlugin.name === 'node-resolve') {
                    if (source[0] === '#') {
                        // private import
                        resolvableImport = source;
                    }
                    else {
                        const [withoutHash, hash] = source.split('#');
                        const [importPath, params] = withoutHash.split('?');
                        importSuffix = `${params ? `?${params}` : ''}${hash ? `#${hash}` : ''}`;
                        resolvableImport = importPath;
                    }
                }
                let result = null;
                const resolverCacheForContext = (_a = resolverCache.get(context)) !== null && _a !== void 0 ? _a : new WeakMap();
                resolverCache.set(context, resolverCacheForContext);
                const resolverCacheForPlugin = (_b = resolverCacheForContext.get(wdsPlugin)) !== null && _b !== void 0 ? _b : new Set();
                resolverCacheForContext.set(wdsPlugin, resolverCacheForPlugin);
                if (resolverCacheForPlugin.has(`${source}:${filePath}`)) {
                    return undefined;
                }
                for (const idResolver of idResolvers) {
                    const idResolverHandler = typeof idResolver === 'function' ? idResolver : idResolver.handler;
                    result = await idResolverHandler.call(rollupPluginContext, resolvableImport, filePath, Object.assign(Object.assign({}, resolveOptions), { attributes: Object.assign({}, ((_c = resolveOptions === null || resolveOptions === void 0 ? void 0 : resolveOptions.assertions) !== null && _c !== void 0 ? _c : {})), isEntry: false }));
                    if (result) {
                        break;
                    }
                }
                if (!result && injectedFilePath) {
                    // the import is a file path but it was not resolved by this plugin
                    // we do assign it here so that it will be converted to a browser path
                    result = resolvableImport;
                }
                let resolvedImportPath = undefined;
                if (typeof result === 'string') {
                    resolvedImportPath = result;
                }
                else if (typeof result === 'object' && typeof (result === null || result === void 0 ? void 0 : result.id) === 'string') {
                    resolvedImportPath = result.id;
                    savePluginMeta(result.id, result);
                }
                if (!resolvedImportPath) {
                    if (!['/', './', '../'].some(prefix => resolvableImport.startsWith(prefix)) &&
                        adapterOptions.throwOnUnresolvedImport) {
                        const errorMessage = (0, nanocolors_1.red)(`Could not resolve import ${(0, nanocolors_1.cyan)(`"${source}"`)}.`);
                        if (typeof code === 'string' &&
                            typeof column === 'number' &&
                            typeof line === 'number') {
                            throw new dev_server_core_1.PluginSyntaxError(errorMessage, filePath, code, column, line);
                        }
                        else {
                            throw new dev_server_core_1.PluginError(errorMessage);
                        }
                    }
                    return undefined;
                }
                // if the resolved import includes a null byte (\0) there is some special logic
                // these often are not valid file paths, so the browser cannot request them.
                // we rewrite them to a special URL which we deconstruct later when we load the file
                if (resolvedImportPath.includes('\0')) {
                    const filename = path_1.default.basename(resolvedImportPath.replace(/\0*/g, '').split('?')[0].split('#')[0]);
                    // if the resolve import path is outside our normal root, fully resolve the file path for rollup
                    const matches = resolvedImportPath.match(OUTSIDE_ROOT_REGEXP);
                    if (matches) {
                        const upDirs = new Array(parseInt(matches[1], 10) + 1).join(`..${path_1.default.sep}`);
                        resolvedImportPath = `\0${path_1.default.resolve(`${upDirs}${matches[2]}`)}`;
                    }
                    const urlParam = encodeURIComponent(resolvedImportPath);
                    return `${VIRTUAL_FILE_PREFIX}/${filename}?${NULL_BYTE_PARAM}=${urlParam}`;
                }
                // some plugins don't return a file path, so we just return it as is
                if (!(0, utils_js_1.isAbsoluteFilePath)(resolvedImportPath)) {
                    return `${resolvedImportPath}`;
                }
                // file already resolved outsided root dir
                if ((0, utils_js_1.isOutsideRootDir)(resolvedImportPath)) {
                    return `${resolvedImportPath}`;
                }
                const normalizedPath = path_1.default.normalize(resolvedImportPath);
                // append a path separator to rootDir so we are actually testing containment
                // of the normalized path within the rootDir folder
                const normalizedRootDir = rootDir.endsWith(path_1.default.sep) ? rootDir : rootDir + path_1.default.sep;
                if (!normalizedPath.startsWith(normalizedRootDir)) {
                    const relativePath = path_1.default.relative(rootDir, normalizedPath);
                    const dirUp = `..${path_1.default.sep}`;
                    const lastDirUpIndex = relativePath.lastIndexOf(dirUp) + 3;
                    const dirUpStrings = relativePath.substring(0, lastDirUpIndex).split(path_1.default.sep);
                    if (dirUpStrings.length === 0 || dirUpStrings.some(str => !['..', ''].includes(str))) {
                        // we expect the relative part to consist of only ../ or ..\\
                        const errorMessage = (0, nanocolors_1.red)(`\n\nResolved ${(0, nanocolors_1.cyan)(source)} to ${(0, nanocolors_1.cyan)(resolvedImportPath)}.\n\n`) +
                            (0, nanocolors_1.red)('This path could not be converted to a browser path. Please file an issue with a reproduction.');
                        if (typeof code === 'string' &&
                            typeof column === 'number' &&
                            typeof line === 'number') {
                            throw new dev_server_core_1.PluginSyntaxError(errorMessage, filePath, code, column, line);
                        }
                        else {
                            throw new dev_server_core_1.PluginError(errorMessage);
                        }
                    }
                    const importPath = (0, utils_js_1.toBrowserPath)(relativePath.substring(lastDirUpIndex));
                    resolvedImportPath = `/__wds-outside-root__/${dirUpStrings.length - 1}/${importPath}`;
                }
                else {
                    let relativeImportFilePath = '';
                    if (context.url.match(OUTSIDE_ROOT_REGEXP)) {
                        const pathInsideRootDir = `/${normalizedPath.replace(normalizedRootDir, '')}`;
                        const resolveRelativeTo = path_1.default.dirname(context.url);
                        relativeImportFilePath = path_1.default.relative(resolveRelativeTo, pathInsideRootDir);
                    }
                    else {
                        const resolveRelativeTo = path_1.default.dirname(filePath);
                        relativeImportFilePath = path_1.default.relative(resolveRelativeTo, resolvedImportPath);
                    }
                    resolvedImportPath = `./${(0, utils_js_1.toBrowserPath)(relativeImportFilePath)}`;
                }
                return `${resolvedImportPath}${importSuffix}`;
            }
            catch (error) {
                throw wrapRollupError(filePath, context, error);
            }
        },
        async serve(context) {
            var _a;
            if (!rollupPlugin.load) {
                return;
            }
            if (context.path.startsWith(WDS_FILE_PREFIX) &&
                !context.path.startsWith(VIRTUAL_FILE_PREFIX)) {
                return;
            }
            let filePath;
            if (context.path.startsWith(VIRTUAL_FILE_PREFIX) &&
                context.URL.searchParams.has(NULL_BYTE_PARAM)) {
                // if this was a special URL constructed in resolveImport to handle null bytes,
                // the file path is stored in the search paramter
                filePath = context.URL.searchParams.get(NULL_BYTE_PARAM);
            }
            else {
                filePath = path_1.default.join(rootDir, context.path);
            }
            try {
                const rollupPluginContext = (0, createRollupPluginContextAdapter_js_1.createRollupPluginContextAdapter)(rollupPluginContexts.pluginContext, wdsPlugin, config, fileWatcher, context, pluginMetaPerModule);
                let result;
                if (typeof rollupPlugin.load === 'function') {
                    result = await ((_a = rollupPlugin.load) === null || _a === void 0 ? void 0 : _a.call(rollupPluginContext, filePath));
                }
                if (typeof result === 'string') {
                    return { body: result, type: 'js' };
                }
                if (result != null && typeof (result === null || result === void 0 ? void 0 : result.code) === 'string') {
                    savePluginMeta(filePath, result);
                    return { body: result.code, type: 'js' };
                }
            }
            catch (error) {
                throw wrapRollupError(filePath, context, error);
            }
            return undefined;
        },
        async transform(context) {
            var _a, _b;
            if (!rollupPlugin.transform) {
                return;
            }
            if (context.path.startsWith(WDS_FILE_PREFIX)) {
                return;
            }
            if (context.response.is('js')) {
                const filePath = path_1.default.join(rootDir, context.path);
                try {
                    const rollupPluginContext = (0, createRollupPluginContextAdapter_js_1.createRollupPluginContextAdapter)(rollupPluginContexts.transformPluginContext, wdsPlugin, config, fileWatcher, context, pluginMetaPerModule);
                    let result;
                    if (typeof rollupPlugin.transform === 'function') {
                        result = await ((_a = rollupPlugin.transform) === null || _a === void 0 ? void 0 : _a.call(rollupPluginContext, context.body, filePath));
                    }
                    let transformedCode = undefined;
                    if (typeof result === 'string') {
                        transformedCode = result;
                    }
                    if (typeof result === 'object' && typeof (result === null || result === void 0 ? void 0 : result.code) === 'string') {
                        savePluginMeta(filePath, result);
                        transformedCode = result.code;
                    }
                    if (transformedCode) {
                        transformedFiles.add(context.path);
                        return transformedCode;
                    }
                    return;
                }
                catch (error) {
                    throw wrapRollupError(filePath, context, error);
                }
            }
            if (context.response.is('html')) {
                const documentAst = (0, parse5_1.parse)(context.body);
                const inlineScripts = (0, dom5_1.queryAll)(documentAst, dom5_1.predicates.AND(dom5_1.predicates.hasTagName('script'), dom5_1.predicates.NOT(dom5_1.predicates.hasAttr('src'))));
                const filePath = (0, dev_server_core_1.getRequestFilePath)(context.url, rootDir);
                let transformed = false;
                try {
                    for (const node of inlineScripts) {
                        const code = (0, dom5_1.getTextContent)(node);
                        const rollupPluginContext = (0, createRollupPluginContextAdapter_js_1.createRollupPluginContextAdapter)(rollupPluginContexts.transformPluginContext, wdsPlugin, config, fileWatcher, context, pluginMetaPerModule);
                        let result;
                        if (typeof rollupPlugin.transform === 'function') {
                            result = await ((_b = rollupPlugin.transform) === null || _b === void 0 ? void 0 : _b.call(rollupPluginContext, code, filePath));
                        }
                        let transformedCode = undefined;
                        if (typeof result === 'string') {
                            transformedCode = result;
                        }
                        if (typeof result === 'object' && typeof (result === null || result === void 0 ? void 0 : result.code) === 'string') {
                            savePluginMeta(filePath, result);
                            transformedCode = result.code;
                        }
                        if (transformedCode) {
                            transformedFiles.add(context.path);
                            (0, dom5_1.setTextContent)(node, transformedCode);
                            transformed = true;
                        }
                    }
                    if (transformed) {
                        return (0, parse5_1.serialize)(documentAst);
                    }
                }
                catch (error) {
                    throw wrapRollupError(filePath, context, error);
                }
            }
        },
        fileParsed(context) {
            var _a;
            if (!rollupPlugin.moduleParsed) {
                return;
            }
            const rollupPluginContext = (0, createRollupPluginContextAdapter_js_1.createRollupPluginContextAdapter)(rollupPluginContexts.transformPluginContext, wdsPlugin, config, fileWatcher, context, pluginMetaPerModule);
            const filePath = (0, dev_server_core_1.getRequestFilePath)(context.url, rootDir);
            const info = rollupPluginContext.getModuleInfo(filePath);
            if (!info)
                throw new Error(`Missing info for module ${filePath}`);
            if (typeof rollupPlugin.moduleParsed === 'function') {
                (_a = rollupPlugin.moduleParsed) === null || _a === void 0 ? void 0 : _a.call(rollupPluginContext, info);
            }
        },
    };
    return wdsPlugin;
}
exports.rollupAdapter = rollupAdapter;
//# sourceMappingURL=rollupAdapter.js.map