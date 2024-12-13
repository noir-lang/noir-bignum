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
exports.chromeLauncher = exports.puppeteerCore = exports.ChromeLauncher = void 0;
const puppeteerCore = __importStar(require("puppeteer-core"));
exports.puppeteerCore = puppeteerCore;
const ChromeLauncher_js_1 = require("./ChromeLauncher.js");
Object.defineProperty(exports, "ChromeLauncher", { enumerable: true, get: function () { return ChromeLauncher_js_1.ChromeLauncher; } });
function chromeLauncher(args = {}) {
    const { launchOptions = {}, createBrowserContext = ({ browser }) => browser.defaultBrowserContext(), createPage = ({ context }) => context.newPage(), puppeteer, concurrency, } = args;
    return new ChromeLauncher_js_1.ChromeLauncher(launchOptions, createBrowserContext, createPage, puppeteer, concurrency);
}
exports.chromeLauncher = chromeLauncher;
//# sourceMappingURL=index.js.map