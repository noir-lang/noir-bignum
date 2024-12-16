import { Middleware } from 'koa';
import { FSWatcher } from 'chokidar';
import { DevServerCoreConfig } from './DevServerCoreConfig.js';
import { Logger } from '../logger/Logger.js';
/**
 * Creates middlewares based on the given configuration. The middlewares can be
 * used by a koa server using `app.use()`:
 */
export declare function createMiddleware(config: DevServerCoreConfig, logger: Logger, fileWatcher: FSWatcher): Middleware[];
//# sourceMappingURL=createMiddleware.d.ts.map