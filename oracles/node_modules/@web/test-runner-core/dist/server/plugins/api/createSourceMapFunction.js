"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createSourceMapFunction = void 0;
const path_1 = __importDefault(require("path"));
const source_map_1 = require("source-map");
const fetchSourceMap_js_1 = require("../../../utils/fetchSourceMap.js");
function resolveRelativeTo(relativeTo, filePath) {
    if (path_1.default.isAbsolute(filePath)) {
        return filePath;
    }
    const dir = path_1.default.dirname(relativeTo);
    return path_1.default.join(dir, filePath);
}
/**
 * Creates a function that can map file path, line an column based on source maps. It maintains a cache of source maps,
 * so that they are not fetched multiple times.
 * @param protocol
 * @param host
 * @param port
 */
function createSourceMapFunction(protocol, host, port) {
    const cachedSourceMaps = new Map();
    return async ({ browserUrl, filePath, line, column }, userAgent) => {
        var _a, _b;
        const cacheKey = `${filePath}${userAgent}`;
        if (!cachedSourceMaps.has(cacheKey)) {
            cachedSourceMaps.set(cacheKey, (0, fetchSourceMap_js_1.fetchSourceMap)({
                protocol,
                host,
                port,
                browserUrl,
                userAgent,
            })
                .then(({ sourceMap }) => sourceMap)
                .catch(() => undefined));
        }
        const sourceMap = await cachedSourceMaps.get(cacheKey);
        if (!sourceMap) {
            return null;
        }
        try {
            // if there is no line and column we're looking for just the associated file, for example
            // the test file itself has source maps. if this is a single file source map, we can return
            // that.
            if (typeof line !== 'number' || typeof column !== 'number') {
                const sources = sourceMap.getProperty('sources');
                if (sources && sources.length === 1) {
                    return {
                        filePath: resolveRelativeTo(filePath, sources[0]),
                        browserUrl,
                        line: 0,
                        column: 0,
                    };
                }
                return null;
            }
            // do the actual source mapping
            const consumer = await new source_map_1.SourceMapConsumer(sourceMap.sourcemap);
            let originalPosition = consumer.originalPositionFor({
                line: line !== null && line !== void 0 ? line : 0,
                column: column !== null && column !== void 0 ? column : 0,
                bias: source_map_1.SourceMapConsumer.GREATEST_LOWER_BOUND,
            });
            if (originalPosition.line == null) {
                originalPosition = consumer.originalPositionFor({
                    line: line !== null && line !== void 0 ? line : 0,
                    column: column !== null && column !== void 0 ? column : 0,
                    bias: source_map_1.SourceMapConsumer.LEAST_UPPER_BOUND,
                });
            }
            consumer.destroy();
            if (originalPosition.line == null) {
                return null;
            }
            if (!originalPosition.source) {
                return null;
            }
            const newFilePath = originalPosition.source.split('/').join(path_1.default.sep);
            return {
                filePath: resolveRelativeTo(filePath, newFilePath),
                browserUrl,
                line: (_a = originalPosition.line) !== null && _a !== void 0 ? _a : 0,
                column: (_b = originalPosition.column) !== null && _b !== void 0 ? _b : 0,
            };
        }
        catch (error) {
            console.error(`Error while reading source maps for ${filePath}`);
            console.error(error);
            return null;
        }
    };
}
exports.createSourceMapFunction = createSourceMapFunction;
//# sourceMappingURL=createSourceMapFunction.js.map