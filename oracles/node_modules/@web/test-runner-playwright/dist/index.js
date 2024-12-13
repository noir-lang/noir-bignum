"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.playwrightLauncher = exports.devices = exports.PlaywrightLauncher = exports.playwright = void 0;
const playwright_1 = require("playwright");
Object.defineProperty(exports, "devices", { enumerable: true, get: function () { return playwright_1.devices; } });
const playwright = __importStar(require("playwright"));
exports.playwright = playwright;
const PlaywrightLauncher_1 = require("./PlaywrightLauncher");
Object.defineProperty(exports, "PlaywrightLauncher", { enumerable: true, get: function () { return PlaywrightLauncher_1.PlaywrightLauncher; } });
const validProductTypes = ['chromium', 'firefox', 'webkit'];
function playwrightLauncher(args = {}) {
    const { product = 'chromium', launchOptions = {}, createBrowserContext = ({ browser }) => browser.newContext(), createPage = ({ context }) => context.newPage(), __experimentalWindowFocus__ = false, concurrency, } = args;
    if (!validProductTypes.includes(product)) {
        throw new Error(`Invalid product: ${product}. Valid product types: ${validProductTypes.join(', ')}`);
    }
    return new PlaywrightLauncher_1.PlaywrightLauncher(product, launchOptions, createBrowserContext, createPage, __experimentalWindowFocus__, concurrency);
}
exports.playwrightLauncher = playwrightLauncher;
//# sourceMappingURL=index.js.map