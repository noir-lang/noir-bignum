"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.expectNotIncludes = exports.expectIncludes = exports.fetchText = exports.timeout = exports.createTestServer = exports.virtualFilesPlugin = void 0;
const portfinder_1 = __importDefault(require("portfinder"));
const chai_1 = require("chai");
const nanocolors_1 = require("nanocolors");
const DevServer_js_1 = require("./server/DevServer.js");
const defaultConfig = {
    hostname: 'localhost',
    injectWebSocket: true,
    middleware: [],
    plugins: [],
};
const mockLogger = Object.assign(Object.assign({}, console), { debug() {
        // no debug
    },
    logSyntaxError(error) {
        console.error(error);
    } });
function virtualFilesPlugin(servedFiles) {
    return {
        name: 'test-helpers-virtual-files',
        serve(context) {
            if (context.path in servedFiles) {
                return servedFiles[context.path];
            }
        },
    };
}
exports.virtualFilesPlugin = virtualFilesPlugin;
async function createTestServer(config, _mockLogger = mockLogger) {
    if (!config.rootDir) {
        throw new Error('A rootDir must be configured.');
    }
    const port = await portfinder_1.default.getPortPromise({
        port: 9000 + Math.floor(Math.random() * 1000),
    });
    const server = new DevServer_js_1.DevServer(Object.assign(Object.assign(Object.assign({}, defaultConfig), config), { rootDir: config.rootDir, port }), _mockLogger);
    await server.start();
    const url = new URL('http://localhost');
    url.protocol = config.http2 ? 'https' : 'http';
    url.port = port.toString();
    return { server, port, host: url.toString().slice(0, -1) };
}
exports.createTestServer = createTestServer;
const timeout = (ms = 0) => new Promise(resolve => setTimeout(resolve, ms));
exports.timeout = timeout;
async function fetchText(url, init) {
    const response = await fetch(url, init);
    (0, chai_1.expect)(response.status).to.equal(200);
    return response.text();
}
exports.fetchText = fetchText;
function expectIncludes(text, expected) {
    if (!text.includes(expected)) {
        throw new Error((0, nanocolors_1.red)(`Expected "${(0, nanocolors_1.yellow)(expected)}" in string: \n\n${(0, nanocolors_1.green)(text)}`));
    }
}
exports.expectIncludes = expectIncludes;
function expectNotIncludes(text, expected) {
    if (text.includes(expected)) {
        throw new Error(`Did not expect "${expected}" in string: \n\n${text}`);
    }
}
exports.expectNotIncludes = expectNotIncludes;
//# sourceMappingURL=test-helpers.js.map