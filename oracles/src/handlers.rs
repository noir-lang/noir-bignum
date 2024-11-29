use ark_bn254::Fr;
use ark_ff::Zero;
use num_bigint::BigUint; // It's pretty disgusting that I've introduced this library, just to convert to/from radix 16. I wonder if there's a better way with arkworks?
use num_traits::Num; // It's pretty disgusting that I've introduced this library, just to convert to/from radix 16. I wonder if there's a better way with arkworks?
use serde_json::{json, Value};
// use std::str::FromStr;

use crate::foreign_call::ForeignCallParam;
use crate::ops::is_zero;
use crate::ops::sqrt;



// a struct that emulates the bignum Params params from the params.nr file
struct Params {
    has_multiplicative_inverse: bool,
    modulus: Vec<Fr>,
    double_modulus: Vec<Fr>,
    redc_param: Vec<Fr>,
}

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
    let input_param = &inputs[0];
    println!("input_param: {:?}", input_param);
    // parse the input into strings 
    let mut input_strings =  vec![]; 
    for input in inputs {
        input_strings.push(callparam_to_string(input)[0]);
    }
    let limbs = gets_limbs(input_strings);
    // call the is_zero function from the ops.rs 
    let result= is_zero(limbs);  
    // print the result 
    println!("Computed result: {:?}", result);
    /**** ENSURE HEX ****/
    let as_big_uint: BigUint = result.into();
    let as_hex_str = as_big_uint.to_str_radix(16);
    let mut results: Vec<String> = vec![];
    println!("as_hex_str: {:?}", as_hex_str);
    results.push(as_hex_str);
    let oracle_return_data_the_noir_program_expects = results;

    /**** FORMAT RESULT FOR NOIR CONSUMPTION, AND CONVERT RESULT TO JSON `Value` TYPE ****/
    let return_vec = oracle_return_data_the_noir_program_expects; // Notice! This is a different type from the singular handle_get_sqrt function! Hence why the `Value` is being computed inside this function, instead in the calling function.
    println!("return_vec: {:?}", return_vec);

    let json_response = json!({"values" : return_vec});
    println!("json_response: {:?}", json_response);
    json_response      
}

// ==============================
// ==============================
// ==============================
// call handler for add
// the inputs of the function are params, lhs, rhs, num_limbs, mod_bits, returns the result of the addition which is a vector of hex limbs
// params are of form  
// lhs and rhs are vector of limbs 
// the input is 8 elements
pub(crate) fn handle_add(inputs: &Vec<ForeignCallParam<String>>) -> Value {
    
    // parse the input, the last 2 elements of the input are the modulus bits and the number of limbs
    let modulus_bits_fc = &inputs[inputs.len()-1];
    let num_limbs_fc = &inputs[inputs.len()-2];
    let modulus_bits = get_u32_from_callparam(&modulus_bits_fc);
    let num_limbs = get_u32_from_callparam(&num_limbs_fc);  
    // parse out the limbs of the lhs and rhs and cast them into Fr elements
    let lhs_fc = &inputs[inputs.len()-3];
    let rhs_fc = &inputs[inputs.len()-4];
    let limbs_lhs = gets_limbs(callparam_to_string(lhs_fc));
    let limbs_rhs = gets_limbs(callparam_to_string(rhs_fc));
    
    // lastly parse out the params 
    // the params consist of has_multiplicative_inverse, modulus, double_modulus, redc_param
    let has_multiplicative_inverse_fc = &inputs[0];
    let modulus_fc = &inputs[1];
    let double_modulus_fc = &inputs[4];
    let redc_param_fc = &inputs[5];
    // create the params struct
    let params: Params = Params::from_foreign_call_params(&inputs);
    println!("params: {:?}", params);
    
    let return_vec:Vec<String> = vec![];
    let json_response = json!({"values" : return_vec});
    json_response

}


// helper function to get limbs of a big num and pack them into a vector of Fr elements
pub (crate) fn gets_limbs(input_strings: Vec<&str>) -> Vec<Fr> {
    let mut limbs: Vec<Fr> = vec![];
    for input_string in input_strings {
        // handle the case of a zero input 
        if input_string == "" {
            let x_big_uint = BigUint::from_str_radix("0", 16).unwrap();
            let limb: Fr = x_big_uint.into();
            limbs.push(limb);
        }
        else{
            let x_big_uint: BigUint = BigUint::from_str_radix(input_string, 16).unwrap();
            let limb: Fr = x_big_uint.into();
            limbs.push(limb);
        }
    }
    limbs
}



pub (crate) fn callparam_to_string(input: &ForeignCallParam<String>) -> Vec<&str> {
    match input {
        ForeignCallParam::Single(value) => vec![value.trim_start_matches('0')],
        ForeignCallParam::Array(values) => values.into_iter().map(|v| v.trim_start_matches('0')).collect(),
    }
}

pub (crate) fn get_u32_from_callparam(input: &ForeignCallParam<String>) -> u32 {
    let input_string = callparam_to_string(input)[0];
    u32::from_str_radix(input_string, 16).unwrap()
}

pub (crate) fn get_bool_from_callparam(input: &ForeignCallParam<String>) -> bool {
    let input_string = callparam_to_string(input)[0];
    let res = u32::from_str_radix(input_string, 16).unwrap(); 
    res == 1
}


impl  Params  {
    // this function takes the foreign call params and returns a Params struct
    pub fn from_foreign_call_params(inputs: &Vec<ForeignCallParam<String>>) -> Params {
        let has_multiplicative_inverse_fc = &inputs[0];
        let has_multiplicative_inverse = get_bool_from_callparam(&has_multiplicative_inverse_fc);
        let modulus_fc = &inputs[1];
        let modulus = gets_limbs(callparam_to_string(modulus_fc));
        let double_modulus_fc = &inputs[4];
        let double_modulus = gets_limbs(callparam_to_string(double_modulus_fc));
        let redc_param_fc = &inputs[5];
        let redc_param = gets_limbs(callparam_to_string(redc_param_fc));

        Params {
            has_multiplicative_inverse: has_multiplicative_inverse,
            modulus: modulus,
            double_modulus: double_modulus,
            redc_param: redc_param,
        }
    }
}

impl std::fmt::Debug for Params {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "Params {{ has_multiplicative_inverse: {:?}, modulus: {:?}, double_modulus: {:?}, redc_param: {:?}", self.has_multiplicative_inverse, self.modulus, self.double_modulus, self.redc_param)
    }
}