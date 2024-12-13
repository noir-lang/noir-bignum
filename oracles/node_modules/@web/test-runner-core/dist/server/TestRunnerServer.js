"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TestRunnerServer = void 0;
const dev_server_core_1 = require("@web/dev-server-core");
const chokidar_1 = __importDefault(require("chokidar"));
const watchFilesMiddleware_js_1 = require("./middleware/watchFilesMiddleware.js");
const cacheMiddleware_js_1 = require("./middleware/cacheMiddleware.js");
const serveTestRunnerHtmlPlugin_js_1 = require("./plugins/serveTestRunnerHtmlPlugin.js");
const serveTestFrameworkPlugin_js_1 = require("./plugins/serveTestFrameworkPlugin.js");
const testRunnerApiPlugin_js_1 = require("./plugins/api/testRunnerApiPlugin.js");
const CACHED_PATTERNS = [
    'node_modules/@web/test-runner-',
    'node_modules/@esm-bundle/chai',
    'node_modules/mocha/',
    'node_modules/chai/',
];
const isDefined = (_) => Boolean(_);
class TestRunnerServer {
    constructor(config, testRunner, sessions, testFiles, runSessions) {
        this.fileWatcher = chokidar_1.default.watch([]);
        const { plugins = [], testFramework, rootDir } = config;
        const { testFrameworkImport, testFrameworkPlugin } = testFramework
            ? (0, serveTestFrameworkPlugin_js_1.serveTestFrameworkPlugin)(testFramework)
            : {};
        const serverConfig = {
            port: config.port,
            hostname: config.hostname,
            rootDir,
            injectWebSocket: true,
            http2: config.http2,
            sslKey: config.sslKey,
            sslCert: config.sslCert,
            mimeTypes: config.mimeTypes,
            disableFileWatcher: !config.watch && !config.manual,
            middleware: [
                (0, watchFilesMiddleware_js_1.watchFilesMiddleware)({ runSessions, sessions, rootDir, fileWatcher: this.fileWatcher }),
                (0, cacheMiddleware_js_1.cacheMiddleware)(CACHED_PATTERNS, config.watch),
                ...(config.middleware || []),
            ],
            plugins: [
                (0, testRunnerApiPlugin_js_1.testRunnerApiPlugin)(config, testRunner, sessions, plugins),
                (0, serveTestRunnerHtmlPlugin_js_1.serveTestRunnerHtmlPlugin)(config, testFiles, sessions, testFrameworkImport),
                testFrameworkPlugin,
                ...(config.plugins || []),
            ].filter(isDefined),
        };
        this.devServer = new dev_server_core_1.DevServer(serverConfig, config.logger, this.fileWatcher);
    }
    async start() {
        await this.devServer.start();
    }
    async stop() {
        await this.devServer.stop();
    }
}
exports.TestRunnerServer = TestRunnerServer;
//# sourceMappingURL=TestRunnerServer.js.map