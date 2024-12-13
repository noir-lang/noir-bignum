/// <reference types="node" />
import Koa from 'koa';
import { FSWatcher } from 'chokidar';
import net from 'net';
import { DevServerCoreConfig } from './DevServerCoreConfig.js';
import { Logger } from '../logger/Logger.js';
/**
 * Creates a koa server with middlewares, but does not start it. Returns the koa app and
 * http server instances.
 */
export declare function createServer(logger: Logger, cfg: DevServerCoreConfig, fileWatcher: FSWatcher, middlewareMode?: boolean): {
    app: Koa<Koa.DefaultState, Koa.DefaultContext>;
    server?: undefined;
} | {
    server: net.Server;
    app: Koa<Koa.DefaultState, Koa.DefaultContext>;
};
//# sourceMappingURL=createServer.d.ts.map