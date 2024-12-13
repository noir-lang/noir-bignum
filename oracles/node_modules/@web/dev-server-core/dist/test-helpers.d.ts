import { DevServer } from './server/DevServer.js';
import { DevServerCoreConfig } from './server/DevServerCoreConfig.js';
import { Logger } from './logger/Logger.js';
import { Plugin } from './plugins/Plugin.js';
export declare function virtualFilesPlugin(servedFiles: Record<string, string>): Plugin;
export declare function createTestServer(config: Partial<DevServerCoreConfig>, _mockLogger?: Logger): Promise<{
    server: DevServer;
    port: number;
    host: string;
}>;
export declare const timeout: (ms?: number) => Promise<unknown>;
export declare function fetchText(url: string, init?: RequestInit): Promise<string>;
export declare function expectIncludes(text: string, expected: string): void;
export declare function expectNotIncludes(text: string, expected: string): void;
//# sourceMappingURL=test-helpers.d.ts.map