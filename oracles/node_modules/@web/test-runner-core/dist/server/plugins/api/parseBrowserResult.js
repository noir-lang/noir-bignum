"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseBrowserResult = void 0;
const parseBrowserErrors_js_1 = require("./parseBrowserErrors.js");
const parseBrowserLogs_js_1 = require("./parseBrowserLogs.js");
function createMapStackLocation(smFn, userAgent) {
    return async function mapStackLocation(originalLoc) {
        const mappedLoc = await smFn(originalLoc, userAgent);
        return mappedLoc ? mappedLoc : originalLoc;
    };
}
async function parseBrowserResult(config, mapBrowserUrl, sourceMapFunction, userAgent, result) {
    const mapStackLocation = createMapStackLocation(sourceMapFunction, userAgent);
    await Promise.all([
        (0, parseBrowserLogs_js_1.parseBrowserLogs)(config, mapBrowserUrl, mapStackLocation, result).catch(error => {
            console.error(error);
        }),
        (0, parseBrowserErrors_js_1.parseSessionErrors)(config, mapBrowserUrl, mapStackLocation, result).catch(error => {
            console.error(error);
        }),
        (0, parseBrowserErrors_js_1.parseTestResults)(config, mapBrowserUrl, mapStackLocation, result).catch(error => {
            console.error(error);
        }),
    ]);
    return result;
}
exports.parseBrowserResult = parseBrowserResult;
//# sourceMappingURL=parseBrowserResult.js.map