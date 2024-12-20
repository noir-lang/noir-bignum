"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.request = void 0;
const http_1 = require("http");
const https_1 = require("https");
function request(options) {
    const isHttps = options.protocol === 'https:';
    const requestFn = isHttps ? https_1.request : http_1.request;
    if (isHttps) {
        options.rejectUnauthorized = false;
    }
    return new Promise((resolve, reject) => {
        const req = requestFn(options, response => {
            let body = '';
            response.on('data', chunk => {
                body += chunk;
            });
            response.on('end', () => {
                resolve({ response, body });
            });
        });
        req.on('error', err => {
            reject(err);
        });
        req.end();
    });
}
exports.request = request;
//# sourceMappingURL=request.js.map