// This copyright notice relates to the `jsonrpsee` boilerplate that was used to kickstart this project:

// Copyright 2019-2021 Parity Technologies (UK) Ltd.
//
// Permission is hereby granted, free of charge, to any
// person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the
// Software without restriction, including without
// limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software
// is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice
// shall be included in all copies or substantial portions
// of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
// ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
// TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
// SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
// IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

mod foreign_call;
mod handlers;
mod ops;


use jsonrpsee::server::{RpcModule, Server};
use std::net::SocketAddr;
use tracing_subscriber::util::SubscriberInitExt;

use serde::Deserialize;
use serde_json::{json, Value};

use crate::foreign_call::ForeignCallParam;
use crate::handlers::{handle_get_sqrt, handle_get_sqrts, handle_is_zero, handle_add, handle_mul_with_quotient, handle_neg, handle_udiv_mod, handle_invmod, handle_pow, handle_div};

// SPIN UP THE SERVER
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let filter = tracing_subscriber::EnvFilter::try_from_default_env()?
        .add_directive("jsonrpsee[method_call{name = \"say_hello\"}]=trace".parse()?);
    tracing_subscriber::FmtSubscriber::builder()
        .with_env_filter(filter)
        .finish()
        .try_init()?;

    let _server_addr = run_server().await?;

    Ok(())
}

fn print_type<T>(_: &T) {
    println!("{:?}", std::any::type_name::<T>());
}

#[derive(Debug, Deserialize)]
struct RequestData {
    session_id: u64,
    function: String,
    inputs: Vec<ForeignCallParam<String>>,
    root_path: String,
    package_name: String,
}

#[derive(Debug, Deserialize)]
struct Requests(Vec<RequestData>); // Wrap it in a struct to handle the array

pub(crate) fn handle_unknown_function(_input: &RequestData) -> Value {
    println!("oops");
    json!(vec![String::from("oops")])
}

async fn run_server() -> anyhow::Result<SocketAddr> {
    let server = Server::builder()
        .build("127.0.0.1:3000".parse::<SocketAddr>()?)
        .await?;
    let mut module = RpcModule::new(());

    module.register_method("say_hello", |_, _, _| "hello, world")?;

    module.register_method("resolve_foreign_call", |params, _, _| {
        // println!("\n\nNEW REQUEST!!!");
        // print_type(&params);
        // println!("params{:?}", params);

        let response: Value = if let Some(json_string) = params.as_str() {
            // Deserialize the JSON string into the Requests struct:
            let requests: Requests =
                serde_json::from_str(&json_string).expect("Failed to parse JSON");

            let request = &requests.0[0];

            // println!("Request function{:?}", request.function);

            let result: Value = match request.function.as_str() {
                "get_sqrt" => handle_get_sqrt(&request.inputs), // the inputs to this are effectively a Vec<String>
                "get_sqrts" => handle_get_sqrts(&request.inputs), // the inputs to this are effectively a Vec<Vec<String>>
                "is_zero" => handle_is_zero(&request.inputs), // the inputs to this are effectively a Vec<String>
                "add" => handle_add(&request.inputs), // the inputs to this are effectively a Vec<String>
                "neg" => handle_neg(&request.inputs), // the inputs to this are effectively a Vec<String>
                "mul_with_quotient" => handle_mul_with_quotient(&request.inputs), // the inputs to this are effectively a Vec<String>
                "udiv_mod" => handle_udiv_mod(&request.inputs), // the inputs to this are effectively a Vec<String>
                "invmod" => handle_invmod(&request.inputs), // the inputs to this are effectively a Vec<String>
                "pow" => handle_pow(&request.inputs), // the inputs to this are effectively a Vec<String>
                "div" => handle_div(&request.inputs), // the inputs to this are effectively a Vec<String>
                _ => handle_unknown_function(&request),
            };

            result
        } else {
            println!("No parameters provided");
            json!(vec![String::from("Bad query")])
        };

        response
    })?;

    let addr = server.local_addr()?;
    let handle = server.start(module);

    println!("Server is running on 127.0.0.1:3000");

    // In this example we don't care about doing shutdown so let's it run forever.
    // You may use the `ServerHandle` to shut it down or manage it yourself.
    // tokio::spawn(handle.stopped());

    // Keep the server running until it's interrupted
    handle.stopped().await;

    Ok(addr)
}
