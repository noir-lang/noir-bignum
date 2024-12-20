"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createMiddleware = void 0;
const koa_etag_1 = __importDefault(require("koa-etag"));
const basePathMiddleware_js_1 = require("../middleware/basePathMiddleware.js");
const etagCacheMiddleware_js_1 = require("../middleware/etagCacheMiddleware.js");
const historyApiFallbackMiddleware_js_1 = require("../middleware/historyApiFallbackMiddleware.js");
const pluginMimeTypeMiddleware_js_1 = require("../middleware/pluginMimeTypeMiddleware.js");
const pluginServeMiddleware_js_1 = require("../middleware/pluginServeMiddleware.js");
const pluginTransformMiddleware_js_1 = require("../middleware/pluginTransformMiddleware.js");
const watchServedFilesMiddleware_js_1 = require("../middleware/watchServedFilesMiddleware.js");
const pluginFileParsedMiddleware_js_1 = require("../middleware/pluginFileParsedMiddleware.js");
const serveFilesMiddleware_js_1 = require("../middleware/serveFilesMiddleware.js");
/**
 * Creates middlewares based on the given configuration. The middlewares can be
 * used by a koa server using `app.use()`:
 */
function createMiddleware(config, logger, fileWatcher) {
    var _a, _b;
    const middlewares = [];
    middlewares.push(async (ctx, next) => {
        logger.debug(`Receiving request: ${ctx.url}`);
        await next();
        logger.debug(`Responding to request: ${ctx.url} with status ${ctx.status}`);
    });
    // strips a base path from requests
    if (config.basePath) {
        middlewares.push((0, basePathMiddleware_js_1.basePathMiddleware)(config.basePath));
    }
    // adds custom user's middlewares
    for (const m of (_a = config.middleware) !== null && _a !== void 0 ? _a : []) {
        middlewares.push(m);
    }
    if (!config.disableFileWatcher) {
        // watch files that are served
        middlewares.push((0, watchServedFilesMiddleware_js_1.watchServedFilesMiddleware)(fileWatcher, config.rootDir));
    }
    // serves 304 responses if resource hasn't changed
    middlewares.push((0, etagCacheMiddleware_js_1.etagCacheMiddleware)());
    // adds etag headers for caching
    middlewares.push((0, koa_etag_1.default)());
    // serves index.html for non-file requests for SPA routing
    if (config.appIndex) {
        middlewares.push((0, historyApiFallbackMiddleware_js_1.historyApiFallbackMiddleware)(config.appIndex, config.rootDir, logger));
    }
    const plugins = (_b = config.plugins) !== null && _b !== void 0 ? _b : [];
    middlewares.push((0, pluginFileParsedMiddleware_js_1.pluginFileParsedMiddleware)(plugins));
    middlewares.push((0, pluginTransformMiddleware_js_1.pluginTransformMiddleware)(logger, config, fileWatcher));
    middlewares.push((0, pluginMimeTypeMiddleware_js_1.pluginMimeTypeMiddleware)(logger, plugins));
    middlewares.push((0, pluginServeMiddleware_js_1.pluginServeMiddleware)(logger, plugins));
    middlewares.push(...(0, serveFilesMiddleware_js_1.serveFilesMiddleware)(config.rootDir));
    return middlewares;
}
exports.createMiddleware = createMiddleware;
//# sourceMappingURL=createMiddleware.js.map