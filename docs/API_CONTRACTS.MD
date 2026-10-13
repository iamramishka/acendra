
# API_CONTRACTS.md
# Acedra - Frontend and Backend API Contracts

Document ID: CSA-API-001
Version: 1.0
Status: Proposed - Pending Approval
Recommended Path: docs/API_CONTRACTS.md

Project: Acedra Course Selling Application
Product Type: Commercial E-Learning Platform

Frontend:
Flutter Web + Dart

Backend:
Supabase Edge Functions

Database:
PostgreSQL

Authentication:
Supabase Auth

Authorization:
PostgreSQL RLS + Trusted Backend

State Management:
Riverpod

Architecture:
Feature-First Clean Architecture

Development Model:
Claude Code + OpenAI Codex

API Contract Version:
v1

Classification:
Internal Engineering Documentation

---

# 1. PURPOSE

This document defines the shared
communication contracts between
the Acedra frontend and backend.

Acedra supports:

- Student registration
- Authentication
- Course discovery
- Course details
- Online checkout
- Bank transfer checkout
- Receipt uploads
- Payment verification
- Course enrollments
- Protected content delivery
- Learning progress
- Administrative management
- Financial reporting

The development process uses
two coding agents:

CLAUDE:
Primarily Flutter implementation.

CODEX:
Primarily backend implementation.

Their actual responsibilities are
determined by GitHub task ownership.

Both agents must follow this document
when implementing shared interfaces.

The objective is to prevent:

- Mismatched request structures
- Incompatible response formats
- Missing authorization checks
- Incorrect payment status handling
- Duplicate financial operations
- Undocumented API changes
- Frontend/backend integration failures

---

# 2. DOCUMENT STATUS

Status:
PROPOSED

The contracts in this document
are design specifications.

They are not evidence that endpoints,
tables, functions, or integrations
have already been implemented.

The following remain pending:

- Payment gateway selection
- Production API configuration
- Final currency policy
- Final enrollment duration policy
- Protected video provider selection
- Final PDF delivery method
- Refund and revocation rules

Critical business decisions must
be approved before corresponding
production functionality is enabled.

---

# 3. RELATED DOCUMENTS

Read and follow:

AGENTS.md
CLAUDE.md
PLAN.md
TASKS.md
SRS.md
ARCHITECTURE.md
DATABASE_DESIGN.md
DESIGN_SYSTEM.md
SECURITY.md
CONTRIBUTING.md
TESTING.md
docs/PARALLEL_WORKFLOW.md

Document responsibilities:

SRS.md:
Functional behavior.

DATABASE_DESIGN.md:
Persistent data and constraints.

ARCHITECTURE.md:
System components and trust boundaries.

SECURITY.md:
Authentication, authorization,
and security requirements.

API_CONTRACTS.md:
Shared client/server interfaces.

TASKS.md:
Implementation tasks and ownership.

PARALLEL_WORKFLOW.md:
Agent coordination procedures.

Do not create conflicting copies
of API contracts in multiple files.

---

# 4. API DESIGN PRINCIPLES

All APIs must follow:

API-001:
Security by default.

API-002:
Explicit authentication.

API-003:
Backend authorization.

API-004:
Consistent data types.

API-005:
Stable error codes.

API-006:
Validated request parameters.

API-007:
Minimal response data.

API-008:
Financial idempotency.

API-009:
Transactional business operations.

API-010:
Safe retries.

API-011:
Backward-compatible evolution.

API-012:
Clear ownership.

API-013:
Testable behavior.

API-014:
Documented contract changes.

API-015:
No secret exposure.

Never trust a client merely
because it is the official Flutter app.

---

# 5. API ARCHITECTURE

Acedra uses two main
data access patterns.

## PATTERN A - RLS-PROTECTED DATA ACCESS

Used for appropriately exposed:

- Published course metadata
- Public categories
- Public curriculum metadata
- Own profile
- Own order summaries
- Own enrollment summaries
- Own learning progress reads

Flow:

Flutter
   |
   v
Supabase Dart Client
   |
   v
PostgREST
   |
   v
PostgreSQL Grants + RLS
   |
   v
Authorized Records

These queries use the Supabase SDK.

They are not separate custom
Edge Function endpoints.

## PATTERN B - TRUSTED EDGE FUNCTIONS

Used for:

- Checkout creation
- Payment initialization
- Payment webhook processing
- Bank receipt processing
- Bank transfer approval
- Enrollment grants
- Protected content authorization
- Sensitive administrative operations

Flow:

Flutter
   |
   v
Supabase Edge Function
   |
   v
Authentication and Authorization
   |
   v
Validated Business Logic
   |
   v
Transactional Database Operation
   |
   v
Authoritative Result

The frontend cannot bypass
trusted backend rules.

---

# 6. API BASE ADDRESSES

Supabase project URL:

https://<PROJECT_REF>.supabase.co

Edge Function base URL:

https://<PROJECT_REF>.supabase.co/functions/v1

Supabase database API:

https://<PROJECT_REF>.supabase.co/rest/v1

Supabase Auth and Storage use
their supported SDK/API endpoints.

Do not hardcode production project
references throughout application code.

Use centralized environment configuration.

## Flutter Configuration

Allowed client configuration:

SUPABASE_URL

SUPABASE_PUBLISHABLE_KEY

Important:

Publishable keys are designed
for client applications.

Privileged secret/service-role keys
must never appear in Flutter Web assets.

---

# 7. REQUEST AUTHENTICATION CLASSES

Every function must declare
its caller authentication class.

## AUTH-PUBLIC

For approved public operations.

Example:

Public course preview.

Requirements:

- No student identity required.
- Validate all inputs.
- Apply abuse protections.
- Return only public information.

## AUTH-USER

For authenticated students.

Requirements:

- Valid Supabase user session.
- Server resolves current user ID.
- Object-level authorization enforced.

Examples:

create-checkout-order

save-lesson-progress

authorize-course-content

## AUTH-ADMIN

For authenticated authorized staff.

Requirements:

- Valid Supabase user session.
- Current trusted role verification.
- Resource-level permission check.
- Audit for sensitive mutations.

Examples:

admin-publish-course

admin-review-bank-transfer

## AUTH-WEBHOOK

For signed external provider callbacks.

Requirements:

- Provider-specific authentication.
- Raw request signature verification
  where required by provider.
- Replay protection where supported.
- Idempotent processing.

Supabase user JWT is not
the authority for this caller type.

## AUTH-SERVICE

For internal workers and scheduled jobs.

Requirements:

- Approved service authentication.
- Restricted credentials.
- Minimal privileges.
- No browser access.

---

# 8. AUTHENTICATION IMPLEMENTATION RULES

For authenticated student functions:

- Require valid user credentials.
- Resolve the actual caller identity.
- Validate current account state.
- Enforce record ownership.
- Never trust a request user_id
  as proof of identity.

For admin functions:

- Authenticate the real user.
- Check current trusted roles.
- Validate resource scope.
- Record sensitive actions.

For payment webhooks:

- Do not expect student JWTs.
- Authenticate the payment provider.
- Reject invalid signatures.
- Verify transaction data.

## Supabase Configuration

User-facing functions should use
the supported authenticated-user
Edge Function pattern.

Webhook functions may require:

verify_jwt = false

This setting only disables the
platform JWT requirement.

It does not validate the provider.

Provider authentication must
still happen inside the handler.

A function with disabled JWT checks
must never treat arbitrary callers
as trusted users.

---

# 9. HTTP TRANSPORT RULES

Use HTTPS in production.

JSON requests:

Content-Type:
application/json

Authenticated user requests:

Authorization:
Bearer <USER_ACCESS_TOKEN>

Supabase SDK calls also use
the appropriate project API key.

Do not use a publishable key
as proof of student identity.

## Request Correlation

Recommended response header:

X-Request-ID

Every sensitive operation should
be traceable using a request identifier.

## Idempotency

Recommended header:

Idempotency-Key:
<CLIENT_GENERATED_UNIQUE_KEY>

Use for supported financial
and other retry-sensitive mutations.

## Browser CORS

Edge Functions called by Flutter Web
must support appropriate preflight handling.

Use a reviewed supported
Supabase function authentication/CORS pattern.

CORS is not authorization.

---

# 10. API VERSIONING

Initial contract version:

v1

Document version:

1.0

These represent different concepts.

The API contract version identifies
the client/server interface.

The document version tracks
documentation revisions.

## Version Rules

- Preserve compatible response fields.
- Do not silently rename identifiers.
- Do not change data types without review.
- Do not remove fields used by active clients.
- Do not change status semantics silently.
- Document breaking changes.
- Coordinate Flutter/backend releases.

An API contract version can be
included in successful responses
through a metadata field.

Example:

contract_version:
"v1"

Endpoint-level versioning may be
introduced if a breaking API upgrade
cannot be handled compatibly.

---

# 11. CANONICAL DATA TYPES

Use one consistent type system.

## UUID

JSON type:
string

Example:

"550e8400-e29b-41d4-a716-446655440000"

## TEXT

JSON type:
string

## BOOLEAN

JSON type:
boolean

## TIMESTAMP

JSON type:
string

Format:
ISO 8601 / RFC 3339

Example:

"2026-10-10T12:30:00Z"

## MONEY

Database type:
BIGINT minor units.

API type:
Integer JSON number within
the approved safe numeric range.

Example:

250000

For LKR with 2 minor digits,
this represents LKR 2,500.00.

## CURRENCY

JSON type:
string

Example:

"LKR"

## NULLABLE FIELD

May contain:

null

## ARRAYS

Use JSON arrays.

## STRUCTURED CONTENT

Use validated JSON objects.

---

# 12. MONEY AND CURRENCY CONTRACT

Money must not be represented
as floating-point currency amounts.

Correct:

```json
{
  "amount_minor": 250000,
  "currency_code": "LKR"
}
```

Incorrect:

```json
{
  "amount": 2500.00
}
```

## Important Rules

- Backend determines trusted price.
- Frontend formats approved minor units.
- Database stores exact integer amounts.
- Checkout snapshots amount and currency.
- Currency codes must be validated.
- Negative order totals are prohibited.
- Historical order totals remain immutable.

## Flutter Web Precision

JSON numeric values crossing
browser JavaScript boundaries must
remain within the safe integer range.

The backend must enforce
approved business limits.

If the application later needs
amounts outside that range,
use a coordinated contract change
to decimal-string representation.

Never silently switch money formats.

## Currency Selection

"LKR" is an illustrative example.

The actual production currency
must be approved.

---

# 13. CANONICAL STATUS VALUES

Database and API contracts use
lowercase snake_case status strings.

The Flutter UI may display
formatted labels.

## 13.1 Course Status

draft

published

archived

## 13.2 Order Status

created

pending_payment

pending_verification

paid

failed

cancelled

refunded

## 13.3 Payment Attempt Status

initialized

pending

succeeded

failed

cancelled

refunded

## 13.4 Bank Submission Status

awaiting_receipt

submitted

under_review

approved

rejected

## 13.5 Enrollment Status

active

expired

revoked

## 13.6 Lesson Type

video

pdf

text

image

## 13.7 Payment Method

online

bank_transfer

## IMPORTANT

Some SRS examples use uppercase
labels for business states.

The canonical API/database values
are lowercase as defined here.

If SRS.md or DATABASE_DESIGN.md
has incompatible semantics,
resolve them before implementation.

Do not introduce new statuses
without updating the shared contract.

---

# 14. SUCCESS RESPONSE FORMAT

Trusted Edge Functions should return
the standard response envelope.

Example:

```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "pending_payment"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_example_001"
  }
}
```

## Rules

- data contains the operation result.
- meta contains safe response metadata.
- Do not return privileged internal fields.
- Do not expose server secrets.
- Avoid unnecessary personally
  identifiable information.

## Exceptions

The following may use
different response formats:

- Supabase Auth APIs
- Direct PostgREST responses
- Supabase Storage APIs
- External payment webhook acknowledgements
- Binary/streamed file delivery

The Flutter data layer must normalize
these differences where appropriate.

---

# 15. ERROR RESPONSE FORMAT

Trusted Edge Functions should use
a consistent error envelope.

Example:

```json
{
  "error": {
    "code": "ENROLLMENT_REQUIRED",
    "message": "Purchase this course to access the lesson.",
    "request_id": "req_example_002"
  }
}
```

Optional safe details:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request contains invalid fields.",
    "details": {
      "field": "course_id"
    },
    "request_id": "req_example_003"
  }
}
```

## Error Rules

- Stable machine-readable code.
- Safe user-facing message.
- No SQL stack traces.
- No private account information.
- No gateway secrets.
- No internal storage paths.
- No sensitive administrative metadata.

Flutter must display suitable feedback
based on the error code.

Do not rely on parsing
error-message text for behavior.

---

# 16. STANDARD ERROR CODES

## Authentication

AUTH_REQUIRED

SESSION_EXPIRED

AUTH_INVALID

## Authorization

ACCESS_DENIED

ADMIN_PERMISSION_REQUIRED

RESOURCE_NOT_FOUND

## Validation

VALIDATION_ERROR

INVALID_INPUT

UNSUPPORTED_FILE_TYPE

FILE_TOO_LARGE

## Marketplace

COURSE_NOT_FOUND

COURSE_UNAVAILABLE

LESSON_NOT_FOUND

## Checkout

ALREADY_ENROLLED

CHECKOUT_NOT_ALLOWED

ORDER_NOT_FOUND

ORDER_NOT_PAYABLE

## Payment

PAYMENT_PENDING

PAYMENT_FAILED

PAYMENT_VERIFICATION_FAILED

PAYMENT_AMOUNT_MISMATCH

PAYMENT_CURRENCY_MISMATCH

PAYMENT_PROVIDER_UNAVAILABLE

## Bank Transfers

BANK_SUBMISSION_NOT_FOUND

BANK_RECEIPT_INVALID

BANK_SUBMISSION_ALREADY_FINALIZED

BANK_VERIFICATION_REQUIRED

BANK_REVIEW_CONFLICT

## Enrollments

ENROLLMENT_REQUIRED

ENROLLMENT_EXPIRED

ENROLLMENT_REVOKED

## API Control

IDEMPOTENCY_CONFLICT

RATE_LIMITED

CONFLICT

SERVICE_UNAVAILABLE

INTERNAL_ERROR

Do not expose detailed fraud rules
or private user information
through public-facing errors.

---

# 17. HTTP STATUS CODE POLICY

200 OK

Successful read or accepted
synchronous operation.

201 Created

A new resource was created.

202 Accepted

Operation accepted but
final processing remains pending.

204 No Content

Successful operation without body.

400 Bad Request

Malformed or invalid request.

401 Unauthorized

Authentication missing or invalid.

403 Forbidden

Authenticated caller lacks permission.

404 Not Found

Resource not found or intentionally
concealed under the access policy.

409 Conflict

Current state prevents requested action.

413 Payload Too Large

Request body exceeds approved limits.

415 Unsupported Media Type

Content format not accepted.

422 Unprocessable Content

Semantically invalid input.

429 Too Many Requests

Rate limit exceeded.

500 Internal Server Error

Unexpected server failure.

502 Bad Gateway

External provider failure.

503 Service Unavailable

Service temporarily unavailable.

## Important

Security-sensitive endpoints may return
404 instead of 403 where appropriate
to avoid revealing resource existence.

Provider webhook acknowledgements
must follow the selected provider's
documented retry protocol.

---

# 18. VALIDATION REQUIREMENTS

All Edge Function requests must be
validated at the server boundary.

## Validate

- JSON structure
- Required fields
- Field types
- UUID syntax
- Allowed status values
- Allowed payment methods
- Text lengths
- File size
- MIME type
- Query limits
- Date formats
- Numeric bounds
- Object ownership
- Current business state

## Security Rule

Client-side validation improves UX.

Server-side validation enforces
business correctness.

Do not trust validation results
supplied by Flutter.

---

# 19. PAGINATION AND SORTING

Large result sets must be paginated.

Recommended normalized parameters:

limit:
Integer, default 20, maximum 50.

offset:
Nonnegative integer.

sort:
Approved named sort value.

## Supported Course Sorts

newest

price_asc

price_desc

## Rules

- Define stable secondary ordering.
- Validate limits.
- Avoid unbounded data retrieval.
- Use permitted filters.
- Do not concatenate user input
  into raw SQL strings.

Direct PostgREST queries may use
Supabase SDK range operations.

Flutter repository interfaces should
hide transport-specific pagination details.

---

# 20. ENDPOINT REGISTRY

Legend:

RLS:
Direct Supabase data operation.

USER:
Authenticated user Edge Function.

ADMIN:
Authenticated authorized admin function.

WEBHOOK:
Externally authenticated provider callback.

## Public / Student

| Operation | Transport | Auth |
|---|---|---|
| list-public-courses | RLS read | Public |
| get-public-course | RLS read | Public |
| get-course-curriculum | RLS read | Public |
| get-public-lesson-preview | Edge Function | Public |
| get-own-profile | RLS read | User |
| update-own-profile | RLS update | User |
| list-own-orders | RLS read | User |
| list-own-enrollments | RLS read | User |
| get-own-progress | RLS read | User |
| create-checkout-order | Edge Function | USER |
| initialize-online-payment | Edge Function | USER |
| get-bank-transfer-instructions | Edge Function | USER |
| create-bank-receipt-upload | Edge Function | USER |
| finalize-bank-receipt | Edge Function | USER |
| get-bank-transfer-status | Edge Function | USER |
| authorize-course-content | Edge Function | USER |
| save-lesson-progress | Edge Function | USER |
| save-lesson-bookmark | Edge Function | USER |

## Payment Provider

| Operation | Transport | Auth |
|---|---|---|
| payment-provider-webhook | Edge Function | WEBHOOK |

## Administration

| Operation | Transport | Auth |
|---|---|---|
| admin-dashboard-stats | Edge Function | ADMIN |
| admin-list-bank-transfers | Edge Function | ADMIN |
| admin-get-bank-transfer | Edge Function | ADMIN |
| admin-review-bank-transfer | Edge Function | ADMIN |
| admin-create-course | Edge Function | ADMIN |
| admin-update-course | Edge Function | ADMIN |
| admin-save-section | Edge Function | ADMIN |
| admin-save-lesson | Edge Function | ADMIN |
| admin-create-media-upload | Edge Function | ADMIN |
| admin-publish-course | Edge Function | ADMIN |
| admin-search-students | Edge Function | ADMIN |
| admin-grant-enrollment | Edge Function | ADMIN |
| admin-revoke-enrollment | Edge Function | ADMIN |
| admin-assign-user-role | Edge Function | ADMIN |
| admin-financial-report | Edge Function | ADMIN |

These are proposed logical operations.

Final function names must be approved
before implementation starts.

No deployment is implied.

---

# 21. PUBLIC COURSE LIST CONTRACT

Operation:

list-public-courses

Transport:

Supabase PostgREST via Dart SDK.

Source:

public.courses

Authentication:

Optional.

## Filters

search:
Optional string.

category_slug:
Optional string.

sort:
newest | price_asc | price_desc

limit:
Default 20.

offset:
Default 0.

## Response Model

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "slug": "flutter-for-beginners",
  "title": "Flutter for Beginners",
  "short_description": "Learn Flutter fundamentals.",
  "thumbnail_path": "published/flutter-basics.webp",
  "price_minor": 250000,
  "currency_code": "LKR",
  "status": "published",
  "published_at": "2026-10-10T09:00:00Z"
}
```

This is one example course record.

The complete result is a collection.

## Security Requirements

- Return published courses only.
- Do not expose drafts.
- Do not return protected lesson bytes.
- Do not return private media locations.
- Enforce visibility through RLS.
- Validate sort/filter values.

## Acceptance

- Anonymous users can view published data.
- Draft courses remain inaccessible.
- Pagination behaves consistently.
- Search does not bypass visibility rules.

Related Tasks:

CSA-077
CSA-079
CSA-082
CSA-083
CSA-084
CSA-085

---

# 22. PUBLIC COURSE DETAILS CONTRACT

Operation:

get-public-course

Transport:

Supabase PostgREST.

Lookup:

Course slug or approved public identifier.

## Required Fields

id

slug

title

short_description

description

thumbnail_path

price_minor

currency_code

published_at

category information

## Rules

- Only published courses are returned.
- Price must reflect current public offer.
- Private lesson content is excluded.
- Invalid or hidden courses return
  appropriate not-found behavior.

## Example Response

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "slug": "flutter-for-beginners",
  "title": "Flutter for Beginners",
  "description": "A beginner-level Flutter course.",
  "price_minor": 250000,
  "currency_code": "LKR",
  "category": {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "name": "Programming"
  }
}
```

Nested category data may be composed
by the Flutter repository from
authorized Supabase query results.

This JSON is the normalized
frontend domain response.

---

# 23. PUBLIC CURRICULUM CONTRACT

Operation:

get-course-curriculum

Transport:

Supabase PostgREST.

Authentication:

Optional.

## Response Model

```json
{
  "course_id": "550e8400-e29b-41d4-a716-446655440001",
  "sections": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440003",
      "title": "Getting Started",
      "position": 0,
      "lessons": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440004",
          "title": "Introduction",
          "lesson_type": "video",
          "duration_seconds": 420,
          "position": 0,
          "is_preview": true
        }
      ]
    }
  ]
}
```

## Critical

Public curriculum responses contain
lesson metadata only.

They must not include:

- Private PDF object paths
- Full protected lesson text
- Video signing credentials
- Paid lesson URLs
- Private asset access tokens

RLS must verify publication
of the parent course, section,
and relevant lesson metadata.

---

# 24. PUBLIC LESSON PREVIEW CONTRACT

Operation:

get-public-lesson-preview

Endpoint:

POST /functions/v1/get-public-lesson-preview

Authentication:

AUTH-PUBLIC

## Request

```json
{
  "lesson_id": "550e8400-e29b-41d4-a716-446655440004"
}
```

## Response

```json
{
  "data": {
    "lesson_id": "550e8400-e29b-41d4-a716-446655440004",
    "lesson_type": "text",
    "preview": {
      "title": "Introduction",
      "body": [
        {
          "type": "paragraph",
          "text": "Welcome to this course."
        }
      ]
    }
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_preview_001"
  }
}
```

## Authorization

The backend must verify:

- Course is published.
- Section is published.
- Lesson is published.
- Lesson is explicitly marked preview.
- Preview content is approved for exposure.

## Important

Do not return unrestricted paid content
simply because is_preview is true.

If this feature is not needed for MVP,
it may remain unimplemented until approved.

---

# 25. AUTHENTICATION CONTRACT

Authentication is handled through
the supported Supabase Auth SDK.

Do not create custom password
storage or authentication endpoints.

## Required Operations

signUp

signInWithPassword

signOut

resetPasswordForEmail

verify supported email flow

restore current session

## Identity Source

Supabase Auth user identity.

## Security

- Never return passwords.
- Never log access tokens.
- Do not trust client-generated roles.
- Require current user authentication
  for protected backend functions.
- Use backend permission checks
  for administrative operations.

## Session Failure

When authentication is invalid:

- Clear inappropriate private UI state.
- Show appropriate login guidance.
- Do not retry privileged mutations
  with stale credentials.

---

# 26. PROFILE CONTRACT

Operations:

get-own-profile

update-own-profile

Transport:

Supabase PostgREST.

Authentication:

AUTH-USER

## Read Model

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440010",
  "display_name": "Example Student",
  "avatar_path": null,
  "locale": "en",
  "created_at": "2026-10-10T09:00:00Z",
  "updated_at": "2026-10-10T09:00:00Z"
}
```

## Allowed Update Fields

display_name

avatar_path

locale

## Forbidden Client Updates

id

role

is_admin

user_roles

created_at

Other protected metadata.

## Rules

- Use current authenticated identity.
- Update only permitted columns.
- Enforce row ownership.
- Validate profile field lengths.
- Protect avatar upload paths.

Profile column-level privileges
must match DATABASE_DESIGN.md.

---

# 27. OWN ORDERS CONTRACT

Operation:

list-own-orders

Transport:

Supabase PostgREST.

Authentication:

AUTH-USER

## Response Record

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440020",
  "order_number": "ACD-EXAMPLE-0001",
  "course_id": "550e8400-e29b-41d4-a716-446655440001",
  "course_title_snapshot": "Flutter for Beginners",
  "amount_minor": 250000,
  "currency_code": "LKR",
  "payment_method": "online",
  "status": "pending_payment",
  "created_at": "2026-10-10T10:00:00Z",
  "paid_at": null
}
```

## Rules

- Student reads own orders only.
- Do not expose provider secrets.
- Do not expose internal financial notes.
- Do not allow direct status updates.
- Payment status comes from backend data.

## UI

Display:

- Order reference
- Course
- Amount
- Payment method
- Status
- Date

---

# 28. CREATE CHECKOUT ORDER

Operation:

create-checkout-order

Endpoint:

POST /functions/v1/create-checkout-order

Authentication:

AUTH-USER

Owner:

CODEX - Proposed

Frontend Consumer:

CLAUDE - Proposed

Priority:

P0

## Required Header

Idempotency-Key:
<UNIQUE_CLIENT_GENERATED_KEY>

## Request

```json
{
  "course_id": "550e8400-e29b-41d4-a716-446655440001",
  "payment_method": "online"
}
```

## Successful Response

HTTP 201 or HTTP 200
for an idempotent replay.

```json
{
  "data": {
    "order_id": "550e8400-e29b-41d4-a716-446655440020",
    "order_number": "ACD-EXAMPLE-0001",
    "course": {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "title": "Flutter for Beginners"
    },
    "amount_minor": 250000,
    "currency_code": "LKR",
    "payment_method": "online",
    "status": "pending_payment",
    "next_action": "initialize_online_payment"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_checkout_001"
  }
}
```

## Bank Transfer Variant

When payment_method is bank_transfer:

next_action:
show_bank_instructions

## Backend Requirements

1. Authenticate the student.
2. Validate course identity.
3. Validate course publication.
4. Check enrollment rules.
5. Read authoritative course price.
6. Validate supported currency.
7. Create a trusted order snapshot.
8. Apply idempotency.
9. Return safe order data.

## Forbidden Inputs

Do not accept authoritative:

user_id

amount_minor

currency_code

is_paid

payment_status

enrollment_status

These values come from trusted sources.

## Error Cases

AUTH_REQUIRED

COURSE_NOT_FOUND

COURSE_UNAVAILABLE

ALREADY_ENROLLED

CHECKOUT_NOT_ALLOWED

IDEMPOTENCY_CONFLICT

INTERNAL_ERROR

## Security Invariant

Creating an order must not
grant access to paid lessons.

Related Tasks:

CSA-092
CSA-096
CSA-097
CSA-098

---

# 29. INITIALIZE ONLINE PAYMENT

Operation:

initialize-online-payment

Endpoint:

POST /functions/v1/initialize-online-payment

Authentication:

AUTH-USER

Priority:

P0

## Request

```json
{
  "order_id": "550e8400-e29b-41d4-a716-446655440020"
}
```

## Response

```json
{
  "data": {
    "order_id": "550e8400-e29b-41d4-a716-446655440020",
    "provider": "configured_provider",
    "redirect_url": "https://payments.example.test/session/example",
    "expires_at": "2026-10-10T10:30:00Z",
    "status": "pending_payment"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_payment_init_001"
  }
}
```

The example domain is illustrative.

Actual provider URLs and response
fields depend on the selected gateway.

## Backend Requirements

- Authenticate student.
- Verify order ownership.
- Verify order remains payable.
- Verify payment method is online.
- Use trusted order amount/currency.
- Create provider checkout securely.
- Store provider session reference.
- Handle provider errors safely.

## Frontend Requirements

- Open approved provider checkout.
- Do not modify trusted payment amount.
- Do not interpret redirect as settlement.
- Refresh backend order status
  after returning from the provider.

## Retry Policy

Payment initialization must follow
a documented idempotency or
safe session-reuse policy.

Avoid creating uncontrolled
duplicate payment sessions.

---

# 30. PAYMENT PROVIDER WEBHOOK

Operation:

payment-provider-webhook

Endpoint:

POST /functions/v1/payment-provider-webhook

Authentication:

AUTH-WEBHOOK

Caller:

Configured payment provider.

Priority:

P0 - CRITICAL

## Important

This endpoint is not called
by the Flutter application.

The selected payment provider
calls the backend directly.

## Provider Request

The raw request format is defined
by the selected gateway.

It may include:

- Event identifier
- Transaction reference
- Order reference
- Event type
- Amount
- Currency
- Provider status
- Signature headers

Do not invent or assume
a provider-specific signature algorithm.

## Verification Sequence

1. Read request safely.
2. Verify provider signature/authentication.
3. Apply replay protection if supported.
4. Validate event structure.
5. Resolve trusted payment attempt.
6. Confirm order reference.
7. Confirm amount.
8. Confirm currency.
9. Validate event meaning.
10. Check processed event history.
11. Execute atomic payment transaction.
12. Return provider-compatible acknowledgement.

## Critical Rules

- Verify before treating an event as trusted.
- Do not allow forged events
  to reserve verified event IDs.
- Duplicate events must be safe.
- Out-of-order events must be safe.
- An older failure must not
  downgrade an already paid order.
- Financial finalization must be atomic.
- Enrollment creation must be transactional.
- Audit records must be preserved.

## Example Logical Acknowledgement

```json
{
  "received": true
}
```

Actual HTTP status and body
must follow provider requirements.

## Error Handling

Invalid authentication:

Reject safely.

Temporary internal failure:

Use provider-compatible retry behavior.

Already processed valid event:

Acknowledge without repeating
financial side effects.

## Required Tests

- Invalid signature
- Valid signature
- Amount mismatch
- Currency mismatch
- Unknown order
- Duplicate event
- Concurrent event
- Replay attempt
- Out-of-order event
- Database rollback
- Reconciliation recovery

Related Tasks:

CSA-100
CSA-102
CSA-103
CSA-104
CSA-105
CSA-120
CSA-121
CSA-122
CSA-126

---

# 31. PAYMENT RETURN AND STATUS

The provider may redirect
the student back to Acedra.

Example frontend route:

/orders/:orderId/status

## Critical

This route does not
verify a payment.

The Flutter application must
query authoritative backend state.

Recommended status source:

list-own-orders / own-order lookup
through RLS.

## Example

```json
{
  "order_id": "550e8400-e29b-41d4-a716-446655440020",
  "status": "paid",
  "paid_at": "2026-10-10T10:15:00Z"
}
```

## UI Behavior

pending_payment:
Show payment pending.

pending_verification:
Show verification pending.

paid:
Refresh enrollment and
show access when entitlement
is actually active.

failed:
Show retry/recovery options.

cancelled:
Show cancellation state.

refunded:
Show approved refund status.

## Important

Do not infer active enrollment
from order status alone.

Confirm current course entitlement
before granting learning navigation.

---

# 32. BANK TRANSFER INSTRUCTIONS

Operation:

get-bank-transfer-instructions

Endpoint:

POST /functions/v1/get-bank-transfer-instructions

Authentication:

AUTH-USER

## Request

```json
{
  "order_id": "550e8400-e29b-41d4-a716-446655440021"
}
```

## Response

```json
{
  "data": {
    "order_id": "550e8400-e29b-41d4-a716-446655440021",
    "amount_minor": 250000,
    "currency_code": "LKR",
    "bank": {
      "bank_name": "Example Bank",
      "account_name": "Acedra",
      "account_number": "EXAMPLE_ACCOUNT",
      "branch_name": "Example Branch"
    },
    "payment_reference": "ACD-EXAMPLE-0002",
    "status": "pending_payment"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_bank_info_001"
  }
}
```

All bank values above are placeholders.

## Rules

- Authenticate order owner.
- Verify bank_transfer payment method.
- Return trusted official bank details.
- Return the order's exact amount.
- Do not use client-provided bank accounts.
- Preserve bank destination version
  for the relevant historical order.
- Show only approved payment instructions.

---

# 33. CREATE BANK RECEIPT UPLOAD

Operation:

create-bank-receipt-upload

Endpoint:

POST /functions/v1/create-bank-receipt-upload

Authentication:

AUTH-USER

Priority:

P0

## Request

```json
{
  "order_id": "550e8400-e29b-41d4-a716-446655440021",
  "file_name": "transfer-receipt.pdf",
  "content_type": "application/pdf",
  "size_bytes": 156000
}
```

## Response

```json
{
  "data": {
    "submission_id": "550e8400-e29b-41d4-a716-446655440030",
    "status": "awaiting_receipt",
    "upload": {
      "mode": "supabase_signed_upload",
      "bucket": "bank-receipts",
      "path": "server-assigned/private-object-path",
      "token": "REDACTED_EXAMPLE_TOKEN"
    },
    "max_size_bytes": 5242880
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_bank_upload_001"
  }
}
```

The upload capability format depends
on the approved Storage integration.

The 5 MB maximum is a proposed
initial limit, not an implemented setting.

## Backend Requirements

- Authenticate user.
- Verify order ownership.
- Verify order is bank-transfer payable.
- Validate file metadata.
- Allocate a server-controlled object path.
- Create or reuse an authorized
  awaiting_receipt submission.
- Issue a scoped upload capability.
- Restrict overwrite behavior.
- Prevent conflicting active submissions.

## Important

The Flutter client must not choose
an arbitrary storage object path.

Upload tokens are bearer capabilities.

Never log or publish upload tokens.

Provider-issued signed upload URLs
may have provider-defined expiry periods.

Do not claim an arbitrary shorter TTL
unless the chosen implementation
actually enforces it.

---

# 34. BANK RECEIPT STORAGE TRANSFER

The actual file upload uses
the approved Supabase Storage mechanism.

This is a separate transport step
from the Edge Function request.

## Upload Sequence

1. Obtain upload capability.
2. Upload bytes to assigned private path.
3. Check upload result.
4. Call finalize-bank-receipt.
5. Backend independently verifies
   the uploaded object.

## Security Requirements

- Private bucket.
- No public receipt URL.
- Restrict paths.
- Restrict overwrite.
- Validate file size.
- Validate content format.
- Verify object belongs to submission.
- Use content scanning if required
  by the approved threat model.

The client saying "uploaded"
is not sufficient proof
that a valid object exists.

---

# 35. FINALIZE BANK RECEIPT

Operation:

finalize-bank-receipt

Endpoint:

POST /functions/v1/finalize-bank-receipt

Authentication:

AUTH-USER

Priority:

P0

## Request

```json
{
  "submission_id": "550e8400-e29b-41d4-a716-446655440030"
}
```

## Response

```json
{
  "data": {
    "submission_id": "550e8400-e29b-41d4-a716-446655440030",
    "order_id": "550e8400-e29b-41d4-a716-446655440021",
    "submission_status": "submitted",
    "order_status": "pending_verification",
    "submitted_at": "2026-10-10T10:25:00Z"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_bank_finalize_001"
  }
}
```

## Backend Requirements

- Authenticate student.
- Verify submission ownership.
- Verify order association.
- Verify expected submission state.
- Verify actual private object exists.
- Verify approved file constraints.
- Record submission event.
- Move order to pending_verification.
- Queue notification if appropriate.

## Critical

Submission does not:

- Mark order paid.
- Approve the receipt.
- Grant course enrollment.
- Authorize protected content.

---

# 36. BANK TRANSFER STATUS

Operation:

get-bank-transfer-status

Endpoint:

POST /functions/v1/get-bank-transfer-status

Authentication:

AUTH-USER

## Request

```json
{
  "order_id": "550e8400-e29b-41d4-a716-446655440021"
}
```

## Response

```json
{
  "data": {
    "order_id": "550e8400-e29b-41d4-a716-446655440021",
    "order_status": "pending_verification",
    "submission": {
      "id": "550e8400-e29b-41d4-a716-446655440030",
      "status": "under_review",
      "submitted_at": "2026-10-10T10:25:00Z",
      "reviewed_at": null,
      "rejection_reason": null
    }
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_bank_status_001"
  }
}
```

## Rules

- Student reads own order only.
- Student receives public-facing review status.
- Do not return internal fraud notes.
- Do not return private reviewer credentials.
- Do not return another student's receipt.

---

# 37. OWN ENROLLMENTS CONTRACT

Operation:

list-own-enrollments

Transport:

Supabase PostgREST.

Authentication:

AUTH-USER

## Response Record

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440040",
  "course_id": "550e8400-e29b-41d4-a716-446655440001",
  "status": "active",
  "granted_at": "2026-10-10T10:35:00Z",
  "expires_at": null,
  "revoked_at": null
}
```

## Rules

- Read own enrollments only.
- No direct student writes.
- Treat status as authoritative server state.
- Check expiration when evaluating access.
- Do not assume active status
  overrides an already-passed expiry.

## My Courses

Flutter may join or compose
authorized course metadata
with the student's enrollments.

Backend authorization remains
mandatory when opening lessons.

---

# 38. AUTHORIZE COURSE CONTENT

Operation:

authorize-course-content

Endpoint:

POST /functions/v1/authorize-course-content

Authentication:

AUTH-USER

Priority:

P0

## Request

```json
{
  "lesson_id": "550e8400-e29b-41d4-a716-446655440004"
}
```

## Required Backend Checks

1. Authenticate caller.
2. Resolve lesson.
3. Resolve parent section and course.
4. Validate lesson publication.
5. Validate course availability.
6. Validate student enrollment.
7. Validate expiration.
8. Validate revocation.
9. Resolve authorized content.
10. Return a controlled descriptor.

## Response: PDF Example

```json
{
  "data": {
    "lesson_id": "550e8400-e29b-41d4-a716-446655440004",
    "lesson_type": "pdf",
    "delivery": {
      "mode": "signed_url",
      "url": "https://storage.example.test/private/authorized-document",
      "expires_at": "2026-10-10T10:40:00Z",
      "watermark_strategy": "server_applied"
    }
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_content_001"
  }
}
```

This is an illustrative descriptor.

The URL, expiry, delivery mode,
and watermark strategy must reflect
the actual approved implementation.

Do not claim a server-applied watermark
unless the returned bytes really
contain that watermark.

## Error Cases

AUTH_REQUIRED

LESSON_NOT_FOUND

ENROLLMENT_REQUIRED

ENROLLMENT_EXPIRED

ENROLLMENT_REVOKED

ACCESS_DENIED

SERVICE_UNAVAILABLE

## Important

Knowing a lesson ID must not
grant access to private media.

The browser must never receive
permanent unrestricted access
to original paid assets.

---

# 39. PROTECTED CONTENT DELIVERY MODES

Possible approved modes:

signed_url

proxied_stream

provider_token

## signed_url

Backend returns time-limited
authorized storage access.

## proxied_stream

Backend-controlled delivery
streams the authorized resource.

## provider_token

Backend returns an appropriate
provider-specific playback credential.

## Contract Rule

Frontend must not guess
which delivery mode is used.

Implement a typed content descriptor.

Every mode must have:

- Required response fields
- Expiration behavior
- Error handling
- Security tests

Changing delivery mode requires
contract coordination.

---

# 40. PDF CONTENT CONTRACT

Lesson Type:

pdf

## Frontend Responsibilities

- Open authorized PDF.
- Render pages.
- Handle zoom.
- Handle page navigation.
- Handle fit-to-width.
- Track reading position.
- Handle expired access.
- Display approved watermark behavior.

## Backend Responsibilities

- Verify enrollment.
- Restrict PDF asset access.
- Issue appropriate delivery capability.
- Apply approved watermark transformation.
- Protect the original document.
- Return safe errors.

## Security Limitation

Flutter Web cannot guarantee
preventing screenshots,
screen recording, developer tool
inspection, or content copying.

Signed URLs cannot erase bytes
already downloaded by the browser.

## Important

UI-only watermark overlays
should not be described
as permanent document watermarking.

---

# 41. VIDEO CONTENT CONTRACT

Lesson Type:

video

## Example Descriptor

```json
{
  "data": {
    "lesson_id": "550e8400-e29b-41d4-a716-446655440050",
    "lesson_type": "video",
    "delivery": {
      "mode": "provider_token",
      "provider": "configured_video_provider",
      "playback_reference": "provider-specific-reference",
      "expires_at": "2026-10-10T11:00:00Z"
    }
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_video_001"
  }
}
```

## Requirements

- Entitlement required.
- Lesson ownership validated.
- No signing secret in Flutter.
- Playback errors handled.
- Token renewal follows
  approved provider policy.
- Video progress is saved safely.

The final delivery fields depend
on the selected provider.

---

# 42. TEXT AND IMAGE CONTENT CONTRACT

## Text Lesson

Returned content should be validated
structured text.

Example:

```json
{
  "data": {
    "lesson_id": "550e8400-e29b-41d4-a716-446655440060",
    "lesson_type": "text",
    "content": {
      "version": 1,
      "blocks": [
        {
          "type": "heading",
          "text": "Introduction"
        },
        {
          "type": "paragraph",
          "text": "Welcome to the lesson."
        }
      ]
    }
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_text_001"
  }
}
```

## Image Lesson

Return authorized image descriptors.

Examples:

- Controlled image URL
- Authorized proxy reference
- Approved asset metadata

## Security

- Validate entitlement.
- Sanitize structured content.
- Avoid arbitrary script execution.
- Protect paid image resources.
- Return only authorized content.

---

# 43. LEARNING PROGRESS READ CONTRACT

Operation:

get-own-progress

Transport:

Supabase PostgREST.

Authentication:

AUTH-USER

## Response Record

```json
{
  "lesson_id": "550e8400-e29b-41d4-a716-446655440004",
  "progress_seconds": 120,
  "pdf_page": 5,
  "is_completed": false,
  "last_opened_at": "2026-10-10T10:50:00Z"
}
```

## Rules

- Student reads own progress.
- Cross-student access denied.
- Do not expose another user's data.
- Returning old own progress does not
  authorize protected content delivery.

---

# 44. SAVE LEARNING PROGRESS

Operation:

save-lesson-progress

Endpoint:

POST /functions/v1/save-lesson-progress

Authentication:

AUTH-USER

## Request

```json
{
  "lesson_id": "550e8400-e29b-41d4-a716-446655440004",
  "progress_seconds": 120,
  "pdf_page": 5,
  "is_completed": false
}
```

## Response

```json
{
  "data": {
    "lesson_id": "550e8400-e29b-41d4-a716-446655440004",
    "progress_seconds": 120,
    "pdf_page": 5,
    "is_completed": false,
    "updated_at": "2026-10-10T10:51:00Z"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_progress_001"
  }
}
```

## Backend Requirements

- Authenticate user.
- Validate lesson.
- Validate authorized course access.
- Validate progress values.
- Upsert using trusted current user identity.
- Prevent cross-student writes.

## Frontend Requirements

- Save at reasonable intervals.
- Avoid one write per scroll event.
- Handle temporary network failures.
- Do not show persisted success
  before backend confirmation.

## Direct RLS Alternative

Direct student progress writes
may be used only when the database
policy securely enforces both
ownership and required entitlement.

The selected implementation must
be documented before coding.

Do not implement both mutation paths
without architectural approval.

---

# 45. LESSON BOOKMARK CONTRACT

Operation:

save-lesson-bookmark

Endpoint:

POST /functions/v1/save-lesson-bookmark

Authentication:

AUTH-USER

## Request

```json
{
  "lesson_id": "550e8400-e29b-41d4-a716-446655440004",
  "label": "Important example",
  "pdf_page": 8
}
```

## Response

```json
{
  "data": {
    "bookmark_id": "550e8400-e29b-41d4-a716-446655440070",
    "lesson_id": "550e8400-e29b-41d4-a716-446655440004",
    "pdf_page": 8
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_bookmark_001"
  }
}
```

## Rules

- Student identity trusted.
- Bookmark belongs to student.
- Lesson access validated.
- Position values validated.

Advanced bookmark functionality
may be scheduled after MVP.

---

# 46. ADMIN API AUTHORIZATION

Every administrative function
must perform trusted RBAC checks.

## Roles

content_manager

finance_admin

super_admin

## Rules

- Authenticate caller.
- Resolve current trusted roles.
- Check requested operation permission.
- Check resource scope.
- Reject insufficient permissions.
- Audit sensitive mutations.

## Important

Do not trust:

- Frontend role labels
- Client-supplied role names
- Hidden UI controls
- Public profile metadata

An admin function must not assume
all authenticated users are admins.

---

# 47. ADMIN DASHBOARD STATISTICS

Operation:

admin-dashboard-stats

Endpoint:

POST /functions/v1/admin-dashboard-stats

Authentication:

AUTH-ADMIN

## Request

```json
{
  "period": "last_30_days"
}
```

## Example Response

```json
{
  "data": {
    "published_courses": 12,
    "registered_students": 450,
    "active_enrollments": 180,
    "pending_bank_reviews": 8,
    "revenue": {
      "amount_minor": 12500000,
      "currency_code": "LKR"
    }
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_admin_stats_001"
  }
}
```

All values are illustrative.

## Security

The backend must decide
which metrics a role may access.

Content managers should not
automatically receive sensitive
financial reporting data.

Revenue aggregation requires
an approved financial definition.

Do not sum different currencies
into one undifferentiated amount.

---

# 48. ADMIN BANK REVIEW QUEUE

Operation:

admin-list-bank-transfers

Endpoint:

POST /functions/v1/admin-list-bank-transfers

Authentication:

AUTH-ADMIN

Required Role:

finance_admin or authorized super_admin

## Request

```json
{
  "status": "submitted",
  "limit": 20,
  "offset": 0
}
```

## Response

```json
{
  "data": {
    "items": [
      {
        "submission_id": "550e8400-e29b-41d4-a716-446655440030",
        "order_id": "550e8400-e29b-41d4-a716-446655440021",
        "order_number": "ACD-EXAMPLE-0002",
        "amount_minor": 250000,
        "currency_code": "LKR",
        "status": "submitted",
        "submitted_at": "2026-10-10T10:25:00Z"
      }
    ],
    "total": 1,
    "limit": 20,
    "offset": 0
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_bank_queue_001"
  }
}
```

## Rules

- Only authorized finance staff.
- Paginated responses.
- Restricted student data.
- No unnecessary bank receipt tokens.
- No unrelated financial records.
- Filter values validated.

---

# 49. ADMIN BANK REVIEW DETAILS

Operation:

admin-get-bank-transfer

Endpoint:

POST /functions/v1/admin-get-bank-transfer

Authentication:

AUTH-ADMIN

## Request

```json
{
  "submission_id": "550e8400-e29b-41d4-a716-446655440030"
}
```

## Response

```json
{
  "data": {
    "submission_id": "550e8400-e29b-41d4-a716-446655440030",
    "order": {
      "id": "550e8400-e29b-41d4-a716-446655440021",
      "amount_minor": 250000,
      "currency_code": "LKR",
      "status": "pending_verification"
    },
    "submission_status": "under_review",
    "receipt": {
      "delivery_mode": "signed_url",
      "url": "https://storage.example.test/private/review-capability",
      "expires_at": "2026-10-10T11:00:00Z"
    }
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_bank_detail_001"
  }
}
```

## Security

- Verify finance permission.
- Return only necessary order data.
- Issue receipt access only
  to authorized reviewers.
- Do not use public Storage buckets.
- Avoid logging signed receipt URLs.
- Protect sensitive review notes.

Receipt viewing does not
automatically approve the payment.

---

# 50. ADMIN REVIEW BANK TRANSFER

Operation:

admin-review-bank-transfer

Endpoint:

POST /functions/v1/admin-review-bank-transfer

Authentication:

AUTH-ADMIN

Required Role:

finance_admin or authorized super_admin

Priority:

P0 - CRITICAL

## Approval Request

```json
{
  "submission_id": "550e8400-e29b-41d4-a716-446655440030",
  "decision": "approve",
  "verification": {
    "bank_account_id": "550e8400-e29b-41d4-a716-446655440080",
    "bank_transaction_reference": "VERIFIED-EXAMPLE-REFERENCE",
    "amount_minor": 250000,
    "currency_code": "LKR",
    "bank_credit_confirmed": true
  }
}
```

## Rejection Request

```json
{
  "submission_id": "550e8400-e29b-41d4-a716-446655440030",
  "decision": "reject",
  "rejection_reason": "Unable to verify the bank transfer."
}
```

## Approval Response

```json
{
  "data": {
    "submission_id": "550e8400-e29b-41d4-a716-446655440030",
    "submission_status": "approved",
    "order_status": "paid",
    "enrollment_status": "active"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_bank_review_001"
  }
}
```

## Critical Backend Requirements

1. Authenticate finance reviewer.
2. Verify current trusted role.
3. Verify reviewer may access submission.
4. Apply self-approval restrictions.
5. Lock submission and order.
6. Validate current submission state.
7. Validate decision type.
8. Verify required bank evidence fields.
9. Require independent confirmation
   of actual bank settlement.
10. Verify amount and currency.
11. Apply settlement reuse controls.
12. Record approved/rejected decision.
13. Update order state.
14. Grant enrollment only if approved.
15. Record audit event.
16. Queue notification.
17. Commit transaction atomically.

## Important

bank_credit_confirmed is a recorded
authorized reviewer assertion.

It is not automatic proof
that money reached the bank.

The organization's finance process
must independently establish settlement.

Do not accept this field
from ordinary students.

## Concurrency

- Duplicate requests must be safe.
- Conflicting decisions must be rejected.
- Use transaction locks.
- Preserve historical review records.

## Error Codes

ADMIN_PERMISSION_REQUIRED

BANK_SUBMISSION_NOT_FOUND

BANK_VERIFICATION_REQUIRED

BANK_REVIEW_CONFLICT

BANK_SUBMISSION_ALREADY_FINALIZED

IDEMPOTENCY_CONFLICT

Related Tasks:

CSA-112
CSA-113
CSA-114
CSA-123
CSA-125

---

# 51. ADMIN COURSE CREATION

Operation:

admin-create-course

Endpoint:

POST /functions/v1/admin-create-course

Authentication:

AUTH-ADMIN

Required Role:

Authorized content_manager or super_admin

## Request

```json
{
  "category_id": "550e8400-e29b-41d4-a716-446655440002",
  "slug": "flutter-for-beginners",
  "title": "Flutter for Beginners",
  "short_description": "Learn Flutter fundamentals.",
  "description": "Complete introductory course.",
  "price_minor": 250000,
  "currency_code": "LKR"
}
```

## Response

```json
{
  "data": {
    "course_id": "550e8400-e29b-41d4-a716-446655440001",
    "status": "draft",
    "created_at": "2026-10-10T09:00:00Z"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_course_create_001"
  }
}
```

## Rules

- Authorize course creation.
- Validate category.
- Validate slug.
- Validate price.
- Validate currency.
- Create course as draft.
- Record actor identity.
- Do not automatically publish.

Course creation permission
does not imply finance-admin permission.

---

# 52. ADMIN COURSE UPDATE

Operation:

admin-update-course

Endpoint:

POST /functions/v1/admin-update-course

Authentication:

AUTH-ADMIN

## Request

```json
{
  "course_id": "550e8400-e29b-41d4-a716-446655440001",
  "expected_updated_at": "2026-10-10T09:00:00Z",
  "changes": {
    "title": "Flutter Fundamentals",
    "price_minor": 300000
  }
}
```

## Response

```json
{
  "data": {
    "course_id": "550e8400-e29b-41d4-a716-446655440001",
    "status": "draft",
    "updated_at": "2026-10-10T11:00:00Z"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_course_update_001"
  }
}
```

## Rules

- Verify course management scope.
- Validate editable fields.
- Validate current course state.
- Use optimistic concurrency.
- Reject stale conflicting updates.
- Protect publication state.
- Preserve old order price snapshots.
- Audit sensitive changes.

## Conflict

Return HTTP 409 when
expected_updated_at does not match
the current approved record version.

Do not silently overwrite
another editor's changes.

---

# 53. ADMIN CURRICULUM EDITING

Operations:

admin-save-section

admin-save-lesson

Authentication:

AUTH-ADMIN

## Section Request

```json
{
  "course_id": "550e8400-e29b-41d4-a716-446655440001",
  "section_id": null,
  "title": "Getting Started",
  "position": 0,
  "is_published": false
}
```

## Lesson Request

```json
{
  "section_id": "550e8400-e29b-41d4-a716-446655440003",
  "lesson_id": null,
  "title": "Introduction",
  "lesson_type": "text",
  "position": 0,
  "is_preview": false,
  "is_published": false,
  "content": {
    "version": 1,
    "blocks": [
      {
        "type": "paragraph",
        "text": "Lesson introduction."
      }
    ]
  }
}
```

## Response

Return:

- Authoritative section/lesson ID
- Current status
- Position
- Updated timestamp
- Safe validation feedback

## Rules

- Verify course ownership/scope.
- Validate lesson type.
- Validate content structure.
- Validate section relationship.
- Preserve ordering constraints.
- Do not expose draft lesson content.
- Do not directly publish protected assets.

## Protected Content

Paid lesson content must be stored
and served through the approved
private content architecture.

---

# 54. ADMIN MEDIA UPLOAD

Operation:

admin-create-media-upload

Endpoint:

POST /functions/v1/admin-create-media-upload

Authentication:

AUTH-ADMIN

## Request

```json
{
  "course_id": "550e8400-e29b-41d4-a716-446655440001",
  "lesson_id": "550e8400-e29b-41d4-a716-446655440004",
  "asset_type": "course_pdf",
  "file_name": "chapter-one.pdf",
  "content_type": "application/pdf",
  "size_bytes": 1250000
}
```

## Response

```json
{
  "data": {
    "asset_id": "550e8400-e29b-41d4-a716-446655440090",
    "upload": {
      "mode": "supabase_signed_upload",
      "bucket": "course-pdfs",
      "path": "server-assigned/course-asset-path",
      "token": "REDACTED_EXAMPLE_TOKEN"
    }
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_admin_upload_001"
  }
}
```

## Requirements

- Verify content manager scope.
- Verify course/lesson relationship.
- Validate type and size.
- Allocate server-controlled path.
- Use private storage for paid assets.
- Restrict overwrite.
- Finalize asset readiness only
  after actual upload validation.

## Important

Course PDF uploads must not
automatically create publicly
downloadable links.

For production, define an upload
finalization and media-validation step
before an asset becomes publishable.

---

# 55. ADMIN COURSE PUBLICATION

Operation:

admin-publish-course

Endpoint:

POST /functions/v1/admin-publish-course

Authentication:

AUTH-ADMIN

## Request

```json
{
  "course_id": "550e8400-e29b-41d4-a716-446655440001",
  "expected_updated_at": "2026-10-10T11:00:00Z"
}
```

## Response

```json
{
  "data": {
    "course_id": "550e8400-e29b-41d4-a716-446655440001",
    "status": "published",
    "published_at": "2026-10-10T11:05:00Z"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_publish_001"
  }
}
```

## Backend Validation

- Authorized course manager.
- Required metadata complete.
- Valid course price/currency.
- Valid curriculum structure.
- Referenced assets are ready.
- Public content visibility is safe.
- Publication state transition allowed.
- Audit entry recorded.

A Flutter publish button
must not bypass these checks.

---

# 56. ADMIN STUDENT MANAGEMENT

Operation:

admin-search-students

Endpoint:

POST /functions/v1/admin-search-students

Authentication:

AUTH-ADMIN

## Request

```json
{
  "search": "example",
  "limit": 20,
  "offset": 0
}
```

## Response

```json
{
  "data": {
    "items": [
      {
        "student_id": "550e8400-e29b-41d4-a716-446655440010",
        "display_name": "Example Student",
        "active_enrollments": 2
      }
    ],
    "total": 1
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_students_001"
  }
}
```

## Security

- Restrict to authorized staff.
- Minimize student information.
- Do not reveal unnecessary
  authentication metadata.
- Apply pagination.
- Validate search inputs.
- Audit sensitive data access
  where required by policy.

Administrative student search
must not become a public directory.

---

# 57. ADMIN MANUAL ENROLLMENT GRANT

Operation:

admin-grant-enrollment

Endpoint:

POST /functions/v1/admin-grant-enrollment

Authentication:

AUTH-ADMIN

Priority:

P0

## Request

```json
{
  "student_id": "550e8400-e29b-41d4-a716-446655440010",
  "course_id": "550e8400-e29b-41d4-a716-446655440001",
  "reason": "Approved complimentary course access"
}
```

## Response

```json
{
  "data": {
    "enrollment_id": "550e8400-e29b-41d4-a716-446655440040",
    "status": "active",
    "source_type": "admin_grant"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_admin_grant_001"
  }
}
```

## Critical Requirements

- Restrict to explicitly approved roles.
- Verify student and course.
- Validate business policy.
- Apply idempotency.
- Preserve grant history.
- Record authorized actor.
- Record reason.
- Audit the action.

Content-manager permission alone
must not imply unrestricted
manual enrollment grant authority.

---

# 58. ADMIN REVOKE ENROLLMENT

Operation:

admin-revoke-enrollment

Endpoint:

POST /functions/v1/admin-revoke-enrollment

Authentication:

AUTH-ADMIN

Priority:

P0

## Request

```json
{
  "enrollment_id": "550e8400-e29b-41d4-a716-446655440040",
  "reason": "Approved access revocation"
}
```

## Response

```json
{
  "data": {
    "enrollment_id": "550e8400-e29b-41d4-a716-446655440040",
    "status": "revoked",
    "revoked_at": "2026-10-10T12:00:00Z"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_revoke_001"
  }
}
```

## Rules

- Verify administrative permission.
- Validate current enrollment.
- Record revocation reason.
- Preserve grant history.
- Record audit entry.
- Deny new protected content access.

## Browser Limitation

Previously downloaded content
cannot necessarily be erased
from a student's device or browser.

---

# 59. ADMIN ROLE ASSIGNMENT

Operation:

admin-assign-user-role

Endpoint:

POST /functions/v1/admin-assign-user-role

Authentication:

AUTH-ADMIN

Required Role:

Explicitly authorized super_admin.

Priority:

P0

## Request

```json
{
  "student_id": "550e8400-e29b-41d4-a716-446655440010",
  "role_code": "content_manager",
  "action": "grant"
}
```

## Response

```json
{
  "data": {
    "user_id": "550e8400-e29b-41d4-a716-446655440010",
    "role_code": "content_manager",
    "action": "grant",
    "status": "active"
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_role_001"
  }
}
```

## Critical Rules

- Never trust user-supplied admin identity.
- Validate trusted super-admin permission.
- Validate target user.
- Validate supported role.
- Prevent unauthorized privilege escalation.
- Apply approved self-modification rules.
- Record actor and audit event.
- Verify role changes take effect
  according to the approved session model.

Students cannot assign themselves
administrative roles.

---

# 60. ADMIN FINANCIAL REPORT

Operation:

admin-financial-report

Endpoint:

POST /functions/v1/admin-financial-report

Authentication:

AUTH-ADMIN

Required Role:

Authorized finance role.

## Request

```json
{
  "from": "2026-10-01",
  "to": "2026-10-10",
  "currency_code": "LKR"
}
```

## Response

```json
{
  "data": {
    "currency_code": "LKR",
    "orders_paid": 42,
    "gross_amount_minor": 10500000,
    "refunded_amount_minor": 0,
    "net_amount_minor": 10500000
  },
  "meta": {
    "contract_version": "v1",
    "request_id": "req_finance_001"
  }
}
```

Numbers are illustrative.

## Rules

- Verify finance authorization.
- Validate date range.
- Validate currency.
- Define revenue recognition.
- Use trusted financial records.
- Avoid cross-currency aggregation.
- Keep private data out of
  unnecessary reports.

Refund and fee calculations
require approved business definitions.

---

# 61. NOTIFICATION CONTRACTS

Notifications may include:

payment_verified

bank_receipt_submitted

bank_transfer_approved

bank_transfer_rejected

enrollment_granted

enrollment_revoked

## Recommended Pattern

Trusted State Change
    |
    v
Notification Outbox
    |
    v
Authorized Worker
    |
    v
Email Provider

## Rules

- Do not send sensitive provider secrets.
- Do not send full bank receipts in email.
- Use approved templates.
- Keep delivery retries safe.
- Avoid duplicate notifications.
- Respect privacy settings.

## Important

Notification delivery failure
must not roll back an otherwise
successfully committed payment.

Notification delivery is not
proof of payment verification.

---

# 62. INTERNAL SERVICE CONTRACTS

Some operations must not
be accessible from Flutter.

Examples:

- Notification delivery worker
- Payment reconciliation worker
- Scheduled cleanup
- Background content transformation
- Administrative maintenance jobs

## Authentication

Use approved service-to-service
authentication.

Do not use a public publishable key
as privileged service authorization.

## Security

- Restricted credentials.
- No browser exposure.
- Narrow permissions.
- Audit sensitive actions.
- Validate inputs and state.
- Use appropriate retries.

Service function names and
job scheduling require
separate implementation decisions.

---

# 63. IDEMPOTENCY CONTRACT

Use idempotency for
retry-sensitive mutations.

Examples:

create-checkout-order

initialize-online-payment

admin-review-bank-transfer

admin-grant-enrollment

## Header

Idempotency-Key:
<UNIQUE_KEY>

## Server Requirements

- Scope key to actor and operation.
- Validate request body consistency.
- Store request hash.
- Handle concurrent identical calls.
- Reuse safe previous result.
- Reject conflicting payload reuse.

## Conflict Response

HTTP 409

```json
{
  "error": {
    "code": "IDEMPOTENCY_CONFLICT",
    "message": "This request key was used with different input.",
    "request_id": "req_idem_001"
  }
}
```

## Payment Webhooks

Provider event IDs require
independent verified-event uniqueness.

A client idempotency key does not
replace provider webhook idempotency.

---

# 64. CONCURRENCY CONTRACT

Concurrent operations must not
corrupt authoritative state.

## Critical Operations

- Checkout creation
- Provider payment finalization
- Bank transfer review
- Enrollment grant
- Enrollment revocation
- Course publication/update

## Backend Responsibilities

- Validate expected current state.
- Use database transactions.
- Use row locks where appropriate.
- Enforce uniqueness.
- Reject conflicting transitions.
- Preserve audit history.

## Example

Two administrators attempt
to approve the same submission.

Expected:

- At most one authoritative finalization.
- No duplicate entitlement grant.
- No inconsistent financial state.
- Repeated identical request handled safely.
- Conflicting request rejected.

Frontend button disabling
is not a concurrency guarantee.

---

# 65. RETRY AND TIMEOUT POLICY

Retries must depend on
the operation's semantics.

## Safe Read Requests

May retry transient failures
with bounded backoff.

## Idempotent Writes

May retry using the same
validated idempotency key.

## Non-Idempotent Writes

Must not be blindly retried
without an approved recovery policy.

## Payment Provider Calls

Use provider-specific retry
and reconciliation guidance.

## UI Timeouts

A frontend timeout does not prove
the server operation failed.

Refresh the authoritative state
before offering a potentially
duplicate financial action.

## Rate Limits

A 429 response should trigger
approved retry/backoff behavior.

Respect Retry-After when supplied.

---

# 66. RATE LIMITING AND ABUSE CONTROLS

Protect:

- Registration-related requests
- Authentication-related flows
- Checkout creation
- Payment initialization
- Receipt upload authorization
- Public previews
- Content authorization
- Admin search
- Financial review endpoints

## Rules

- Apply reasonable limits.
- Protect server resources.
- Avoid unbounded input.
- Prevent enumeration.
- Do not expose secrets
  in rate-limit responses.

Specific limits must be
selected and measured.

Do not invent production limits
without operational evidence.

---

# 67. CACHING AND DATA PRIVACY

Different APIs need different
caching behavior.

## Public Catalog

Cache according to
publication freshness policy.

## Own Profile

Avoid shared/public caching.

## Orders

Use authoritative current
backend state after payments.

## Enrollments

Refresh after payment,
approval, revocation, or expiry.

## Protected Content

Avoid publicly cacheable
authorization responses.

## Sensitive Admin Data

Do not use shared public caches.

## Recommended Headers

For sensitive Edge Function JSON:

Cache-Control: no-store

Actual media cache behavior
must be reviewed separately.

## Important

Private browser-cached bytes
may remain after access revocation.

Never claim server controls can
erase already copied content.

---

# 68. LOGGING AND PRIVACY CONTRACT

Every important operation should
have a safe request identifier.

Log:

- Operation name
- Request ID
- Safe actor reference
- Safe resource reference
- Outcome
- Error category
- Timestamp

Avoid logging:

- Authentication tokens
- Payment provider secrets
- Webhook signing secrets
- Full signed download URLs
- Full signed upload tokens
- Complete bank receipt files
- Private lesson content

## Audit vs Diagnostic Logs

Audit logs:

Business and security events.

Diagnostic logs:

Operational troubleshooting.

Use appropriate access and
retention policies for each.

---

# 69. CORS AND BROWSER RULES

Flutter Web calls Edge Functions
from a browser.

Functions must support
configured CORS behavior.

## Requirements

- Handle preflight requests correctly.
- Allow approved application origins.
- Use appropriate supported headers.
- Do not expose credentials unnecessarily.
- Apply actual authentication checks.
- Return appropriate HTTP errors.

## Important

CORS only affects browser
cross-origin request behavior.

It does not prove identity
or authorize data access.

A malicious non-browser client
can send requests directly.

Backend authorization is mandatory.

---

# 70. FLUTTER DATA LAYER CONTRACT

Claude should implement typed
frontend interfaces matching
these approved contracts.

Recommended structure:

```text
lib/
  features/
    marketplace/
      domain/
        entities/
          course.dart
        repositories/
          course_repository.dart
      data/
        models/
          course_dto.dart
        repositories/
          supabase_course_repository.dart

    checkout/
      domain/
        entities/
          checkout_order.dart
        repositories/
          checkout_repository.dart
      data/
        models/
          checkout_order_dto.dart
        repositories/
          edge_checkout_repository.dart

    learning/
      domain/
        entities/
          authorized_content.dart
        repositories/
          learning_repository.dart
      data/
        models/
          content_descriptor_dto.dart
```

## Flutter Rules

- Parse known status values explicitly.
- Validate required response fields.
- Handle missing/unknown data safely.
- Keep financial status server-authoritative.
- Avoid exposing raw network errors.
- Use typed domain models.
- Separate DTOs from presentation state.

Do not embed hardcoded production
API responses inside UI widgets.

---

# 71. BACKEND IMPLEMENTATION CONTRACT

Codex should implement and validate
trusted Edge Function behavior.

Suggested structure:

```text
supabase/
  functions/
    _shared/
      auth/
      authorization/
      validation/
      responses/
      errors/
      payments/

    create-checkout-order/
    initialize-online-payment/
    payment-provider-webhook/

    get-bank-transfer-instructions/
    create-bank-receipt-upload/
    finalize-bank-receipt/
    get-bank-transfer-status/

    authorize-course-content/
    save-lesson-progress/

    admin-review-bank-transfer/
    admin-create-course/
    admin-update-course/
    admin-publish-course/

  migrations/
  tests/
```

Only create files for actual
approved implementation tasks.

## Backend Rules

- Validate authentication.
- Validate object authorization.
- Validate request schemas.
- Return stable response envelopes.
- Use safe error codes.
- Use transactions where necessary.
- Restrict privileged credentials.
- Test negative security behavior.

---

# 72. API CONTRACT FIXTURES

Maintain synthetic JSON fixtures
for agreed shared responses.

Recommended structure:

```text
test/
  fixtures/
    api/
      public_courses.json
      course_details.json
      curriculum.json
      checkout_created.json
      payment_pending.json
      payment_paid.json
      bank_submitted.json
      bank_approved.json
      bank_rejected.json
      enrollment_active.json
      enrollment_revoked.json
      protected_pdf.json
      api_errors.json

supabase/
  functions/
    tests/
      fixtures/
```

## Rules

- Use synthetic identities.
- Use synthetic financial data.
- Use placeholder bank accounts.
- Never commit real access tokens.
- Never commit real provider secrets.
- Keep fixtures synchronized with contracts.
- Review fixture changes across agents.

Fixtures are test inputs,
not evidence that production
integrations work.

---

# 73. CONTRACT TESTING REQUIREMENTS

Each critical API requires:

- Successful request test
- Invalid request test
- Authentication test
- Authorization test
- State transition test
- Error response test
- Idempotency test if applicable
- Concurrency test if applicable

## Test IDs

API-AUTH-001:
Unauthorized user rejected.

API-CAT-001:
Unpublished course excluded.

API-CHECK-001:
Trusted price determined by backend.

API-CHECK-002:
Duplicate checkout request safe.

API-PAY-001:
Forged webhook rejected.

API-PAY-002:
Duplicate webhook safe.

API-PAY-003:
Amount mismatch rejected.

API-BANK-001:
Receipt upload does not grant access.

API-BANK-002:
Unauthorized reviewer rejected.

API-BANK-003:
Concurrent review safe.

API-ENR-001:
Unpaid course access denied.

API-ENR-002:
Expired enrollment denied.

API-CONTENT-001:
Unauthorized PDF delivery denied.

API-CONTENT-002:
Authorized PDF delivery succeeds.

API-ADMIN-001:
Unauthorized role assignment rejected.

API-CONTRACT-001:
Flutter fixtures match approved
backend response structure.

## Important

Mock-based frontend tests are necessary
but insufficient to prove actual
backend payment and RLS security.

---

# 74. CLAUDE AND CODEX RESPONSIBILITIES

## CLAUDE - SUGGESTED

- Flutter domain models
- API DTO parsing
- Riverpod controllers
- UI error handling
- Loading states
- Payment status presentation
- PDF reader integration
- Widget tests
- Frontend contract tests

## CODEX - SUGGESTED

- Edge Function implementation
- Authentication enforcement
- RLS integration
- Request validation
- Provider webhook verification
- Payment transactions
- Bank approval operations
- Content authorization
- Backend contract tests

These are proposed assignments.

Actual ownership comes from
confirmed GitHub task records.

---

# 75. CONTRACT-FIRST PARALLEL WORKFLOW

Before implementing a paired
frontend/backend feature:

1. Identify the shared operation.
2. Approve request schema.
3. Approve response schema.
4. Approve authentication class.
5. Approve authorization rules.
6. Approve error codes.
7. Approve status behavior.
8. Approve idempotency rules.
9. Add contract fixtures.
10. Assign separate task owners.
11. Begin parallel implementation.
12. Run independent tests.
13. Run integrated contract tests.
14. Review and merge safely.

## Example

CLAUDE:

Implements checkout UI
using approved fixtures.

CODEX:

Implements checkout backend
using approved schemas.

Both agents may progress independently.

However, integration is incomplete
until real requests and responses
are verified together.

---

# 76. API CONTRACT CHANGE PROCEDURE

If an agent requires a contract change:

1. Create or update a GitHub Issue.
2. Explain the proposed change.
3. Identify affected operations.
4. Identify affected frontend modules.
5. Identify affected backend modules.
6. Assess compatibility.
7. Assess security implications.
8. Obtain review.
9. Update this document.
10. Update fixtures.
11. Update implementation.
12. Update automated tests.
13. Run integration checks.

## Breaking Changes

Examples:

- Renaming order_id
- Changing amount_minor to a string
- Removing a response field
- Changing payment status meaning
- Altering authorization requirements
- Changing delivery mode semantics

Do not implement breaking changes
silently during parallel development.

---

# 77. SHARED FILE OWNERSHIP

Contract-related shared files:

docs/API_CONTRACTS.md

docs/api-contracts/**

Shared Dart DTOs

Shared API fixtures

Shared TypeScript schemas

Shared database enums/status definitions

## Rules

- One designated owner per
  conflicting shared change.
- Record changes in GitHub.
- Notify dependent task owners.
- Avoid simultaneous edits.
- Review contract modifications.
- Verify both implementations.

Do not overwrite another
agent's unmerged contract work.

---

# 78. INTEGRATION GATES

## GATE A - Public Catalog

- Public listing works.
- Draft data protected.
- Public curriculum safe.
- Pagination verified.

## GATE B - Authentication

- User session verified.
- Own profile protected.
- Cross-user access denied.
- Admin role escalation blocked.

## GATE C - Checkout

- Trusted order creation.
- Backend price validation.
- Payment initialization.
- Safe retry behavior.

## GATE D - Online Payments

- Provider authentication.
- Amount/currency verification.
- Idempotent finalization.
- Transactional enrollment grant.
- Negative security tests.

## GATE E - Bank Transfers

- Private upload.
- Pending state.
- Authorized finance review.
- Bank verification workflow.
- Atomic approval.
- Rejection behavior.

## GATE F - Learning

- Valid enrollment required.
- Private PDF delivery.
- Protected video access.
- Learning progress persistence.

## GATE G - Administration

- RBAC verification.
- Secure course publishing.
- Authorized enrollment management.
- Audited financial actions.

An integrated feature must not
be accepted solely because
its frontend screens render.

---

# 79. OPEN API DECISIONS

API-OPEN-001:
Payment gateway protocol.

API-OPEN-002:
Supported production currency.

API-OPEN-003:
Checkout session lifetime.

API-OPEN-004:
Payment reconciliation interface.

API-OPEN-005:
Bank upload delivery mode.

API-OPEN-006:
Receipt content-scanning policy.

API-OPEN-007:
Bank receipt size limits.

API-OPEN-008:
Bank resubmission rules.

API-OPEN-009:
Course access duration.

API-OPEN-010:
Refund authorization and state changes.

API-OPEN-011:
Protected PDF delivery mode.

API-OPEN-012:
Server-side watermark generation.

API-OPEN-013:
Protected video provider contract.

API-OPEN-014:
Learning progress mutation approach.

API-OPEN-015:
Admin role permission matrix.

API-OPEN-016:
API pagination conventions.

API-OPEN-017:
Approved rate limits.

API-OPEN-018:
Public lesson preview rules.

API-OPEN-019:
Multi-currency reporting policy.

API-OPEN-020:
Contract versioning and compatibility policy.

These decisions must be resolved
before dependent production behavior
is considered approved.

---

# 80. IMPLEMENTATION ORDER

Recommended contract implementation order:

Stage 1:
Approve canonical data types
and error envelopes.

Stage 2:
Implement public course reads.

Stage 3:
Implement authenticated profile access.

Stage 4:
Implement order read contract.

Stage 5:
Implement trusted checkout creation.

Stage 6:
Implement online payment initialization.

Stage 7:
Implement verified provider webhook.

Stage 8:
Implement bank receipt submission.

Stage 9:
Implement bank approval workflow.

Stage 10:
Implement enrollment reads/grants.

Stage 11:
Implement protected content authorization.

Stage 12:
Implement learning progress operations.

Stage 13:
Implement admin content management.

Stage 14:
Implement admin reporting and role operations.

Stage 15:
Run complete contract and integration tests.

Frontend UI implementation may
proceed earlier against approved
synthetic fixtures.

Security-sensitive backend
dependencies must not be skipped.

---

# 81. API DEFINITION OF READY

An API implementation task is READY when:

- [ ] Operation name approved.
- [ ] Authentication class defined.
- [ ] Authorization rules defined.
- [ ] Request schema approved.
- [ ] Response schema approved.
- [ ] Error codes defined.
- [ ] Business state transitions defined.
- [ ] Idempotency policy established.
- [ ] Database dependencies reviewed.
- [ ] Security tests identified.
- [ ] Task ownership confirmed.
- [ ] Shared files coordinated.

---

# 82. API DEFINITION OF DONE

An API implementation is DONE only when:

- [ ] Endpoint or RLS operation implemented.
- [ ] Input validation tested.
- [ ] Authentication enforced.
- [ ] Authorization enforced.
- [ ] Response matches contract.
- [ ] Error codes match contract.
- [ ] Status values match contract.
- [ ] Relevant idempotency tested.
- [ ] Concurrency tested if applicable.
- [ ] Database security verified.
- [ ] Secrets remain protected.
- [ ] Flutter integration tested.
- [ ] Backend tests pass.
- [ ] CI checks pass.
- [ ] Documentation updated.
- [ ] Required review complete.
- [ ] Changes merged or formally accepted.
- [ ] Completion evidence recorded.

Generating an Edge Function
does not prove its correctness.

Generating a Flutter API client
does not prove backend integration.

---

# 83. FINAL API CONTRACT DIRECTIVE

Acedra uses contract-first development.

CLAUDE and CODEX must implement
against one consistent set of
approved API definitions.

The frontend is responsible for:

- Presentation
- Navigation
- Input collection
- Client state
- Error presentation
- Authorized content rendering

The backend is responsible for:

- Authentication verification
- Trusted permissions
- Financial validation
- Payment verification
- Bank approval
- Enrollment grants
- Protected content authorization
- Auditable business mutations

The database is responsible for:

- Data integrity
- Constraints
- Row-level access control
- Transactional consistency
- Idempotent financial state

No student may:

- Mark an order paid directly.
- Approve a bank receipt.
- Grant their own enrollment.
- Assign an admin role.
- Access another student's financial data.
- Read paid content without authorization.

Both agents must:

- Respect confirmed task ownership.
- Use isolated workspaces.
- Follow approved contracts.
- Avoid silent breaking changes.
- Implement meaningful tests.
- Submit reviewable pull requests.
- Verify integrated behavior.
- Report accurate results.

ONE CONTRACT.
TWO INDEPENDENT AGENTS.
EXPLICIT AUTHENTICATION.
BACKEND AUTHORIZATION.
TRUSTED FINANCIAL STATE.
PROTECTED LEARNING CONTENT.
STABLE DATA TYPES.
CONSISTENT ERROR CODES.
CONTROLLED API EVOLUTION.
TEST BEFORE MERGE.
SECURITY BEFORE SPEED.

END OF API_CONTRACTS.md

# CSA158/164/165/168/172 implementation addendum (2026-10-12)

Issue106, coordinated development implementation IN_REVIEW. Endpoint examples
in sections47,54,55,57,58,60 must defer to these concrete task contracts:
- [Reporting158/172](contracts/CSA-158-172-REPORTING.md): permission-filtered current
  counts and confirmed settlement facts, exact decimal strings, approved Colombo
  receipt reporting basis. Confirmed refund/net totals remain unavailable until a
  trusted adjustment ledger exists; absence is never presented as zero.
- [Media164](handoffs/CSA-164-MEDIA-UPLOAD.md): course PDF/thumbnail limits approved,
  private preparation/finalization and trusted inspection before readiness. Production
  inspector is not configured; video upload integration deferred.
- [Publication165](contracts/CSA-165-PUBLICATION.md): ONLY current MFA super admins
  publish/unpublish. Content-manager authoring authority does not permit publishing.
- [Enrollment168](contracts/CSA-168-ENROLLMENT-ADMIN.md): canonical audited mutations
  remain admin-entitlements (grant/source/course/account/release); bounded
  admin-enrollments provides safe views. Legacy separate grant/revoke examples
  are superseded; no unaudited duplicate mutation endpoints introduced.

All new entrypoints retain code-level release gates. Development integration and
owner metric/file-limit approvals do not authorize deployment/production activation.
See [coordination and evidence](tasks/CSA-158-164-165-168-172-INTEGRATION.md).
