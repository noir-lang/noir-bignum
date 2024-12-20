"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getWatchCommands = void 0;
const nanocolors_1 = require("nanocolors");
function getWatchCommands(coverage, testFiles, focusedTest) {
    if (focusedTest) {
        return [
            `${(0, nanocolors_1.gray)('Press')} F ${(0, nanocolors_1.gray)('to focus another test file.')}`,
            `${(0, nanocolors_1.gray)('Press')} D ${(0, nanocolors_1.gray)('to debug in the browser.')}`,
            coverage ? `${(0, nanocolors_1.gray)('Press')} C ${(0, nanocolors_1.gray)('to view coverage details.')}` : '',
            `${(0, nanocolors_1.gray)('Press')} Q ${(0, nanocolors_1.gray)('to exit watch mode.')}`,
            `${(0, nanocolors_1.gray)('Press')} Enter ${(0, nanocolors_1.gray)('to re-run this test file.')}`,
            `${(0, nanocolors_1.gray)('Press')} ESC ${(0, nanocolors_1.gray)('to exit focus mode')}`,
        ].filter(_ => !!_);
    }
    return [
        testFiles.length > 1 ? `${(0, nanocolors_1.gray)('Press')} F ${(0, nanocolors_1.gray)('to focus on a test file.')}` : '',
        `${(0, nanocolors_1.gray)('Press')} D ${(0, nanocolors_1.gray)('to debug in the browser.')}`,
        `${(0, nanocolors_1.gray)('Press')} M ${(0, nanocolors_1.gray)('to debug manually in a custom browser.')}`,
        coverage ? `${(0, nanocolors_1.gray)('Press')} C ${(0, nanocolors_1.gray)('to view coverage details.')}` : '',
        `${(0, nanocolors_1.gray)('Press')} Q ${(0, nanocolors_1.gray)('to quit watch mode.')}`,
        `${(0, nanocolors_1.gray)('Press')} Enter ${(0, nanocolors_1.gray)('to re-run all tests.')}`,
    ].filter(_ => !!_);
}
exports.getWatchCommands = getWatchCommands;
//# sourceMappingURL=getWatchCommands.js.map