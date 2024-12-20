"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createDebugSessions = void 0;
const nanoid_1 = require("nanoid");
function createDebugSessions(sessions) {
    const debugSessions = [];
    for (const session of sessions) {
        const debugSession = Object.assign(Object.assign({}, session), { id: (0, nanoid_1.nanoid)(), debug: true });
        debugSessions.push(debugSession);
    }
    return debugSessions;
}
exports.createDebugSessions = createDebugSessions;
//# sourceMappingURL=createDebugSessions.js.map