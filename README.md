API:
POST /api/register        public
POST /api/login           public
GET  /api/user-data       custom authorizer
POST /api/update-user     custom authorizer
POST /api/visit-counter   public

DynamoDB:
users              PK: email
user_checkin_data  PK: email
checkinappstats    PK: StatID

Lambda env:
loginFunction: JWT_SECRET
authorizerFunction: JWT_SECRET
userDataFunction: USER_DATA_TABLE
updateUserDataFunction: USER_DATA_TABLE
checkinAppVisitCounter: DYNAMODB_TABLE_NAME

Authorizer:
REST API TOKEN Authorizer
event.authorizationToken
returns policyDocument + context.email

Business Lambda:
event.requestContext.authorizer.email
