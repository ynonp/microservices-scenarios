# Serverless Leads Collection Micro Service

Today we're going to implement a server-less micro service to collect leads generated from a landing page.
While implementing the code you'll get a chance to experiment first hand with AWS interface and some of its services.

## Intro
AWS is a collection of services designed to help us build micro services oriented applications. For each task you can think of, there's an AWS service to handle it.

In today's example we will explore 3 services that together will allow us to build a lead collection service for an application:

1. API Gateway
2. Lambda
3. Dynamo DB

Using AWS, we will be able to scale up or down each service immediately and with no downtime. Services integrate with each other resulting in shorter code.

The architecture of our lead collection micro-service will be something like this:

  Internet (client)                           Triggers                      Saves Data In
 ---->           ---------> [API Gateway] -------->  ----> Lambda Function ----> -----------> Dynamo DB Table

A client (web browser or application) will access a public service called an API Gateway.
On AWS, API Gateway acts as a "router". We create some routes, connect them to handler functions and the gateway listens for incoming requests and calls the appropriate handler following each request.

We will write a handler using a service called "AWS Lambda". A lambda is a function that takes data (in our case from the API Gateway), and returns a result (in our case that'll be a JSON object). We will write our lambda using Node.JS but AWS Lambda supports a variety of languages including Java, Go, PowerShell, Node.js, C#, Python, and Ruby.

In order to store the leads we need a database, and that's the job of Dynamo DB. Dynamo DB is a distributed NoSQL database that stores "objects". Each object has a "key" fields and other fields as you see fit. DynamoDB can be accessed from lambdas running on AWS or from any other code.

Today we won't talk about authorization and permission, however be aware that AWS has a very rich system of permissions that provides access control and even identity management.

## Setup

1. Before you can run the examples below you'll need to configure AWS CLI. Please follow the instructions here to install:
[https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html).

2. All the commands in this tutorial use region "eu-west-3". I suggest when configuring AWS to also select this region. In AWS talk, each region has its own services so you need to stay persistent.

3. For this tutorial you will be given a userid/password/access token from the instructor. Use them when you configure AWS.

## Creating The Micro Services

** BEFORE YOU BEGIN **

AWS keeps items by name for a given region. In this tutorial I use generic names such as "Leads", but when you run the code you'll need to personalize the names by adding your room number.

So when you see --table-name Leads; You actually need to write "--table-name Leads1" (or wahtever room number you're in)

Otherwise names will collide with other participant's work.

The keys that need to change are:

1. table-name
2. policy-name
3. role-name
4. policy-arn (to match the policy name you selected)
5. function-name
6. API Gateway name
7. Log group name

** NOW CONTINUE **

Start by creating a dynamodb table

```
$ aws dynamodb create-table --table-name Leads --key-schema AttributeName=id,KeyType=HASH --attribute-definitions AttributeName=id,AttributeType=S --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

Then login to AWS management console to see the new table you just created:
https://eu-west-3.console.aws.amazon.com/dynamodb/home?region=eu-west-3#tables:


Create a lambda policy:

```
$ aws iam create-policy --policy-name Leads --policy-document file://policy.json
```

Then go to the Policy list page and use the filter to find your newly created policy:
https://console.aws.amazon.com/iam/home?region=eu-west-3#/policies

Create an execution role:

```
$ aws iam create-role --role-name leads-lambda-ex --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
```

And connect the role to the policy:

```
$ aws iam attach-role-policy --role-name leads-lambda-ex --policy-arn arn:aws:iam::219781153561:policy/Leads
```

---------------

Create the lamdba function from the starter code:

```
$ zip function.zip index.js
$ aws lambda create-function --function-name leads \
    --zip-file fileb://function.zip --handler index.handler --runtime nodejs12.x \
    --role arn:aws:iam::219781153561:role/leads-lambda-ex

```

Later when you need to update the function code you can use:

```
$ aws lambda update-function-code --function-name leads --zip-file fileb://function.zip
```


Login to AWS GUI to verify you have your lambda in place:
https://eu-west-3.console.aws.amazon.com/lambda/home?region=eu-west-3#/functions

## Write Incoming Leads to Dynamo DB Table
To start writing real leads to our AWS table we need to set up an API gateway. An API Gateway recevies HTTP requests and can trigger lambda functions (or do a bunch of other stuff) in response.

Create an HTTP API Gateway:

```
$ aws apigatewayv2 create-api --name leads-api --protocol-type HTTP
```

Write down the API ID that will be printed on screen after running the last command. If you missed it you can always use:

```
$ aws apigatewayv2 get-apis
```

To see all the APIs you created.

An API Gateway connects to a lambda function via an Integration. Replace the variable `API_ID` with the value you got back when creating the API. We need to create one:

MAKE SURE TO CHANGE arn TO MATCH YOUR LAMBDA FUNCTION

```
$ aws apigatewayv2 create-integration --api-id ${API_ID} --integration-type AWS_PROXY --integration-uri arn:aws:lambda:eu-west-3:219781153561:function:leads --payload-format-version "2.0"

```

Write down the integration id.

If you miss it you can always check on the management console:
https://eu-west-3.console.aws.amazon.com/apigateway/main/develop/integrations/list?api=qzuz9mvb28&region=eu-west-3


An API also has a "stage", that is the environment in which this API is active. Possible stage values are development, production, staging. We will use a stage called $default which is what you get when you don't specify a stage. We still need to create it though:

```
$ aws apigatewayv2 create-stage --api-id ${API_ID}  --stage-name '$default' --auto-deploy
```

Finally create a route to trigger the integration on our default stage:

```
$ aws apigatewayv2 create-route --api-id ${API_ID}  --target "integrations/${INTEGRATION_ID}" --route-key 'GET /items'
$ aws apigatewayv2 create-route --api-id ${API_ID}  --target "integrations/${INTEGRATION_ID}" --route-key 'PUT /items'
```

------------
Before we can use the function we still need two additions:

1. Our API Gateway doesn't yet have the permissions to invoke the lambda. We'll need to fix that.

2. Our API Gateway doesn't create logs. It'll be much easier to debug if we can see what's going on.

Start with the logs. In AWS a service called CloudWatch takes care of the logging. To interact with it we create a new Log Group:

```
$ aws logs create-log-group --log-group-name leads-http-logs
```

And then ask our API to write logs to this newly created log group:

```
$ aws apigatewayv2 update-stage --api-id ${API_ID} \
    --stage-name '$default' \
    --access-log-settings '{"DestinationArn": "arn:aws:logs:eu-west-3:219781153561:log-group:leads-http-logs", "Format": "$context.identity.sourceIp - - [$context.requestTime] \"$context.routeKey $context.protocol\" - $context.integrationErrorMessage - $context.status $context.responseLength $context.requestId"}'

```

Note you can control the format of the log as you see fit.


The second challenge is to allow our API to invoke the function we created. Use the following command to grant pemissions:

```
$ aws lambda add-permission --function-name leads \
    --statement-id apigateway-get --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:eu-west-3:219781153561:${API_ID}/*/items"

```

Now let's see what we've built using AWS GUI:

1. In the lambda console you can see your function with its trigger - the API Gateway:
https://eu-west-3.console.aws.amazon.com/lambda/home?region=eu-west-3#/functions/

2. In the API Gateway console you can see you API gateway, all defined routes and integrations:
https://eu-west-3.console.aws.amazon.com/apigateway/main/apis?region=eu-west-3

3. And in dynamodb console you can see your Leads table:
https://eu-west-3.console.aws.amazon.com/dynamodb/home?region=eu-west-3#



To check everything works you can use the following CURL call to add a new lead:

```
$ curl -v -H "Content-Type: application/json" -X PUT -d '{"name": "ynon", "email": "ynon@tocode.co.il"}' https://chtpwn5jm6.execute-api.eu-west-3.amazonaws.com/items
```

And this url shows ALL the leads in the DB:
```
https://${API_ID}.execute-api.eu-west-3.amazonaws.com/items
```

## Can You Find The Bug?
If you go to check the contents of your dynamodb table you'll find that it's empty. Nevertheless the code seems to work, however something is fishy.

Can you figure out what's going on and fix it?



## Discussion

1. What are the advantages of using AWS lambda ? What are the disadvantages ?

2. In the example we used a single Lambda function to handle two routes. What would be the advantages of using two separate functions (one for GET and one for PUT) ? What would be the disadvantages?

3. In the example we used the email as the ID field. What would happen if a person with the same email would subscribe using a different name? Can you think of a better ID, that would allow multiple emails?

4. In our example we didn't use any access restriction mechanism and all data is visible to everyone. This will not work in a real world scenario. What requirements do you think we need for this micro service to function in the real world?

5. Imagine a main app that has multiple users, each user can create landing pages and collect leads. How would you design the micro service that captures the leads?
  - Would you use a dynamodb table per user, or keep all the leads in one big table?
  - What will be the key?
  - What fields will be saved?
  - How is permissions and access restriction going to work?



## Extra Tasks

1. Add a `console.log` call to the function code. Use CloudWatch GUI to read your log message (can you find it? understand it?)

2. Modify the route from `/items` to `/leads` for both GET and PUT calls. What were all the places you had to modify?

3. Create a cool landing page to replace the curl call to add new leads
