---
name: api-design-skill
description: Design and document APIs — REST conventions, OpenAPI/Swagger spec generation, GraphQL schema patterns, API versioning, pagination, rate limiting, error response formats, and HATEOAS
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: api-design
  languages: [typescript, python, openapi, graphql]
---

## What I do

I help you design, document, and implement well-structured APIs:

1. **REST Design**: Resource naming, HTTP methods, status codes, URL conventions
2. **OpenAPI/Swagger**: Generate and maintain API specifications
3. **GraphQL**: Schema design, resolver patterns, query optimization
4. **Versioning**: URL, header, and content negotiation strategies
5. **Pagination**: Cursor-based, offset-based, and relay-style patterns
6. **Error Handling**: Consistent error response formats across API types
7. **Rate Limiting**: Implementation patterns and header conventions

## When to use me

Use this skill when:
- Designing a new REST or GraphQL API
- Creating OpenAPI/Swagger documentation
- Implementing API versioning strategy
- Designing pagination for large data sets
- Standardizing error response formats
- Planning rate limiting and throttling
- Reviewing existing API design for improvements
- Converting REST endpoints to GraphQL (or vice versa)

## Related Skills

- **clean-architecture-skill**: Layer boundaries and dependency rules for API implementations
- **design-patterns-skill**: Structural patterns (Repository, Facade) useful in API design
- **authentication-authorization-skill**: Auth middleware and token handling for APIs
- **performance-optimization-skill**: Query optimization and caching for API endpoints

---

## Step 1: REST Design Conventions

### Resource Naming

```
GET    /api/v1/users              # Collection
GET    /api/v1/users/123          # Single resource
POST   /api/v1/users              # Create resource
PATCH  /api/v1/users/123          # Partial update
PUT    /api/v1/users/123          # Full replacement
DELETE /api/v1/users/123          # Delete resource

GET    /api/v1/users/123/orders   # Sub-collection
POST   /api/v1/users/123/orders   # Create sub-resource

GET    /api/v1/orders?status=active&sort=-created_at&page=2
```

### Rules

| Rule | Convention | Example |
|------|-----------|---------|
| Use nouns, not verbs | `/users` not `/getUsers` | `GET /users` |
| Plural for collections | `/users` not `/user` | `GET /users/123` |
| Nested for relationships | Max 2 levels | `/users/123/orders` |
| Query params for filtering | Not in path | `?status=active` |
| Kebab-case for URLs | Not camelCase | `/user-profiles` |
| Consistent trailing slashes | Pick one convention | No trailing slash |

### HTTP Status Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful GET, PATCH, PUT |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 301 | Moved Permanently | Resource relocated |
| 304 | Not Modified | Cache hit |
| 400 | Bad Request | Validation failure |
| 401 | Unauthorized | Missing/invalid auth |
| 403 | Forbidden | Auth but no permission |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate or state conflict |
| 422 | Unprocessable Entity | Semantic validation failure |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unhandled server error |

## Step 2: Error Response Format

### Standard Error Envelope

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request body contains invalid fields",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address",
        "value": "not-an-email"
      }
    ],
    "requestId": "req_abc123",
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

### FastAPI Error Handler

```python
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel

class ErrorDetail(BaseModel):
    field: str
    message: str
    value: str | None = None

class ErrorResponse(BaseModel):
    error: dict

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": exc.detail if isinstance(exc.detail, str) else "ERROR",
                "message": str(exc.detail),
                "requestId": getattr(request.state, "request_id", "unknown"),
                "timestamp": datetime.utcnow().isoformat() + "Z",
            }
        },
    )
```

## Step 3: Pagination

### Cursor-Based (Recommended for large datasets)

```json
{
  "data": [...],
  "pagination": {
    "cursor": "eyJpZCI6MTAwfQ==",
    "hasMore": true,
    "nextUrl": "/api/v1/users?cursor=eyJpZCI6MTAwfQ==&limit=20"
  }
}
```

```python
from fastapi import Query

@app.get("/api/v1/users")
async def list_users(
    cursor: str | None = Query(None),
    limit: int = Query(20, ge=1, le=100),
):
    query = select(User)
    if cursor:
        decoded = base64.b64decode(cursor).decode()
        last_id = json.loads(decoded)["id"]
        query = query.where(User.id > last_id)
    users = await session.execute(query.limit(limit + 1))
    results = users.scalars().all()
    has_more = len(results) > limit
    data = results[:limit]
    next_cursor = None
    if has_more:
        next_cursor = base64.b64encode(json.dumps({"id": data[-1].id}).encode()).decode()
    return {"data": data, "pagination": {"cursor": next_cursor, "hasMore": has_more}}
```

### Offset-Based (For small, static datasets)

```json
{
  "data": [...],
  "pagination": {
    "page": 2,
    "perPage": 20,
    "total": 156,
    "totalPages": 8,
    "nextUrl": "/api/v1/users?page=3&perPage=20",
    "prevUrl": "/api/v1/users?page=1&perPage=20"
  }
}
```

## Step 4: OpenAPI Specification

### FastAPI (Auto-generated)

```python
from fastapi import FastAPI
from pydantic import BaseModel

class UserCreate(BaseModel):
    email: str
    name: str
    age: int | None = None

class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    created_at: str

app = FastAPI(
    title="User Service API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

@app.post(
    "/api/v1/users",
    response_model=UserResponse,
    status_code=201,
    summary="Create a new user",
    responses={400: {"description": "Validation error"}, 409: {"description": "Email already exists"}},
)
async def create_user(body: UserCreate):
    """Create a new user with the provided details."""
    ...
```

### Next.js (Manual OpenAPI)

```typescript
import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi'

const app = new OpenAPIHono()

const createUserRoute = createRoute({
  method: 'post',
  path: '/api/v1/users',
  request: {
    body: {
      content: {
        'application/json': {
          schema: z.object({
            email: z.string().email(),
            name: z.string().min(1).max(100),
          }),
        },
      },
    },
  },
  responses: {
    201: { content: { 'application/json': { schema: UserResponseSchema } }, description: 'User created' },
    400: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Validation error' },
  },
})
```

## Step 5: GraphQL Schema Design

### Schema Conventions

```graphql
type Query {
  user(id: ID!): User
  users(filter: UserFilter, pagination: PaginationInput): UserConnection!
}

type Mutation {
  createUser(input: CreateUserInput!): UserResult!
  updateUser(id: ID!, input: UpdateUserInput!): UserResult!
  deleteUser(id: ID!): DeleteResult!
}

type User {
  id: ID!
  email: String!
  name: String!
  createdAt: DateTime!
  orders(filter: OrderFilter): OrderConnection!
}

type UserConnection {
  edges: [UserEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type UserEdge {
  node: User!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

union UserResult = User | ValidationError | NotFoundError
```

### N+1 Prevention

```python
import strawberry
from strawberry.dataloader import DataLoader

@strawberry.type
class User:
    id: strawberry.ID
    name: str

    @strawberry.field
    async def orders(self, loader=Info.context.order_loader) -> list[Order]:
        return await loader.load(self.id)

def setup_loaders(db):
    async def load_orders(user_ids):
        orders = await db.execute(
            select(Order).where(Order.user_id.in_(user_ids))
        )
        grouped = defaultdict(list)
        for order in orders:
            grouped[order.user_id].append(order)
        return [grouped[uid] for uid in user_ids]
    return DataLoader(load_fn=load_orders)
```

## Step 5.5: Multi-Source Response Schema Consistency

### `multi-source-response-schema-drift`

When an API response is assembled from multiple sources (e.g., a fast DB path and a slower Temporal workflow path), adding a field to one path without updating all others causes invisible data loss. Consumers see the field present in some responses and absent in others with no error.

```typescript
// PROBLEM: New `summary` field only added to the DB fast path
async function getReport(id: string) {
  const cached = await cache.get(id)
  if (cached) {
    // Fast path: DB/cached response — has the new `summary` field
    return { ...cached, summary: cached.summary }
  }

  // Slow path: Temporal workflow result — missing `summary`
  const workflowResult = await temporalClient.result(workflowId)
  return workflowResult // no `summary` field
}

// FIX: Validate response against a shared schema before returning
import { z } from "zod"

const ReportResponseSchema = z.object({
  id: z.string(),
  title: z.string(),
  status: z.enum(["draft", "submitted", "approved"]),
  summary: z.string().nullable(),
  createdAt: z.string().datetime(),
})

const ReportResponseSchemaWithoutSummary = ReportResponseSchema.partial({ summary: undefined })

function normalizeReport(data: unknown): Report {
  const result = ReportResponseSchemaWithoutSummary.parse(data)
  return { ...result, summary: result.summary ?? null }
}

async function getReport(id: string) {
  const cached = await cache.get(id)
  if (cached) return normalizeReport(cached)

  const workflowResult = await temporalClient.result(workflowId)
  return normalizeReport(workflowResult)
}
```

**Rule**: When adding fields to a multi-source response, update all code paths that produce that response and validate output against a shared schema.

---

## Step 6: API Versioning Strategies

| Strategy | URL Example | Pros | Cons |
|----------|-------------|------|------|
| URL path | `/api/v1/users` | Simple, explicit | URL changes |
| Header | `Accept: application/vnd.api.v1+json` | Clean URLs | Hidden from casual use |
| Query param | `/api/users?version=1` | Simple | Not RESTful |
| Content negotiation | `Accept: application/vnd.api+json; version=1` | Most RESTful | Complex |

**Recommended**: URL path versioning (`/api/v1/`) — most explicit and easiest for consumers.

## Step 5.6: Async Polling API Pattern

### `async-api-blocking-poll-pattern`

Model long-running operations with a submit→poll→download lifecycle instead of blocking the HTTP connection. Return a status endpoint the client can poll until the work is complete.

```text
POST   /api/v1/reports           → 202 Accepted (returns jobId)
GET    /api/v1/reports/{jobId}    → 200 { status: "processing"|"completed"|"failed", resultUrl? }
GET    /api/v1/reports/{jobId}/download → 200 (file download, only when status=completed)
```

```python
@app.post("/api/v1/reports", status_code=202)
async def submit_report(request: ReportRequest):
    job_id = str(uuid.uuid4())
    await job_queue.enqueue("generate_report", job_id=job_id, params=request.model_dump())
    return {"jobId": job_id, "status": "queued", "pollUrl": f"/api/v1/reports/{job_id}"}

@app.get("/api/v1/reports/{job_id}")
async def get_report_status(job_id: str):
    job = await job_store.get(job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    response = {"jobId": job_id, "status": job.status, "createdAt": job.created_at}
    if job.status == "completed":
        response["downloadUrl"] = f"/api/v1/reports/{job_id}/download"
    elif job.status == "failed":
        response["error"] = job.error_message
    return response

@app.get("/api/v1/reports/{job_id}/download")
async def download_report(job_id: str):
    job = await job_store.get(job_id)
    if not job or job.status != "completed":
        raise HTTPException(status_code=409, detail="Report not ready")
    return FileResponse(job.result_path, media_type="application/pdf", filename=f"report-{job_id}.pdf")
```

**Status codes**: 202 (accepted), 200 (polling result), 404 (unknown job), 409 (not ready yet), 410 (expired).

---

## Step 7: Rate Limiting

### Implementation

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/api/v1/users")
@limiter.limit("10/minute")
async def create_user(request: Request, body: UserCreate):
    ...
```

### Response Headers

```http
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1705312200
Retry-After: 30
```

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 30
Content-Type: application/json

{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit of 100 requests per minute exceeded. Retry after 30 seconds.",
    "retryAfter": 30
  }
}
```
