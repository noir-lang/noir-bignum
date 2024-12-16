"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TestRunner = void 0;
const createSessionGroups_js_1 = require("./createSessionGroups.js");
const getTestCoverage_js_1 = require("../coverage/getTestCoverage.js");
const TestScheduler_js_1 = require("./TestScheduler.js");
const TestSessionManager_js_1 = require("../test-session/TestSessionManager.js");
const TestSessionStatus_js_1 = require("../test-session/TestSessionStatus.js");
const EventEmitter_js_1 = require("../utils/EventEmitter.js");
const createSessionUrl_js_1 = require("./createSessionUrl.js");
const createDebugSessions_js_1 = require("./createDebugSessions.js");
const TestRunnerServer_js_1 = require("../server/TestRunnerServer.js");
class TestRunner extends EventEmitter_js_1.EventEmitter {
    constructor(config, groupConfigs = []) {
        super();
        this.startTime = -1;
        this.testRun = -1;
        this.started = false;
        this.stopped = false;
        this.running = false;
        this.passed = false;
        this.pendingSessions = new Set();
        if (!config.manual && (!config.browsers || config.browsers.length === 0)) {
            throw new Error('No browsers are configured to run tests');
        }
        if (config.manual && config.watch) {
            throw new Error('Cannot combine the manual and watch options.');
        }
        if (config.open && !config.manual) {
            throw new Error('The open option requires the manual option to be set.');
        }
        const { sessionGroups, testFiles, testSessions, browsers } = (0, createSessionGroups_js_1.createTestSessions)(config, groupConfigs);
        this.config = config;
        this.testFiles = testFiles;
        this.browsers = browsers;
        this.browserNames = Array.from(new Set(this.browsers.map(b => b.name)));
        this.browserNames.sort((a, b) => this.browsers.findIndex(br => br.name === a) - this.browsers.findIndex(br => br.name === b));
        this.sessions = new TestSessionManager_js_1.TestSessionManager(sessionGroups, testSessions);
        this.scheduler = new TestScheduler_js_1.TestScheduler(config, this.sessions, browsers);
        this.server = new TestRunnerServer_js_1.TestRunnerServer(this.config, this, this.sessions, this.testFiles, sessions => {
            this.runTests(sessions);
        });
        this.sessions.on('session-status-updated', session => {
            if (session.status === TestSessionStatus_js_1.SESSION_STATUS.FINISHED) {
                this.onSessionFinished();
            }
        });
    }
    async start() {
        try {
            if (this.started) {
                throw new Error('Cannot start twice.');
            }
            this.started = true;
            this.startTime = Date.now();
            await this.server.start();
            if (!this.config.manual) {
                for (const browser of this.browsers) {
                    if (browser.initialize) {
                        await browser.initialize(this.config, this.testFiles);
                    }
                }
                // the browser names can be updated after initialize
                this.browserNames = Array.from(new Set(this.browsers.map(b => b.name)));
                this.runTests(this.sessions.all());
            }
        }
        catch (error) {
            this.stop(error);
        }
    }
    async runTests(sessions) {
        if (this.stopped) {
            return;
        }
        if (this.running) {
            for (const session of sessions) {
                this.pendingSessions.add(session);
            }
            return;
        }
        const sessionsToRun = this.focusedTestFile
            ? Array.from(sessions).filter(f => f.testFile === this.focusedTestFile)
            : [...sessions, ...this.pendingSessions];
        this.pendingSessions.clear();
        if (sessionsToRun.length === 0) {
            return;
        }
        try {
            this.testRun += 1;
            this.running = true;
            this.scheduler.schedule(this.testRun, sessionsToRun);
            this.emit('test-run-started', { testRun: this.testRun });
        }
        catch (error) {
            this.running = false;
            this.stop(error);
        }
    }
    async stop(error) {
        if (error instanceof Error) {
            console.error('Error while running tests:');
            console.error(error);
            console.error('');
        }
        if (this.stopped) {
            return;
        }
        this.stopped = true;
        await this.scheduler.stop();
        const stopActions = [];
        const stopServerAction = this.server.stop().catch(error => {
            console.error(error);
        });
        stopActions.push(stopServerAction);
        if (this.config.watch) {
            // we only need to stop the browsers in watch mode, in non-watch
            // mode the scheduler has already stopped them
            const stopActions = [];
            for (const browser of this.browsers) {
                if (browser.stop) {
                    stopActions.push(browser.stop().catch(error => {
                        console.error(error);
                    }));
                }
            }
        }
        await Promise.all(stopActions);
        this.emit('stopped', this.passed);
    }
    startDebugBrowser(testFile) {
        const sessions = this.sessions.forTestFile(testFile);
        const debugSessions = (0, createDebugSessions_js_1.createDebugSessions)(Array.from(sessions));
        this.sessions.addDebug(...debugSessions);
        for (const session of debugSessions) {
            session.browser
                .startDebugSession(session.id, (0, createSessionUrl_js_1.createSessionUrl)(this.config, session))
                .catch(error => {
                console.error(error);
            });
        }
    }
    async onSessionFinished() {
        try {
            const finishedAll = Array.from(this.sessions.all()).every(s => s.status === TestSessionStatus_js_1.SESSION_STATUS.FINISHED);
            if (finishedAll) {
                let passedCoverage = true;
                let testCoverage = undefined;
                if (this.config.coverage) {
                    testCoverage = (0, getTestCoverage_js_1.getTestCoverage)(this.sessions.all(), this.config.coverageConfig);
                    passedCoverage = testCoverage.passed;
                }
                setTimeout(() => {
                    // emit finished event after a timeout to ensure all event listeners have processed
                    // the session status updated event
                    this.emit('test-run-finished', { testRun: this.testRun, testCoverage });
                    this.running = false;
                    if (this.pendingSessions) {
                        this.runTests(this.pendingSessions);
                    }
                });
                if (!this.config.watch) {
                    setTimeout(async () => {
                        this.passed = passedCoverage && Array.from(this.sessions.failed()).length === 0;
                        this.emit('finished', this.passed);
                    });
                }
            }
        }
        catch (error) {
            this.stop(error);
        }
    }
}
exports.TestRunner = TestRunner;
//# sourceMappingURL=TestRunner.js.map