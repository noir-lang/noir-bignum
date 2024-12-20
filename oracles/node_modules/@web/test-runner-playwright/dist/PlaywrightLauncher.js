"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PlaywrightLauncher = void 0;
const playwright_1 = __importDefault(require("playwright"));
const PlaywrightLauncherPage_1 = require("./PlaywrightLauncherPage");
function capitalize(str) {
    return `${str[0].toUpperCase()}${str.substring(1)}`;
}
class PlaywrightLauncher {
    constructor(product, launchOptions, createBrowserContextFn, createPageFn, __experimentalWindowFocus__, concurrency) {
        this.type = 'playwright';
        this.activePages = new Map();
        this.activeDebugPages = new Map();
        this.testCoveragePerSession = new Map();
        this.product = product;
        this.launchOptions = launchOptions;
        this.createBrowserContextFn = createBrowserContextFn;
        this.createPageFn = createPageFn;
        this.concurrency = concurrency;
        this.name = capitalize(product);
        this.__experimentalWindowFocus__ = !!__experimentalWindowFocus__;
    }
    async initialize(config, testFiles) {
        this.config = config;
        this.testFiles = testFiles;
    }
    async stop() {
        var _a, _b;
        if ((_a = this.browser) === null || _a === void 0 ? void 0 : _a.isConnected()) {
            await this.browser.close();
        }
        if ((_b = this.debugBrowser) === null || _b === void 0 ? void 0 : _b.isConnected()) {
            await this.debugBrowser.close();
        }
    }
    async startSession(sessionId, url) {
        var _a;
        const browser = await this.getOrStartBrowser();
        const page = await this.createNewPage(browser);
        this.activePages.set(sessionId, page);
        this.testCoveragePerSession.delete(sessionId);
        await page.runSession(url, !!((_a = this.config) === null || _a === void 0 ? void 0 : _a.coverage));
    }
    isActive(sessionId) {
        return this.activePages.has(sessionId);
    }
    getBrowserUrl(sessionId) {
        return this.getPage(sessionId).url();
    }
    async startDebugSession(sessionId, url) {
        if (!this.debugBrowser) {
            this.debugBrowser = await playwright_1.default[this.product].launch(Object.assign(Object.assign({}, this.launchOptions), { 
                // devtools is only supported on chromium
                devtools: this.product === 'chromium', headless: false }));
        }
        const page = await this.createNewPage(this.debugBrowser);
        this.activeDebugPages.set(sessionId, page);
        page.playwrightPage.on('close', () => {
            this.activeDebugPages.delete(sessionId);
        });
        await page.runSession(url, false);
    }
    async createNewPage(browser) {
        const playwrightContext = await this.createBrowserContextFn({ config: this.config, browser });
        const playwrightPage = await this.createPageFn({
            config: this.config,
            browser,
            context: playwrightContext,
        });
        return new PlaywrightLauncherPage_1.PlaywrightLauncherPage(this.config, this.product, this.testFiles, playwrightContext, playwrightPage);
    }
    async stopSession(sessionId) {
        const page = this.activePages.get(sessionId);
        if (!page) {
            throw new Error(`No page for session ${sessionId}`);
        }
        if (page.playwrightPage.isClosed()) {
            throw new Error(`Session ${sessionId} is already stopped`);
        }
        const result = await page.stopSession();
        this.activePages.delete(sessionId);
        return result;
    }
    async getOrStartBrowser() {
        var _a;
        if (this.__launchBrowserPromise) {
            return this.__launchBrowserPromise;
        }
        if (!this.browser || !((_a = this.browser) === null || _a === void 0 ? void 0 : _a.isConnected())) {
            this.__launchBrowserPromise = (async () => {
                const browser = await playwright_1.default[this.product].launch(this.launchOptions);
                return browser;
            })();
            const browser = await this.__launchBrowserPromise;
            this.browser = browser;
            this.__launchBrowserPromise = undefined;
        }
        return this.browser;
    }
    getPage(sessionId) {
        var _a, _b, _c;
        const page = (_b = (_a = this.activePages.get(sessionId)) === null || _a === void 0 ? void 0 : _a.playwrightPage) !== null && _b !== void 0 ? _b : (_c = this.activeDebugPages.get(sessionId)) === null || _c === void 0 ? void 0 : _c.playwrightPage;
        if (!page) {
            throw new Error(`Could not find a page for session ${sessionId}`);
        }
        return page;
    }
}
exports.PlaywrightLauncher = PlaywrightLauncher;
//# sourceMappingURL=PlaywrightLauncher.js.map