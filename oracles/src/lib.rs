mod ops; 
mod foreign_call; 
mod handlers; 

use std::array;

use foreign_call::ForeignCallParam;
use serde_json::{json, Value};
use wasm_bindgen::{prelude::wasm_bindgen, JsValue};


#[wasm_bindgen]
pub fn handle_is_zero(inputs: Vec<String>) -> Vec<String> {
    handlers::handle_is_zero(&vec![ForeignCallParam::from(inputs)])
}