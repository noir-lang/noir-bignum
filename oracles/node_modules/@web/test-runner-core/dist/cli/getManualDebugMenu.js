"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getManualDebugMenu = void 0;
const nanocolors_1 = require("nanocolors");
const internal_ip_1 = __importDefault(require("internal-ip"));
function getManualDebugMenu(config) {
    const localAddress = `${config.protocol}//${config.hostname}:${config.port}/`;
    const networkAddress = `${config.protocol}//${internal_ip_1.default.v4.sync()}:${config.port}/`;
    return [
        'Debug manually in a browser not controlled by the test runner.',
        ' ',
        "Advanced functionalities such commands for changing viewport and screenshots don't work there.",
        'Use the regular debug option to debug in a controlled browser.',
        ' ',
        `Local address:   ${(0, nanocolors_1.cyan)(localAddress)}`,
        `Network address: ${(0, nanocolors_1.cyan)(networkAddress)}`,
        ' ',
        `${(0, nanocolors_1.gray)('Press')} D ${(0, nanocolors_1.gray)('to open the browser.')}`,
        `${(0, nanocolors_1.gray)('Press')} ${config.manual ? 'Q' : 'ESC'} ${(0, nanocolors_1.gray)('to exit manual debug.')}`,
    ].filter(_ => !!_);
}
exports.getManualDebugMenu = getManualDebugMenu;
//# sourceMappingURL=getManualDebugMenu.js.map