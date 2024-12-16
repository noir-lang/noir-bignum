"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getSelectFilesMenu = void 0;
const nanocolors_1 = require("nanocolors");
const path_1 = require("path");
function getSelectFilesMenu(succeededFiles, failedFiles) {
    const maxI = succeededFiles.length + failedFiles.length;
    const minWidth = maxI.toString().length + 1;
    function formatTestFile(file, i, offset, failed) {
        const relativePath = (0, path_1.relative)(process.cwd(), file);
        return `[${i + offset}]${' '.repeat(Math.max(0, minWidth - (i + offset).toString().length))}${failed ? (0, nanocolors_1.red)(relativePath) : (0, nanocolors_1.cyan)(relativePath)}`;
    }
    const entries = [
        'Test files:\n',
        ...succeededFiles.map((f, i) => formatTestFile(f, i, failedFiles.length + 1, false)),
        '',
    ];
    if (failedFiles.length > 0) {
        entries.push('Failed test files:\n', ...failedFiles.map((f, i) => formatTestFile(f, i, 1, true)));
    }
    return entries;
}
exports.getSelectFilesMenu = getSelectFilesMenu;
//# sourceMappingURL=getSelectFilesMenu.js.map