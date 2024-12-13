"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.snapshotPlugin = void 0;
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const util_1 = require("util");
const mkdirp_1 = __importDefault(require("mkdirp"));
const readFile = (0, util_1.promisify)(fs_1.default.readFile);
const writeFile = (0, util_1.promisify)(fs_1.default.writeFile);
const unlink = (0, util_1.promisify)(fs_1.default.unlink);
const access = (0, util_1.promisify)(fs_1.default.access);
async function fileExists(filePath) {
    try {
        await access(filePath);
        return true;
    }
    catch (_a) {
        return false;
    }
}
function isObject(payload) {
    return payload != null && typeof payload === 'object';
}
function isSaveSnapshotPayload(payload) {
    if (!isObject(payload))
        throw new Error('You must provide a payload object');
    if (typeof payload.name !== 'string')
        throw new Error('You must provide a path option');
    if (payload.content !== undefined && typeof payload.content !== 'string')
        throw new Error('You must provide a content option');
    return true;
}
function getSnapshotPath(testFile) {
    const testDir = path_1.default.dirname(testFile);
    const testFileName = path_1.default.basename(testFile);
    const ext = path_1.default.extname(testFileName);
    const fileWithoutExt = testFileName.substring(0, testFileName.length - ext.length);
    return path_1.default.join(testDir, '__snapshots__', `${fileWithoutExt}.snap.js`);
}
class SnapshotStore {
    constructor() {
        this.snapshots = new Map();
        this.sessionToSnapshotPath = new Map();
        this.readOperations = new Map();
    }
    async get(testFilePath) {
        var _a, _b;
        const snapshotPath = getSnapshotPath(testFilePath);
        if (this.readOperations.has(snapshotPath)) {
            // something else is already reading, wait for it
            await ((_a = this.readOperations.get(snapshotPath)) === null || _a === void 0 ? void 0 : _a.promise);
        }
        const cachedContent = this.snapshots.get(snapshotPath);
        if (cachedContent) {
            // return from cache
            return cachedContent;
        }
        const promiseObj = { resolve: () => { }, promise: Promise.resolve() };
        promiseObj.promise = new Promise(resolve => {
            promiseObj.resolve = resolve;
        });
        this.readOperations.set(testFilePath, promiseObj);
        // store in cache
        const content = (await fileExists(snapshotPath))
            ? await readFile(snapshotPath, 'utf-8')
            : '/* @web/test-runner snapshot v1 */\nexport const snapshots = {};\n\n';
        this.snapshots.set(snapshotPath, content);
        // resolve read promise to let others who are waiting continue
        (_b = this.readOperations.get(snapshotPath)) === null || _b === void 0 ? void 0 : _b.resolve();
        this.readOperations.delete(snapshotPath);
        return content;
    }
    async saveSnapshot(sessionId, testFilePath, name, updatedSnapshot) {
        const snapshotPath = getSnapshotPath(testFilePath);
        const nameStr = JSON.stringify(name);
        const startMarker = `snapshots[${nameStr}]`;
        const endMarker = `/* end snapshot ${name} */\n\n`;
        const replacement = updatedSnapshot
            ? `${startMarker} = \n\`${updatedSnapshot}\`;\n${endMarker}`
            : '';
        const content = await this.get(testFilePath);
        let updatedContent;
        const startIndex = content.indexOf(startMarker);
        if (startIndex !== -1) {
            // replace existing snapshot
            const endIndex = content.indexOf(endMarker);
            if (endIndex === -1) {
                throw new Error('Missing snapshot end marker');
            }
            const beforeReplace = content.substring(0, startIndex);
            const afterReplace = content.substring(endIndex + endMarker.length);
            updatedContent = `${beforeReplace}${replacement}${afterReplace}`;
        }
        else {
            // add new snapshot
            updatedContent = `${content}${replacement}`;
        }
        if (updatedContent === content) {
            // snapshot did not actually change, avoid marking snapshot as dirty
            return;
        }
        this.sessionToSnapshotPath.set(sessionId, snapshotPath);
        this.snapshots.set(snapshotPath, updatedContent);
    }
    getSnapshotPathForSession(sessionId) {
        return this.sessionToSnapshotPath.get(sessionId);
    }
    async writeSnapshot(snapshotPath) {
        const updatedContent = this.snapshots.get(snapshotPath);
        if (!updatedContent) {
            throw new Error('Unexpected error while writing snapshots, could not find snapshot content.');
        }
        if (updatedContent.includes('/* end snapshot')) {
            // update or create snapshot
            const fileDir = path_1.default.dirname(snapshotPath);
            await (0, mkdirp_1.default)(fileDir);
            await writeFile(snapshotPath, updatedContent);
        }
        else {
            // snapshot file is empty, remove it
            if (await fileExists(snapshotPath)) {
                await unlink(snapshotPath);
            }
        }
    }
}
function snapshotPlugin(config) {
    const updateSnapshots = config && config.updateSnapshots;
    const snapshots = new SnapshotStore();
    const writePromises = new Set();
    return {
        name: 'file-commands',
        serverStart({ webSockets }) {
            webSockets.on('message', async ({ data }) => {
                const { type, sessionId } = data;
                if (type === 'wtr-session-finished') {
                    if (typeof sessionId !== 'string') {
                        throw new Error('Missing session id in wtr-session-finished event');
                    }
                    const snapshotPath = snapshots.getSnapshotPathForSession(sessionId);
                    if (!snapshotPath) {
                        return;
                    }
                    const writePromise = snapshots.writeSnapshot(snapshotPath);
                    writePromises.add(writePromise);
                    await writePromise;
                    writePromises.delete(writePromise);
                }
            });
        },
        async serverStop() {
            // ensure all write operations are finished
            await Promise.all([...writePromises]);
        },
        async executeCommand({ command, payload, session }) {
            if (command === 'get-snapshot-config') {
                return { updateSnapshots };
            }
            if (command === 'get-snapshots') {
                const content = await snapshots.get(session.testFile);
                return { content };
            }
            if (command === 'save-snapshot') {
                if (!isSaveSnapshotPayload(payload)) {
                    throw new Error('Invalid save snapshot payload');
                }
                await snapshots.saveSnapshot(session.id, session.testFile, payload.name, payload.content);
                return true;
            }
        },
    };
}
exports.snapshotPlugin = snapshotPlugin;
//# sourceMappingURL=snapshotPlugin.js.map