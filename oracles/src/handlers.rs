use ark_bn254::Fr;
use num_bigint::BigUint; // It's pretty disgusting that I've introduced this library, just to convert to/from radix 16. I wonder if there's a better way with arkworks?
use num_traits::Num; // It's pretty disgusting that I've introduced this library, just to convert to/from radix 16. I wonder if there's a better way with arkworks?
use serde_json::{json, Value};
// use std::str::FromStr;

use crate::foreign_call::ForeignCallParam;

use crate::ops::sqrt;

/**** THERE'S A LOT OF BOILERPLATE INSIDE THESE "HANDLERS", THAT WE CAN PROBABLY PUT INTO COMMON HELPER FUNCTIONS ****/

/** Note: I _think_ the type `Vec<ForeignCallParam<String>>` will be generically applicable to _any_ oracle call arguments, so I've made _all_ handlers receive this type. */
pub(crate) fn handle_get_sqrt(inputs: &Vec<ForeignCallParam<String>>) -> Value {
    /**** EXTRACT INPUT STRING(S) ****/
    println!("inputs: {:?}", inputs);
    assert!(inputs.len() == 1);

    let input_param = &inputs[0];

    let input_string = match input_param {
        ForeignCallParam::Single(value) => value.trim_start_matches('0'), // Trimming leading zeroes turned out to be very important, otherwise `from_str` on the next line was erroring!
        ForeignCallParam::Array(_) => panic!("Expected single value, found array"),
    };

    println!("input_string: {:?}", input_string);

    /**** CONVERT INPUT STRING(S) TO MEANINGFUL TYPE(S) ****/
    let x_big_uint: BigUint = BigUint::from_str_radix(input_string, 16).unwrap();
    let x: Fr = x_big_uint.into();
    // let x: Fr = Fr::from_str(input_string).unwrap(); // This was incorrectly assuming the input_string to be decimal.
    println!("x: {:?}", x);

    /**** OPERATE ****/
    let sqrt = sqrt(x);
    println!("Computed sqrt: {:?}", sqrt);

    /**** ENSURE HEX ****/
    let as_big_uint: BigUint = sqrt.unwrap().into();
    let as_hex_str = as_big_uint.to_str_radix(16);

    let oracle_return_data_the_noir_program_expects = as_hex_str;

    /**** FORMAT RESULT FOR NOIR CONSUMPTION, AND CONVERT RESULT TO JSON `Value` TYPE ****/
    //** Note: I'm converting to `Value` within these "handler" functions, instead of within the main callback (the callback inside run_server --> module.register_method --> resolve_foreign_call), because the return types can be subtly different: Vec<String>, or Vec<Vec<String>>, or maybe some more-complex arrangement of Strings and Vec<Strings>. It felt easiest to have the "hander" functions figure out how to serialise their return data. */
    let return_vec = vec![oracle_return_data_the_noir_program_expects];
    println!("return_vec: {:?}", return_vec);

    let json_response = json!({"values" : return_vec});
    println!("json_response: {:?}", json_response);
    json_response
}


pub(crate) fn handle_get_sqrts(inputs: &Vec<ForeignCallParam<String>>) -> Value {
    /**** EXTRACT INPUT STRING(S) ****/
    println!("inputs: {:?}", inputs);

    let input_param = &inputs[0];
    let input_strings: Vec<&str> = match input_param {
        ForeignCallParam::Single(_value) => panic!("Expected array, found single value"),
        ForeignCallParam::Array(values) => values
            .into_iter()
            .map(|v| v.trim_start_matches('0'))
            .collect(),
    };

    println!("input_strings: {:?}", input_strings);

    let mut sqrts: Vec<String> = vec![];

    for input_string in input_strings {
        /**** CONVERT INPUT STRING(S) TO MEANINGFUL TYPE(S) ****/
        println!("input_string: {:?}", input_string);

        let x_big_uint: BigUint = BigUint::from_str_radix(input_string, 16).unwrap();
        let x: Fr = x_big_uint.into();
        // let x: Fr = Fr::from_str(input_string).unwrap(); // This was incorrectly assuming the input_string to be decimal.
        println!("x: {:?}", x);

        /**** OPERATE ****/
        let sqrt = sqrt(x);
        println!("Computed sqrt: {:?}", sqrt);

        /**** ENSURE HEX ****/
        let as_big_uint: BigUint = sqrt.unwrap().into();
        let as_hex_str = as_big_uint.to_str_radix(16);

        sqrts.push(as_hex_str);
    }

    let oracle_return_data_the_noir_program_expects = sqrts;

    /**** FORMAT RESULT FOR NOIR CONSUMPTION, AND CONVERT RESULT TO JSON `Value` TYPE ****/
    let return_vec = vec![oracle_return_data_the_noir_program_expects]; // Notice! This is a different type from the singular handle_get_sqrt function! Hence why the `Value` is being computed inside this function, instead in the calling function.
    println!("return_vec: {:?}", return_vec);

    let json_response = json!({"values" : return_vec});
    println!("json_response: {:?}", json_response);
    json_response
}




// ==============================
// ==============================
// ==============================
// call handler for is_zero
pub(crate) fn handle_is_zero(inputs: &Vec<ForeignCallParam<String>>) -> Value {
    println!("you called the is_zero function with inputs: {:?}", inputs);
    // Create a vector with a single boolean value (true) as the result
    let return_vec = vec![true];

    // Create a JSON object with a "values" key containing the return_vec
    let json_response = json!({"values" : return_vec});

    // Print the JSON response for debugging purposes
    println!("json_response: {:?}", json_response);
    json_response
}

// ==============================
// ==============================
// ==============================
// call handler for add
pub(crate) fn handle_add(inputs: &Vec<ForeignCallParam<String>>) -> Value {
    println!("inputs for add: {:?}", inputs);

    let input_param = &inputs[0];
    // println!("input_param: {:?}", input_param);
    
    // println!("inputs length: {:?}", inputs.len());
    let mut has_multiplicative_inverse = inputs[0].clone();
    let mut modulus = inputs[1].clone();
    let mut modulus_u60 = inputs[2].clone();
    let mut modulus_u60_x4 = inputs[3].clone();
    let mut double_modulus = inputs[4].clone();
    let mut redc_param = inputs[5].clone();
    let mut lhs = inputs[6].clone();
    let mut rhs = inputs[7].clone();

    // get the number of limbs from the length of the modulus
    let N = modulus.len();  
    println!("number of limbs {:?}", N);
    let modulus_values: Vec<String> = modulus.get_values();
    println!("modulus_values length: {:?}", modulus_values.len());
    let has_multiplicative_inverse_value = has_multiplicative_inverse.get_values();
    println!("has_multiplicative_inverse_value: {:?}", has_multiplicative_inverse_value);
    // println!("modulus: {:?}", modulus_values);

    // println!("has_multiplicative_inverse: {:?}", has_multiplicative_inverse);
    // println!("modulus length: {:?}", modulus.len());
    // println!("modulus_u60: {:?}", modulus_u60);
    // println!("modulus_u60_x4: {:?}", modulus_u60_x4);
    // println!("double_modulus: {:?}", double_modulus);
    // println!("redc_param: {:?}", redc_param);
    // println!("lhs: {:?}", lhs); 
    // println!("rhs: {:?}", rhs);


    // println!("number_of_limbs: {:?}", number_of_limbs);

    // compute what the number of limbs are
    // println!("lhs: {:?}", lhs);
    // println!("rhs: {:?}", rhs);

    // println!("input_param type: {:?}", input_param.type_name());
    // let input_strings = inputs.unwrap(); 
    // println!("input_strings: {:?}", input_strings);
    // let input_strings: Vec<&str> = match input_param {
    //     ForeignCallParam::Single(_value) => panic!("Expected array, found single value"),
    //     ForeignCallParam::Array(values) => values
    //         .into_iter()
    //         .map(|v| v.trim_start_matches('0'))
    //         .collect(),
    // };

    
    let return_vec = vec![true];
    let json_response = json!({"values" : return_vec});
    json_response
}