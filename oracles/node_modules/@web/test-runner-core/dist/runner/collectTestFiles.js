"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.collectTestFiles = void 0;
const globby_1 = __importDefault(require("globby"));
const path_1 = require("path");
function collectTestFiles(patterns, baseDir = process.cwd()) {
    const normalizedPatterns = [patterns].flat().map(p => p.split(path_1.sep).join('/'));
    return globby_1.default.sync(normalizedPatterns, { cwd: baseDir, absolute: true });
}
exports.collectTestFiles = collectTestFiles;
//# sourceMappingURL=collectTestFiles.js.map