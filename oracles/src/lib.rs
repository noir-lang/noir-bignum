mod foreign_call;
mod handlers;
mod ops;

use foreign_call::ForeignCallParam;
// use serde_json::{json, Value};
use wasm_bindgen::prelude::wasm_bindgen;
use js_sys::JsString;


#[wasm_bindgen]
pub fn handle_is_zero(inputs: Vec<JsString>) -> Vec<JsString> {
    let inputs: Vec<String> = inputs.into_iter().map(|string: JsString| String::from(string)).collect();
    let result = handlers::handle_is_zero(&vec![ForeignCallParam::from(inputs)]);
    result.into_iter().map(|string| JsString::from(string)).collect()

    // nested vecs example (parens may be wrong.)
    //let inputs: Vec<Vec<String>> = inputs.into_iter().map(|inner|inner.into_iter().map(|string: JsString| String::from(string))).collect::<Vec<String>>()).collect();

}
