/// <reference types="node" />
import Koa from 'koa';
import { Server } from 'net';
import { DevServerCoreConfig } from './DevServerCoreConfig.js';
import { Logger } from '../logger/Logger.js';
import { WebSocketsManager } from '../web-sockets/WebSocketsManager.js';
export declare class DevServer {
    config: DevServerCoreConfig;
    logger: Logger;
    fileWatcher: import("chokidar").FSWatcher;
    koaApp: Koa;
    server?: Server;
    webSockets?: WebSocketsManager;
    private started;
    private connections;
    constructor(config: DevServerCoreConfig, logger: Logger, fileWatcher?: import("chokidar").FSWatcher);
    start(): Promise<void>;
    private closeServer;
    stop(): Promise<[void, ...(void | undefined)[], void | undefined] | undefined>;
}
//# sourceMappingURL=DevServer.d.ts.map