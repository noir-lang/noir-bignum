/* tslint:disable */
/* eslint-disable */
/**
* @param {(string)[]} inputs
* @returns {(string)[]}
*/
export function handle_is_zero(inputs: (string)[]): (string)[];
/**
* @param {Array<any>} inputs
* @returns {Array<any>}
*/
export function handle_mul_with_quotient(inputs: Array<any>): Array<any>;
/**
* @param {Array<any>} inputs
* @returns {Array<any>}
*/
export function handle_add(inputs: Array<any>): Array<any>;
/**
* @param {Array<any>} inputs
* @returns {Array<any>}
*/
export function handle_neg(inputs: Array<any>): Array<any>;
/**
* @param {Array<any>} inputs
* @returns {Array<any>}
*/
export function handle_udiv_mod(inputs: Array<any>): Array<any>;
/**
* @param {Array<any>} inputs
* @returns {Array<any>}
*/
export function handle_invmod(inputs: Array<any>): Array<any>;
/**
* @param {Array<any>} inputs
* @returns {Array<any>}
*/
export function handle_pow(inputs: Array<any>): Array<any>;
/**
* @param {Array<any>} inputs
* @returns {Array<any>}
*/
export function handle_div(inputs: Array<any>): Array<any>;
/**
* @param {Array<any>} inputs
* @returns {Array<any>}
*/
export function handle_barrett_reduction(inputs: Array<any>): Array<any>;
/**
* @param {Array<any>} inputs
* @returns {Array<any>}
*/
export function handle_batch_invert(inputs: Array<any>): Array<any>;

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
  readonly memory: WebAssembly.Memory;
  readonly handle_is_zero: (a: number, b: number, c: number) => void;
  readonly handle_mul_with_quotient: (a: number) => number;
  readonly handle_add: (a: number) => number;
  readonly handle_neg: (a: number) => number;
  readonly handle_udiv_mod: (a: number) => number;
  readonly handle_invmod: (a: number) => number;
  readonly handle_pow: (a: number) => number;
  readonly handle_div: (a: number) => number;
  readonly handle_barrett_reduction: (a: number) => number;
  readonly handle_batch_invert: (a: number) => number;
  readonly __wbindgen_malloc: (a: number) => number;
  readonly __wbindgen_realloc: (a: number, b: number, c: number) => number;
  readonly __wbindgen_add_to_stack_pointer: (a: number) => number;
  readonly __wbindgen_free: (a: number, b: number) => void;
}

export type SyncInitInput = BufferSource | WebAssembly.Module;
/**
* Instantiates the given `module`, which can either be bytes or
* a precompiled `WebAssembly.Module`.
*
* @param {SyncInitInput} module
*
* @returns {InitOutput}
*/
export function initSync(module: SyncInitInput): InitOutput;

/**
* If `module_or_path` is {RequestInfo} or {URL}, makes a request and
* for everything else, calls `WebAssembly.instantiate` directly.
*
* @param {InitInput | Promise<InitInput>} module_or_path
*
* @returns {Promise<InitOutput>}
*/
export default function __wbg_init (module_or_path?: InitInput | Promise<InitInput>): Promise<InitOutput>;
