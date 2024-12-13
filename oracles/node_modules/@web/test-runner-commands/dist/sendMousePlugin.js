"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendMousePlugin = void 0;
function isObject(payload) {
    return payload != null && typeof payload === 'object';
}
function isSendMousePayload(payload) {
    const validTypes = ['move', 'click', 'down', 'up'];
    const validButtons = ['left', 'middle', 'right'];
    if (!isObject(payload)) {
        throw new Error('You must provide a `SendMousePayload` object');
    }
    if (typeof payload.type !== 'string' || !validTypes.includes(payload.type)) {
        throw new Error(`You must provide a type option with one of the following values: ${validTypes.join(', ')}.`);
    }
    if (['click', 'move'].includes(payload.type)) {
        if (!Array.isArray(payload.position) ||
            typeof payload.position[0] !== 'number' ||
            typeof payload.position[1] !== 'number' ||
            !Number.isInteger(payload.position[0]) ||
            !Number.isInteger(payload.position[1])) {
            throw new Error('You must provide a position option as a [x, y] tuple where x and y are integers.');
        }
    }
    if (['click', 'up', 'down'].includes(payload.type)) {
        if (typeof payload.button === 'string' && !validButtons.includes(payload.button)) {
            throw new Error(`The button option must be one of the following values when provided: ${validButtons.join(', ')}.`);
        }
    }
    return true;
}
function sendMousePlugin() {
    return {
        name: 'send-mouse-command',
        async executeCommand({ command, payload, session }) {
            if (command === 'send-mouse') {
                if (!payload || !isSendMousePayload(payload)) {
                    throw new Error('You must provide a `SendMousePayload` object');
                }
                // handle specific behavior for playwright
                if (session.browser.type === 'playwright') {
                    const page = session.browser.getPage(session.id);
                    switch (payload.type) {
                        case 'move':
                            await page.mouse.move(payload.position[0], payload.position[1]);
                            return true;
                        case 'click':
                            await page.mouse.click(payload.position[0], payload.position[1], {
                                button: payload.button,
                            });
                            return true;
                        case 'down':
                            await page.mouse.down({ button: payload.button });
                            return true;
                        case 'up':
                            await page.mouse.up({ button: payload.button });
                            return true;
                    }
                }
                // handle specific behavior for puppeteer
                if (session.browser.type === 'puppeteer') {
                    const page = session.browser.getPage(session.id);
                    switch (payload.type) {
                        case 'move':
                            await page.mouse.move(payload.position[0], payload.position[1]);
                            return true;
                        case 'click':
                            await page.mouse.click(payload.position[0], payload.position[1], {
                                button: payload.button,
                            });
                            return true;
                        case 'down':
                            await page.mouse.down({ button: payload.button });
                            return true;
                        case 'up':
                            await page.mouse.up({ button: payload.button });
                            return true;
                    }
                }
                // handle specific behavior for webdriver
                if (session.browser.type === 'webdriver') {
                    const page = session.browser;
                    switch (payload.type) {
                        case 'move':
                            await page.sendMouseMove(session.id, payload.position[0], payload.position[1]);
                            return true;
                        case 'click':
                            await page.sendMouseClick(session.id, payload.position[0], payload.position[1], payload.button);
                            return true;
                        case 'down':
                            await page.sendMouseDown(session.id, payload.button);
                            return true;
                        case 'up':
                            await page.sendMouseUp(session.id, payload.button);
                            return true;
                    }
                }
                // you might not be able to support all browser launchers
                throw new Error(`Sending mouse is not supported for browser type ${session.browser.type}.`);
            }
            if (command === 'reset-mouse') {
                // handle specific behavior for playwright
                if (session.browser.type === 'playwright') {
                    const page = session.browser.getPage(session.id);
                    await page.mouse.up({ button: 'left' });
                    await page.mouse.up({ button: 'middle' });
                    await page.mouse.up({ button: 'right' });
                    await page.mouse.move(0, 0);
                    return true;
                }
                // handle specific behavior for puppeteer
                if (session.browser.type === 'puppeteer') {
                    const page = session.browser.getPage(session.id);
                    await page.mouse.reset();
                    return true;
                }
                // handle specific behavior for webdriver
                if (session.browser.type === 'webdriver') {
                    const page = session.browser;
                    await page.resetMouse(session.id);
                    return true;
                }
                // you might not be able to support all browser launchers
                throw new Error(`Resetting mouse is not supported for browser type ${session.browser.type}.`);
            }
        },
    };
}
exports.sendMousePlugin = sendMousePlugin;
//# sourceMappingURL=sendMousePlugin.js.map