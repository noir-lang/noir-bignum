"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PluginError = exports.PluginSyntaxError = exports.isInlineScriptRequest = exports.getHtmlPath = exports.getResponseBody = exports.getRequestFilePath = exports.getRequestBrowserPath = exports.WebSocketsManager = exports.DevServer = exports.WebSocket = exports.Server = exports.Koa = exports.FSWatcher = void 0;
// reexports of types from internal libraries
var chokidar_1 = require("chokidar");
Object.defineProperty(exports, "FSWatcher", { enumerable: true, get: function () { return chokidar_1.FSWatcher; } });
var koa_1 = require("koa");
Object.defineProperty(exports, "Koa", { enumerable: true, get: function () { return __importDefault(koa_1).default; } });
var net_1 = require("net");
Object.defineProperty(exports, "Server", { enumerable: true, get: function () { return net_1.Server; } });
const ws_1 = __importDefault(require("ws"));
exports.WebSocket = ws_1.default;
var DevServer_js_1 = require("./server/DevServer.js");
Object.defineProperty(exports, "DevServer", { enumerable: true, get: function () { return DevServer_js_1.DevServer; } });
var WebSocketsManager_js_1 = require("./web-sockets/WebSocketsManager.js");
Object.defineProperty(exports, "WebSocketsManager", { enumerable: true, get: function () { return WebSocketsManager_js_1.WebSocketsManager; } });
var utils_js_1 = require("./utils.js");
Object.defineProperty(exports, "getRequestBrowserPath", { enumerable: true, get: function () { return utils_js_1.getRequestBrowserPath; } });
Object.defineProperty(exports, "getRequestFilePath", { enumerable: true, get: function () { return utils_js_1.getRequestFilePath; } });
Object.defineProperty(exports, "getResponseBody", { enumerable: true, get: function () { return utils_js_1.getResponseBody; } });
Object.defineProperty(exports, "getHtmlPath", { enumerable: true, get: function () { return utils_js_1.getHtmlPath; } });
Object.defineProperty(exports, "isInlineScriptRequest", { enumerable: true, get: function () { return utils_js_1.isInlineScriptRequest; } });
var PluginSyntaxError_js_1 = require("./logger/PluginSyntaxError.js");
Object.defineProperty(exports, "PluginSyntaxError", { enumerable: true, get: function () { return PluginSyntaxError_js_1.PluginSyntaxError; } });
var PluginError_js_1 = require("./logger/PluginError.js");
Object.defineProperty(exports, "PluginError", { enumerable: true, get: function () { return PluginError_js_1.PluginError; } });
//# sourceMappingURL=index.js.map