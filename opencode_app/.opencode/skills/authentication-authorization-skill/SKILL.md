---
name: authentication-authorization-skill
description: Implement authentication and authorization patterns — OAuth2/OIDC flows, JWT best practices, session management, RBAC/ABAC, NextAuth/Auth.js, Passport.js, password hashing, and CSRF protection
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: authentication
  languages: [typescript, python]
---

## What I do

I help you implement secure authentication and authorization systems:

1. **OAuth2/OIDC**: Authorization code, client credentials, PKCE flows
2. **JWT**: Token creation, validation, rotation, and best practices
3. **Session Management**: Secure session handling and storage
4. **RBAC/ABAC**: Role-based and attribute-based access control
5. **Framework Integration**: NextAuth/Auth.js, Passport.js, FastAPI security
6. **Password Security**: Hashing, salting, and password policies
7. **CSRF Protection**: Token-based and same-site cookie patterns

## When to use me

Use this skill when:
- Implementing login/signup flows
- Setting up OAuth2 social login (Google, GitHub, etc.)
- Designing role-based access control
- Configuring JWT token management
- Integrating NextAuth/Auth.js or Passport.js
- Implementing API authentication middleware
- Setting up password hashing and verification
- Adding CSRF protection to forms
- Implementing multi-factor authentication

## Related Skills

- **security-audit-skill**: Handles security *auditing* and vulnerability scanning. This skill handles auth *implementation*. CSRF here focuses on implementation patterns; security-audit focuses on detecting CSRF vulnerabilities.
- **api-design-skill**: API endpoint design. This skill handles authentication middleware for those endpoints.
- **nextjs-standard-setup-skill**: Project scaffolding that may include auth setup.

---

## Step 1: OAuth2/OIDC Flows

### Flow Selection

| Flow | Use Case | Client Type |
|------|----------|-------------|
| Authorization Code + PKCE | SPAs, mobile apps | Public |
| Authorization Code | Server-side web apps | Confidential |
| Client Credentials | Service-to-service | Confidential |
| Device Code | CLI tools, IoT | Public |

### Authorization Code + PKCE (Next.js)

```typescript
import NextAuth from "next-auth"
import Google from "next-auth/providers/google"

export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    }),
  ],
  pages: {
    signIn: "/login",
    error: "/login",
  },
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id
        token.role = user.role
      }
      return token
    },
    async session({ session, token }) {
      session.user.id = token.id
      session.user.role = token.role
      return session
    },
  },
  session: {
    strategy: "jwt",
    maxAge: 24 * 60 * 60,
  },
})
```

### Client Credentials (Python/FastAPI)

```python
from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")

async def get_service_token(token: str = Depends(oauth2_scheme)):
    payload = verify_token(token)
    if payload.get("type") != "service":
        raise HTTPException(status_code=403, detail="Service token required")
    return payload
```

---

## Step 2: JWT Best Practices

### Token Structure

```json
{
  "sub": "user_abc123",
  "email": "user@example.com",
  "role": "admin",
  "type": "access",
  "iat": 1705312200,
  "exp": 1705315800,
  "jti": "unique-token-id",
  "iss": "my-api",
  "aud": "my-api-users"
}
```

### Token Creation (Python)

```python
from datetime import datetime, timedelta, timezone
from jose import jwt

def create_access_token(subject: str, role: str, expires_delta: timedelta | None = None):
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=15))
    return jwt.encode(
        {
            "sub": subject,
            "role": role,
            "type": "access",
            "exp": expire,
            "iat": datetime.now(timezone.utc),
            "jti": str(uuid4()),
            "iss": settings.APP_NAME,
            "aud": "my-api-users",
        },
        settings.SECRET_KEY,
        algorithm="HS256",
    )

def create_refresh_token(subject: str):
    expire = datetime.now(timezone.utc) + timedelta(days=7)
    return jwt.encode(
        {
            "sub": subject,
            "type": "refresh",
            "exp": expire,
            "jti": str(uuid4()),
        },
        settings.SECRET_KEY,
        algorithm="HS256",
    )
```

### Token Validation

```python
from jose import JWTError, jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=["HS256"],
            audience="my-api-users",
            issuer=settings.APP_NAME,
        )
        if payload.get("type") != "access":
            raise HTTPException(401, "Invalid token type")
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(401, "Invalid token")
    except JWTError:
        raise HTTPException(401, "Token validation failed")
    return await get_user(user_id)
```

### Token Rotation

```python
@router.post("/auth/refresh")
async def refresh_token(refresh_token: str):
    payload = verify_token(refresh_token, token_type="refresh")

    if await is_token_revoked(payload["jti"]):
        raise HTTPException(401, "Token revoked")

    await revoke_token(payload["jti"])

    access = create_access_token(payload["sub"], role=payload.get("role", "user"))
    refresh = create_refresh_token(payload["sub"])

    return {"access_token": access, "refresh_token": refresh, "token_type": "bearer"}
```

### Best Practices

| Practice | Why |
|----------|-----|
| Short-lived access tokens (15min) | Limits damage from theft |
| Longer refresh tokens (7 days) | Reduces re-auth frequency |
| Store refresh tokens in httpOnly cookie | Not accessible via JavaScript |
| Never store tokens in localStorage | XSS vulnerability |
| Include `jti` for revocation | Enable server-side revocation |
| Use `iss` and `aud` claims | Prevent token confusion |
| Rotate signing keys periodically | Limit blast radius |

---

## Step 3: RBAC/ABAC

### Role-Based Access Control (RBAC)

```python
from enum import Enum
from functools import wraps

class Role(str, Enum):
    ADMIN = "admin"
    EDITOR = "editor"
    VIEWER = "viewer"

ROLE_PERMISSIONS = {
    Role.ADMIN: {"users:read", "users:write", "users:delete", "posts:read", "posts:write", "posts:delete"},
    Role.EDITOR: {"posts:read", "posts:write", "users:read"},
    Role.VIEWER: {"posts:read", "users:read"},
}

class RequirePermission:
    def __init__(self, permission: str):
        self.permission = permission

    async def __call__(self, current_user=Depends(get_current_user)):
        user_permissions = ROLE_PERMISSIONS.get(Role(current_user.role), set())
        if self.permission not in user_permissions:
            raise HTTPException(403, f"Permission '{self.permission}' required")
        return current_user

@router.delete("/api/v1/users/{user_id}")
async def delete_user(
    user_id: str,
    current_user=Depends(RequirePermission("users:delete")),
):
    ...
```

### Next.js Route Protection

```typescript
import { auth } from "@/auth"
import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

export async function middleware(request: NextRequest) {
  const session = await auth()

  if (!session) {
    return NextResponse.redirect(new URL("/login", request.url))
  }

  if (request.nextUrl.pathname.startsWith("/admin") && session.user.role !== "admin") {
    return NextResponse.redirect(new URL("/unauthorized", request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ["/dashboard/:path*", "/admin/:path*", "/api/v1/((?!auth).*)"],
}
```

---

## Step 4: Password Security

### Hashing

```python
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)
```

### Password Policy

```python
from pydantic import BaseModel, Field, field_validator
import re

class PasswordInput(BaseModel):
    password: str = Field(..., min_length=12, max_length=128)

    @field_validator("password")
    @classmethod
    def validate_strength(cls, v):
        checks = [
            (len(v) >= 12, "Must be at least 12 characters"),
            (re.search(r"[A-Z]", v), "Must contain uppercase letter"),
            (re.search(r"[a-z]", v), "Must contain lowercase letter"),
            (re.search(r"\d", v), "Must contain a digit"),
            (re.search(r"[!@#$%^&*(),.?\":{}|<>]", v), "Must contain special character"),
        ]
        failures = [msg for passed, msg in checks if not passed]
        if failures:
            raise ValueError("; ".join(failures))
        return v
```

---

## Step 5: CSRF Protection

### SameSite Cookies

```python
app.add_middleware(
    SessionMiddleware,
    secret_key=settings.SECRET_KEY,
    same_site="lax",
    https_only=not settings.DEBUG,
)
```

### Double Submit Cookie (API)

```typescript
import { NextRequest, NextResponse } from "next/server"

export function middleware(request: NextRequest) {
  if (["POST", "PUT", "PATCH", "DELETE"].includes(request.method)) {
    const cookieToken = request.cookies.get("csrf-token")?.value
    const headerToken = request.headers.get("x-csrf-token")

    if (!cookieToken || cookieToken !== headerToken) {
      return NextResponse.json({ error: "CSRF token mismatch" }, { status: 403 })
    }
  }
  return NextResponse.next()
}
```

---

## Step 6: Session Management

### Token Storage Decision Matrix

| Storage | Access | Security | Best For |
|---------|--------|----------|----------|
| httpOnly cookie | Server only | High (no XSS) | Refresh tokens |
| Memory (state) | Client only | Medium (XSS but not persisted) | Short-lived access tokens |
| localStorage | Client | Low (XSS accessible) | Never for sensitive tokens |
| Session storage | Client | Medium (tab-scoped) | Temporary state |

### Session Invalidation

```python
BLOCKLIST_KEY = "token:blocklist"

async def revoke_token(jti: str):
    await redis_client.set(f"{BLOCKLIST_KEY}:{jti}", "1", ex=86400 * 7)

async def is_token_revoked(jti: str) -> bool:
    return await redis_client.exists(f"{BLOCKLIST_KEY}:{jti}")
```
