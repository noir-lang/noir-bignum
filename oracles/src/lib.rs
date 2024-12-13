mod foreign_call;
mod handlers;
mod ops;

use foreign_call::ForeignCallParam;
// use serde_json::{json, Value};
use wasm_bindgen::prelude::wasm_bindgen;
use js_sys::{JsString, Array};
// use wasm_bindgen::JsValue;


pub(crate) fn js_value_to_foreign_call_param(js_value: Array) -> Result<Vec<ForeignCallParam<String>>, JsString> {
    // create an array out of the JsValue
    // let array = Array::from(&js_value);
    let array = js_value; 
    // Convert outer array to Vec
    let result: Vec<Vec<String>> = array
        .iter()
        .map(|inner_js_value| {
            let inner_array = Array::from(&inner_js_value);
            
            inner_array
                .iter()
                .map(|js_str| {
                    js_str
                        .as_string()
                        .ok_or("Failed to convert to string")
                })
                .collect::<Result<Vec<String>, &str>>()
        })
        .collect::<Result<Vec<Vec<String>>, &str>>()
        .map_err(|e| JsString::from(e))?;
    // change these to foreign call params 
    let result = result.into_iter().map(|inner| ForeignCallParam::from(inner)).collect();

    Ok(result)
}




#[wasm_bindgen]
pub fn handle_is_zero(inputs: Vec<JsString>) -> Vec<JsString> {
    let inputs: Vec<String> = inputs.into_iter().map(|string: JsString| String::from(string)).collect();
    let result = handlers::handle_is_zero(&vec![ForeignCallParam::from(inputs)]);
    result.into_iter().map(|string| JsString::from(string)).collect()

    // nested vecs example (parens may be wrong.)
    //let inputs: Vec<Vec<String>> = inputs.into_iter().map(|inner|inner.into_iter().map(|string: JsString| String::from(string))).collect::<Vec<String>>()).collect();

}


macro_rules! create_handler {
    ($name:ident) => {
        #[wasm_bindgen]
        pub fn $name(inputs: Array) -> Array {
            let inputs = js_value_to_foreign_call_param(inputs).unwrap();
            
            let result = handlers::$name(&inputs);
            let result = result
                .into_iter()
                .map(|inner| inner
                    .into_iter()
                    .map(|string| JsString::from(string))
                    .collect::<Array>())
                .collect::<Array>();
            
            // JsValue::from(result)
            result 
        }
    };
}

create_handler!(handle_mul_with_quotient);
create_handler!(handle_add);
create_handler!(handle_neg);
create_handler!(handle_udiv_mod);
create_handler!(handle_invmod);
create_handler!(handle_pow);
create_handler!(handle_div);
create_handler!(handle_barrett_reduction);
create_handler!(handle_batch_invert);


