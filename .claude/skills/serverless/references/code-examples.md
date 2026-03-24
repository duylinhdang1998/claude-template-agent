# Serverless - Code Examples

## Table of Contents
1. [Lambda Functions](#lambda-functions)
2. [API Gateway + Lambda](#api-gateway--lambda)
3. [DynamoDB Integration](#dynamodb-integration)
4. [AWS SAM](#aws-sam)
5. [AWS CDK](#aws-cdk)
6. [Event-Driven Patterns](#event-driven-patterns)
7. [Best Practices](#best-practices)
8. [Cost Optimization](#cost-optimization)

---

## Lambda Functions

### Basic Handler
```typescript
// lambda/hello.ts
export const handler = async (event: any) => {
  console.log('Event:', JSON.stringify(event))

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      message: 'Hello from Lambda!',
      timestamp: new Date().toISOString()
    })
  }
}
```

### Deploy with AWS CLI
```bash
# Package function
zip function.zip hello.js

# Create function
aws lambda create-function \
  --function-name HelloFunction \
  --runtime nodejs20.x \
  --role arn:aws:iam::123456789:role/lambda-role \
  --handler hello.handler \
  --zip-file fileb://function.zip

# Invoke function
aws lambda invoke \
  --function-name HelloFunction \
  response.json
```

---

## API Gateway + Lambda

```typescript
// lambda/api/users.ts
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda'

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  const { httpMethod, pathParameters, body } = event

  try {
    switch (httpMethod) {
      case 'GET':
        if (pathParameters?.id) {
          // GET /users/{id}
          const user = await getUser(pathParameters.id)
          return respond(200, user)
        }
        // GET /users
        const users = await getUsers()
        return respond(200, users)

      case 'POST':
        // POST /users
        const data = JSON.parse(body || '{}')
        const newUser = await createUser(data)
        return respond(201, newUser)

      case 'PUT':
        // PUT /users/{id}
        const updateData = JSON.parse(body || '{}')
        const updated = await updateUser(pathParameters!.id, updateData)
        return respond(200, updated)

      case 'DELETE':
        // DELETE /users/{id}
        await deleteUser(pathParameters!.id)
        return respond(204, {})

      default:
        return respond(405, { error: 'Method not allowed' })
    }
  } catch (error) {
    console.error(error)
    return respond(500, { error: 'Internal server error' })
  }
}

function respond(statusCode: number, data: any): APIGatewayProxyResult {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify(data)
  }
}
```

---

## DynamoDB Integration

```typescript
import { DynamoDBClient } from '@aws-sdk/client-dynamodb'
import { DynamoDBDocumentClient, GetCommand, PutCommand, ScanCommand } from '@aws-sdk/lib-dynamodb'

const client = new DynamoDBClient({})
const docClient = DynamoDBDocumentClient.from(client)

const TABLE_NAME = process.env.TABLE_NAME!

async function getUser(id: string) {
  const result = await docClient.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { id }
    })
  )
  return result.Item
}

async function createUser(data: any) {
  const user = {
    id: crypto.randomUUID(),
    ...data,
    createdAt: new Date().toISOString()
  }

  await docClient.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: user
    })
  )

  return user
}

async function getUsers() {
  const result = await docClient.send(
    new ScanCommand({
      TableName: TABLE_NAME,
      Limit: 100
    })
  )
  return result.Items
}
```

---

## AWS SAM

```yaml
# template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Globals:
  Function:
    Runtime: nodejs20.x
    Timeout: 30
    Environment:
      Variables:
        TABLE_NAME: !Ref UsersTable

Resources:
  # API Gateway
  ApiGateway:
    Type: AWS::Serverless::Api
    Properties:
      StageName: prod
      Cors:
        AllowOrigin: "'*'"
        AllowHeaders: "'*'"

  # Lambda Functions
  GetUsersFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: dist/
      Handler: users.handler
      Events:
        GetUsers:
          Type: Api
          Properties:
            RestApiId: !Ref ApiGateway
            Path: /users
            Method: GET
        GetUser:
          Type: Api
          Properties:
            RestApiId: !Ref ApiGateway
            Path: /users/{id}
            Method: GET
      Policies:
        - DynamoDBCrudPolicy:
            TableName: !Ref UsersTable

  # DynamoDB Table
  UsersTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: users
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH

Outputs:
  ApiUrl:
    Value: !Sub 'https://${ApiGateway}.execute-api.${AWS::Region}.amazonaws.com/prod'
```

### Deploy
```bash
# Build
sam build

# Deploy
sam deploy --guided

# Test locally
sam local start-api
```

---

## AWS CDK

```typescript
// lib/stack.ts
import * as cdk from 'aws-cdk-lib'
import * as lambda from 'aws-cdk-lib/aws-lambda'
import * as apigateway from 'aws-cdk-lib/aws-apigateway'
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb'

export class ServerlessStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string) {
    super(scope, id)

    // DynamoDB Table
    const table = new dynamodb.Table(this, 'UsersTable', {
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY
    })

    // Lambda Function
    const handler = new lambda.Function(this, 'UsersHandler', {
      runtime: lambda.Runtime.NODEJS_20_X,
      code: lambda.Code.fromAsset('dist'),
      handler: 'users.handler',
      environment: {
        TABLE_NAME: table.tableName
      }
    })

    // Grant permissions
    table.grantReadWriteData(handler)

    // API Gateway
    const api = new apigateway.RestApi(this, 'UsersApi', {
      restApiName: 'Users Service',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS
      }
    })

    const users = api.root.addResource('users')
    users.addMethod('GET', new apigateway.LambdaIntegration(handler))
    users.addMethod('POST', new apigateway.LambdaIntegration(handler))

    const user = users.addResource('{id}')
    user.addMethod('GET', new apigateway.LambdaIntegration(handler))
    user.addMethod('PUT', new apigateway.LambdaIntegration(handler))
    user.addMethod('DELETE', new apigateway.LambdaIntegration(handler))

    // Output API URL
    new cdk.CfnOutput(this, 'ApiUrl', {
      value: api.url
    })
  }
}
```

### Deploy
```bash
npm run build
cdk bootstrap  # First time only
cdk deploy
```

---

## Event-Driven Patterns

### S3 Event Processing
```typescript
// lambda/s3-processor.ts
import { S3Event } from 'aws-lambda'
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3'

const s3 = new S3Client({})

export const handler = async (event: S3Event) => {
  for (const record of event.Records) {
    const bucket = record.s3.bucket.name
    const key = record.s3.object.key

    console.log(`Processing ${bucket}/${key}`)

    // Get file from S3
    const response = await s3.send(
      new GetObjectCommand({ Bucket: bucket, Key: key })
    )

    const content = await response.Body.transformToString()

    // Process file (e.g., resize image, extract text, etc.)
    await processFile(content)
  }
}
```

### Trigger Configuration (CDK)
```typescript
import * as s3 from 'aws-cdk-lib/aws-s3'
import * as s3n from 'aws-cdk-lib/aws-s3-notifications'

const bucket = new s3.Bucket(this, 'UploadBucket')

bucket.addEventNotification(
  s3.EventType.OBJECT_CREATED,
  new s3n.LambdaDestination(processorFunction),
  { prefix: 'uploads/', suffix: '.jpg' }
)
```

### Scheduled Tasks (Cron Jobs)
```typescript
// lambda/daily-report.ts
export const handler = async () => {
  console.log('Running daily report...')

  // Generate report
  const report = await generateDailyReport()

  // Send email
  await sendEmail({
    to: 'admin@example.com',
    subject: 'Daily Report',
    body: report
  })

  return { success: true }
}
```

### Schedule (CDK)
```typescript
import * as events from 'aws-cdk-lib/aws-events'
import * as targets from 'aws-cdk-lib/aws-events-targets'

// Run every day at 9 AM UTC
new events.Rule(this, 'DailyReport', {
  schedule: events.Schedule.cron({ hour: '9', minute: '0' }),
  targets: [new targets.LambdaFunction(reportFunction)]
})
```

### SQS Queue Processing
```typescript
// lambda/queue-processor.ts
import { SQSEvent } from 'aws-lambda'

export const handler = async (event: SQSEvent) => {
  for (const record of event.Records) {
    const message = JSON.parse(record.body)
    console.log('Processing:', message)

    try {
      await processMessage(message)

      // Message will be automatically deleted if no error
    } catch (error) {
      console.error('Processing failed:', error)
      // Message will return to queue (or go to DLQ if max retries exceeded)
      throw error
    }
  }
}
```

### Queue Setup (CDK)
```typescript
import * as sqs from 'aws-cdk-lib/aws-sqs'
import * as lambdaEventSources from 'aws-cdk-lib/aws-lambda-event-sources'

const queue = new sqs.Queue(this, 'ProcessingQueue', {
  visibilityTimeout: cdk.Duration.seconds(300),
  retentionPeriod: cdk.Duration.days(7),
  deadLetterQueue: {
    queue: new sqs.Queue(this, 'DLQ'),
    maxReceiveCount: 3
  }
})

processorFunction.addEventSource(
  new lambdaEventSources.SqsEventSource(queue, {
    batchSize: 10
  })
)
```

### Authentication with Cognito
```typescript
// API Gateway Authorizer
import { APIGatewayTokenAuthorizerEvent } from 'aws-lambda'
import jwt from 'jsonwebtoken'

export const handler = async (event: APIGatewayTokenAuthorizerEvent) => {
  const token = event.authorizationToken.replace('Bearer ', '')

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!)

    return {
      principalId: decoded.sub,
      policyDocument: {
        Version: '2012-10-17',
        Statement: [
          {
            Action: 'execute-api:Invoke',
            Effect: 'Allow',
            Resource: event.methodArn
          }
        ]
      },
      context: {
        userId: decoded.sub,
        email: decoded.email
      }
    }
  } catch (error) {
    throw new Error('Unauthorized')
  }
}
```

---

## Best Practices

### Cold Start Optimization
```typescript
// ❌ Bad: Initialize inside handler (cold start every time)
export const handler = async () => {
  const db = new DynamoDBClient({})
  // ...
}

// ✅ Good: Initialize outside handler (reuse across invocations)
const db = new DynamoDBClient({})

export const handler = async () => {
  // Use db
}
```

### Environment Variables
```typescript
// Load config once
const config = {
  tableName: process.env.TABLE_NAME!,
  region: process.env.AWS_REGION!,
  stage: process.env.STAGE || 'dev'
}

export const handler = async () => {
  console.log(`Running in ${config.stage}`)
  // Use config
}
```

### Error Handling
```typescript
export const handler = async (event: any) => {
  try {
    // Main logic
    const result = await processEvent(event)
    return { statusCode: 200, body: JSON.stringify(result) }
  } catch (error) {
    console.error('Error:', error)

    // Log to CloudWatch
    if (error instanceof ValidationError) {
      return { statusCode: 400, body: JSON.stringify({ error: error.message }) }
    }

    return { statusCode: 500, body: JSON.stringify({ error: 'Internal error' }) }
  }
}
```

### Logging & Monitoring
```typescript
export const handler = async (event: any, context: any) => {
  console.log('Request ID:', context.requestId)
  console.log('Event:', JSON.stringify(event))

  const startTime = Date.now()

  try {
    const result = await processEvent(event)

    const duration = Date.now() - startTime
    console.log(`Success in ${duration}ms`)

    return result
  } catch (error) {
    const duration = Date.now() - startTime
    console.error(`Failed in ${duration}ms:`, error)
    throw error
  }
}
```

### Lambda Layers (Shared Dependencies)
```bash
# Create layer
mkdir -p layer/nodejs/node_modules
cd layer/nodejs
npm install aws-sdk lodash

# Package
cd ..
zip -r layer.zip nodejs/

# Create layer
aws lambda publish-layer-version \
  --layer-name shared-dependencies \
  --zip-file fileb://layer.zip \
  --compatible-runtimes nodejs20.x
```

---

## Cost Optimization

### Right-Size Memory
```typescript
// Test different memory sizes (128MB to 10GB)
// More memory = faster CPU, but higher cost
// Find sweet spot where execution time * cost is minimized

// Example: 512MB @ 100ms might be cheaper than 128MB @ 400ms
```

### Use Reserved Concurrency Wisely
```typescript
// Only for critical functions with consistent load
// Prevents cold starts but reserves capacity (costs even when idle)
```

### Minimize Package Size
```bash
# Use tree-shaking
npm install --production

# Use esbuild for bundling
esbuild src/index.ts --bundle --platform=node --target=node20 --outfile=dist/index.js
```
