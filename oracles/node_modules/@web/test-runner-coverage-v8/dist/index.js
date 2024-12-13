"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.v8ToIstanbul = void 0;
const path_1 = require("path");
const v8_to_istanbul_1 = __importDefault(require("v8-to-istanbul"));
const test_runner_core_1 = require("@web/test-runner-core");
const picomatch_1 = __importDefault(require("picomatch"));
const lru_cache_1 = __importDefault(require("lru-cache"));
const promises_1 = require("node:fs/promises");
const utils_1 = require("./utils");
const cachedMatchers = new Map();
// Cache the sourcemap/source objects to avoid repeatedly having to load
// them from disk per call
const cachedSources = new lru_cache_1.default({
    maxSize: 1024 * 1024 * 50,
    sizeCalculation: n => n.source.length,
});
// coverage base dir must be separated with "/"
const coverageBaseDir = process.cwd().split(path_1.sep).join('/');
function hasOriginalSource(source) {
    return ('sourceMap' in source &&
        source.sourceMap !== undefined &&
        typeof source.sourceMap.sourcemap === 'object' &&
        source.sourceMap.sourcemap !== null &&
        Array.isArray(source.sourceMap.sourcemap.sourcesContent) &&
        source.sourceMap.sourcemap.sourcesContent.length > 0);
}
function getMatcher(patterns) {
    if (!patterns || patterns.length === 0) {
        return () => true;
    }
    const key = patterns.join('');
    let matcher = cachedMatchers.get(key);
    if (!matcher) {
        const resolvedPatterns = patterns.map(pattern => !(0, path_1.isAbsolute)(pattern) && !pattern.startsWith('*')
            ? path_1.posix.join(coverageBaseDir, pattern)
            : pattern);
        matcher = (0, picomatch_1.default)(resolvedPatterns);
        cachedMatchers.set(key, matcher);
    }
    return matcher;
}
async function v8ToIstanbul(config, testFiles, coverage, userAgent) {
    var _a, _b;
    const included = getMatcher((_a = config === null || config === void 0 ? void 0 : config.coverageConfig) === null || _a === void 0 ? void 0 : _a.include);
    const excluded = getMatcher((_b = config === null || config === void 0 ? void 0 : config.coverageConfig) === null || _b === void 0 ? void 0 : _b.exclude);
    const istanbulCoverage = {};
    for (const entry of coverage) {
        const url = new URL(entry.url);
        const path = url.pathname;
        if (
        // ignore non-http protocols (for exmaple webpack://)
        url.protocol.startsWith('http') &&
            // ignore external urls
            url.hostname === config.hostname &&
            url.port === `${config.port}` &&
            // ignore non-files
            !!(0, path_1.extname)(path) &&
            // ignore virtual files
            !path.startsWith('/__web-test-runner') &&
            !path.startsWith('/__web-dev-server')) {
            try {
                const filePath = (0, path_1.join)(config.rootDir, (0, utils_1.toFilePath)(path));
                if (!testFiles.includes(filePath) && included(filePath) && !excluded(filePath)) {
                    const browserUrl = `${url.pathname}${url.search}${url.hash}`;
                    const cachedSource = cachedSources.get(browserUrl);
                    const sources = cachedSource !== null && cachedSource !== void 0 ? cachedSource : (await (0, test_runner_core_1.fetchSourceMap)({
                        protocol: config.protocol,
                        host: config.hostname,
                        port: config.port,
                        browserUrl,
                        userAgent,
                    }));
                    if (!cachedSource) {
                        if (!hasOriginalSource(sources)) {
                            const contents = await (0, promises_1.readFile)(filePath, 'utf8');
                            sources.originalSource = contents;
                        }
                        cachedSources.set(browserUrl, sources);
                    }
                    const converter = (0, v8_to_istanbul_1.default)(filePath, 0, sources);
                    await converter.load();
                    converter.applyCoverage(entry.functions);
                    Object.assign(istanbulCoverage, converter.toIstanbul());
                }
            }
            catch (error) {
                console.error(`Error while generating code coverage for ${entry.url}.`);
                console.error(error);
            }
        }
    }
    return istanbulCoverage;
}
exports.v8ToIstanbul = v8ToIstanbul;
//# sourceMappingURL=index.js.map