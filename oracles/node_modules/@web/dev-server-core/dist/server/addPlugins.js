"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.addPlugins = void 0;
const transformModuleImportsPlugin_js_1 = require("../plugins/transformModuleImportsPlugin.js");
const webSocketsPlugin_js_1 = require("../web-sockets/webSocketsPlugin.js");
const mimeTypesPlugin_js_1 = require("../plugins/mimeTypesPlugin.js");
function addPlugins(logger, config) {
    var _a, _b;
    if (!config.plugins) {
        config.plugins = [];
    }
    if (config.mimeTypes && Object.keys(config.mimeTypes).length > 0) {
        config.plugins.unshift((0, mimeTypesPlugin_js_1.mimeTypesPlugin)(config.mimeTypes));
    }
    if (config.injectWebSocket && ((_a = config.plugins) === null || _a === void 0 ? void 0 : _a.some(pl => pl.injectWebSocket))) {
        config.plugins.unshift((0, webSocketsPlugin_js_1.webSocketsPlugin)());
    }
    if ((_b = config.plugins) === null || _b === void 0 ? void 0 : _b.some(pl => 'resolveImport' in pl || 'transformImport' in pl)) {
        // transform module imports must happen after all other plugins did their regular transforms
        config.plugins.push((0, transformModuleImportsPlugin_js_1.transformModuleImportsPlugin)(logger, config.plugins, config.rootDir));
    }
}
exports.addPlugins = addPlugins;
//# sourceMappingURL=addPlugins.js.map