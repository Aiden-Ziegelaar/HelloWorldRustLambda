use lambda_http::{run, service_fn, Body, Error, Request, RequestExt, Response};

/// This is the main body for the function.
/// Write your code inside it.
/// There are some code example in the following URLs:
/// - https://github.com/awslabs/aws-lambda-rust-runtime/tree/main/examples
async fn function_handler(event: Request, client: &aws_sdk_secretsmanager::Client) -> Result<Response<Body>, Error> {
    // Extract some useful information from the request
    let who = event
        .query_string_parameters_ref()
        .and_then(|params| params.first("name"))
        .unwrap_or("world");

    let random_string = client.get_random_password().send().await?.random_password;

    let message = format!("Hello {who}, this is an AWS Lambda HTTP request, your random value is: {random_string}", who=who, random_string=random_string.unwrap_or_default());

    // Return something that implements IntoResponse.
    // It will be serialized to the right response event automatically by the runtime
    let resp = Response::builder()
        .status(200)
        .header("content-type", "text/html")
        .body(message.into())
        .map_err(Box::new)?;
    Ok(resp)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        // disable printing the name of the module in every log line.
        .with_target(false)
        // disabling time is handy because CloudWatch will add the ingestion time.
        .without_time()
        .init();

    let sdk_config = aws_config::from_env().load().await;
    let secrets_manager = aws_sdk_secretsmanager::Client::new(&sdk_config);

    run(service_fn(|event| function_handler(event, &secrets_manager))).await
}
