
# TESTING.md
# Acedra - Software Testing & Quality Assurance Standards

Document ID: CSA-TEST-001
Version: 1.0
Status: Proposed - Pending Approval
Project: Acedra Course Selling Application
Project Type: Commercial E-Learning Platform

Primary Platform: Flutter Web
Future Platforms: Android and iOS
Frontend: Flutter + Dart
State Management: Riverpod
Navigation: go_router
Backend: Supabase
Database: PostgreSQL
Authentication: Supabase Auth
Authorization: PostgreSQL RLS
Backend Functions: Supabase Edge Functions

Development Model:
Claude Code + OpenAI Codex

Testing Methodology:
Risk-Based Testing + TDD + Continuous Integration

Test Frameworks:
- flutter_test
- integration_test
- pgTAP
- Deno Test
- Approved Browser Testing Tools

Test Coordination:
GitHub Issues + Pull Requests + GitHub Actions

Classification:
Internal Engineering Documentation

---

# 1. PURPOSE

This document defines the testing
strategy and quality assurance
requirements for Acedra.

Acedra is a commercial application
that sells digital courses and delivers
paid learning content.

The system handles:

- Student identities
- Authentication
- Course discovery
- Financial transactions
- Bank transfer evidence
- Paid enrollments
- Private learning documents
- Student learning progress
- Administrative operations

Testing must protect:

1. Financial correctness
2. Student privacy
3. Authorization integrity
4. Course content access
5. Application reliability
6. User experience
7. Accessibility
8. Performance
9. Maintainability
10. Production stability

Claude and Codex may develop
and test different modules
simultaneously.

All test results must represent
actual executed verification.

---

# 2. DOCUMENT AUTHORITY

Follow applicable rules in:

AGENTS.md
PLAN.md
TASKS.md
SRS.md
ARCHITECTURE.md
DATABASE_DESIGN.md
DESIGN_SYSTEM.md
SECURITY.md
CONTRIBUTING.md
docs/PARALLEL_WORKFLOW.md
docs/API_CONTRACTS.md

This document defines testing practices.

SRS.md defines required behavior.

SECURITY.md defines security expectations.

DATABASE_DESIGN.md defines data integrity.

ARCHITECTURE.md defines system boundaries.

TASKS.md identifies implementation owners.

Do not treat proposed test plans
as evidence of passing tests.

---

# 3. QUALITY ASSURANCE PRINCIPLES

The following principles are mandatory.

QA-001:
Test observable behavior.

QA-002:
Test security boundaries.

QA-003:
Test both successful and failing paths.

QA-004:
Test financial state transitions.

QA-005:
Test unauthorized operations.

QA-006:
Prefer deterministic tests.

QA-007:
Use synthetic data.

QA-008:
Automate repeatable verification.

QA-009:
Keep test environments isolated.

QA-010:
Preserve regression coverage.

QA-011:
Never manipulate results.

QA-012:
Do not accept critical failures.

QA-013:
Verify integrated functionality.

QA-014:
Report limitations honestly.

QA-015:
Security takes priority over speed.

---

# 4. TEST STATUS DEFINITIONS

Every test must have a clear status.

NOT_IMPLEMENTED:
Test does not exist yet.

READY:
Test exists but has not been executed
against the current target revision.

RUNNING:
Test execution is in progress.

PASSED:
Test executed successfully against
the documented code and environment.

FAILED:
Test executed and its expected
assertions were not satisfied.

BLOCKED:
Test cannot run because a
prerequisite is missing.

SKIPPED:
Test was intentionally not executed
and the reason is recorded.

FLAKY:
Test has demonstrated unstable results
that require investigation.

## Important

Do not mark tests PASSED merely because:

- Test code was generated.
- A mock returned success.
- A previous unrelated build passed.
- The UI appears correct.
- An AI agent predicts success.

Every passing result must be backed
by actual execution evidence.

---

# 5. RISK-BASED TESTING

Testing effort must correspond
to business and technical risk.

## P0 - CRITICAL

Examples:

- Payment verification
- Bank transfer approvals
- Enrollment grants
- RLS policies
- Administrator role escalation
- Private receipt access
- Protected course authorization

Requirements:

- Unit tests where applicable
- Integration tests
- Negative security tests
- Concurrency tests where relevant
- Regression coverage
- Authorized review

No unresolved P0 defect
may be accepted for production.

## P1 - HIGH

Examples:

- Authentication
- Checkout UI
- Course management
- Learning workspace
- PDF reader
- Video playback

Requirements:

- Relevant unit/widget tests
- Integration tests
- Error-path tests
- Accessibility verification
- Responsive testing where applicable

## P2 - MEDIUM

Examples:

- Bookmarks
- UI refinements
- Noncritical analytics
- Convenience features

Requirements:

- Appropriate functional tests
- Regression tests for significant behavior

## P3 - LOW

Examples:

- Minor visual adjustments
- Future enhancements

Requirements:

- Risk-appropriate verification

Low priority does not excuse
introduced security regressions.

---

# 6. TESTING PYRAMID

Acedra uses multiple testing layers.

Conceptual structure:

                   /\
                  /  \
                 / E2E\
                /------\
               /Integrated\
              /------------\
             / Widget + API \
            /----------------\
           / Unit + Database   \
          /_____________________\

Broad coverage should come
from fast deterministic tests.

Critical end-to-end journeys
must also be verified against
integrated application components.

## Layers

L1:
Static analysis and formatting.

L2:
Unit and widget tests.

L3:
Database and Edge Function tests.

L4:
Integration and contract tests.

L5:
End-to-end user journeys.

L6:
Security, performance, accessibility,
and recovery verification.

These categories overlap where
cross-cutting tests are appropriate.

---

# 7. TOOLING BASELINE

## Flutter

flutter_test:
Unit and widget testing.

integration_test:
Application integration testing.

Flutter Analyzer:
Static analysis.

Dart Formatter:
Formatting verification.

## Supabase

Supabase CLI:
Local service and migration testing.

pgTAP:
Database schema and policy tests.

## Backend

Deno Test:
Edge Function unit testing.

Approved integration harness:
Edge Function and provider workflows.

## Automation

GitHub Actions:
Continuous integration.

## Optional Tools

Approved browser automation:
Full browser workflows.

Approved accessibility tooling:
Semantic and interaction evaluation.

Approved load-testing tools:
Performance and concurrency testing.

Optional tools require actual
installation and configuration.

Do not invent tool availability.

---

# 8. RECOMMENDED TEST DIRECTORY STRUCTURE

Target layout:

test/
  unit/
    authentication/
    marketplace/
    checkout/
    payments/
    enrollments/
    learning/
    pdf_reader/
    admin/

  widget/
    authentication/
    marketplace/
    checkout/
    learning/
    pdf_reader/
    admin/
    shared/

  fixtures/
    users/
    courses/
    orders/
    enrollments/

  helpers/
    test_app.dart
    fake_repositories.dart
    test_data.dart

integration_test/
  authentication/
  marketplace/
  checkout/
  learning/
  administration/

test_driver/
  integration_test.dart

supabase/
  tests/
    database/
      identity/
      courses/
      payments/
      bank_transfers/
      enrollments/
      learning/
      security/

  functions/
    tests/
      checkout/
      payment_webhook/
      bank_transfers/
      content_access/

docs/
  testing/
    test-cases/
    test-reports/
    performance/
    release-evidence/

Create directories only when
required by actual tests.

The structure above is proposed,
not proof that the files exist.

---

# 9. TEST NAMING CONVENTIONS

Use descriptive names.

## Dart Test Files

<feature>_test.dart

<feature>_widget_test.dart

Examples:

course_repository_test.dart

checkout_controller_test.dart

course_card_widget_test.dart

pdf_toolbar_widget_test.dart

## Database Tests

<feature>_test.sql

Examples:

profiles_rls_test.sql

orders_constraints_test.sql

payment_idempotency_test.sql

enrollment_access_test.sql

## Edge Function Tests

<feature>.test.ts

Examples:

checkout.test.ts

webhook_signature.test.ts

bank_approval.test.ts

## Test Case IDs

Use:

TST-<AREA>-<NUMBER>

Examples:

TST-AUTH-001

TST-PAY-001

TST-BANK-001

TST-RLS-001

TST-PDF-001

TST-E2E-001

Test IDs must be unique.

Do not reuse IDs for
different scenarios.

---

# 10. TEST CASE SPECIFICATION

Each significant test case should contain:

Test ID:
Title:
Priority:
Related Requirement:
Related Task:
Test Layer:
Preconditions:
Test Data:
Execution Steps:
Expected Result:
Negative Expectations:
Environment:
Automation Status:
Latest Result:
Evidence:

Example:

Test ID:
TST-PAY-003

Title:
Reject Forged Payment Callback

Priority:
P0

Related Task:
CSA-120

Test Layer:
Backend Integration

Preconditions:
Checkout exists with unpaid order.

Execution:
Send a callback with an
invalid provider signature.

Expected:
Request is rejected.

Negative Expectations:
- Order does not become paid.
- Enrollment is not granted.
- Verified event is not recorded
  as successfully authenticated.

Status:
NOT_IMPLEMENTED

---

# 11. REQUIREMENT TRACEABILITY

Every critical requirement must map to:

Requirement
    |
    v
Implementation Task
    |
    v
Test Case
    |
    v
Execution Result
    |
    v
Release Evidence

## Requirement Mapping

Authentication:

FR-AUTH-*
FR-PROFILE-*

Marketplace:

FR-CAT-*
FR-COURSE-*

Commerce:

FR-CHECKOUT-*
FR-PAY-*
FR-BANK-*
FR-ENROLL-*

Learning:

FR-LEARN-*
FR-VIDEO-*
FR-TEXT-*
FR-IMAGE-*
FR-PDF-*
FR-PDF-SEC-*

Administration:

FR-ADMIN-*
FR-STUDENT-*
FR-APAY-*

Notifications:

FR-NOTIFY-*

Also trace tests to the
applicable SRS acceptance tests:

AT-001 through AT-014.

The exact requirement-to-test map
must be completed after SRS approval.

Do not claim requirements are covered
solely because a broad test suite exists.

---

# 12. TEST-DRIVEN DEVELOPMENT

Use TDD for testable business behavior.

Process:

RED
  |
  v
GREEN
  |
  v
REFACTOR
  |
  v
VERIFY

## RED

Write a meaningful failing test
for the required behavior.

## GREEN

Implement the smallest correct
change that passes the test.

## REFACTOR

Improve the implementation while
preserving observable behavior.

## VERIFY

Run affected tests again.

TDD is especially important for:

- Financial state transitions
- Price validation
- Payment idempotency
- Enrollment authorization
- Bank transfer approval
- Role permissions
- Data integrity
- Error handling

Do not weaken assertions
to force a passing result.

---

# 13. UNIT TESTING STRATEGY

Unit tests verify isolated behavior.

Examples:

- Course price formatting
- Validation rules
- Order status mapping
- Repository response mapping
- Enrollment state presentation
- Pagination logic
- Progress calculations
- Form validation
- Application error translation

Unit tests should:

- Execute quickly.
- Avoid real network calls.
- Avoid production services.
- Be deterministic.
- Use controlled dependencies.
- Test edge cases.

## Recommended Cases

Null and missing data.

Invalid user input.

Boundary numbers.

Unexpected statuses.

Empty collections.

Malformed API responses.

Cancellation and error states.

Unit tests do not replace
real backend security tests.

---

# 14. FLUTTER WIDGET TESTING

Widget tests verify UI components.

Examples:

- Buttons
- Form inputs
- Course cards
- Navigation elements
- Status indicators
- Dialogs
- PDF toolbar
- Admin table components

## Required Checks

- Correct content displayed
- Correct interaction behavior
- Disabled states
- Loading states
- Error states
- Empty states
- Accessible labels
- Theme compatibility
- Appropriate layout behavior

## Example Test Cases

TST-UI-001:
Course card renders title and price.

TST-UI-002:
Course card handles missing thumbnail.

TST-UI-003:
Login form displays validation error.

TST-UI-004:
Loading button prevents repeated action.

TST-UI-005:
Checkout displays pending payment state.

TST-UI-006:
PDF toolbar updates page navigation.

TST-UI-007:
Admin review button is disabled
during an in-flight request.

Status:
NOT_IMPLEMENTED

---

# 15. RIVERPOD STATE TESTING

Test provider/controller behavior.

Important scenarios:

- Initial state
- Loading state
- Successful response
- Empty response
- Network failure
- Authorization failure
- Retry behavior
- State invalidation
- Logout cleanup
- Cancellation behavior

## Example

Checkout controller:

1. Starts idle.
2. Receives checkout request.
3. Enters loading state.
4. Receives server response.
5. Displays pending checkout.
6. Handles backend failure.
7. Prevents unsafe duplicate submission.

## Rules

Mock repository boundaries,
not trusted backend security invariants.

Do not test a fake payment success
as if it were real financial verification.

---

# 16. REPOSITORY TESTING

Repositories translate between
application models and data sources.

Test:

- Correct request construction
- Correct response parsing
- Null handling
- Date conversion
- Money representation
- Server error conversion
- Network failure behavior
- Unauthorized response handling

## Important

API responses must match
docs/API_CONTRACTS.md.

Do not create separate incompatible
frontend and backend status models.

Use explicit mapping when database
statuses and UI labels differ.

---

# 17. AUTHENTICATION TESTING

Authentication is P1 functionality
with P0 security implications.

## Test Cases

TST-AUTH-001:
Valid registration.

TST-AUTH-002:
Invalid registration input rejected.

TST-AUTH-003:
Duplicate account behavior handled.

TST-AUTH-004:
Email verification flow.

TST-AUTH-005:
Valid login.

TST-AUTH-006:
Invalid credentials rejected.

TST-AUTH-007:
Password recovery.

TST-AUTH-008:
Logout clears authenticated UI state.

TST-AUTH-009:
Expired session handled safely.

TST-AUTH-010:
Protected route requires login.

TST-AUTH-011:
Student cannot modify another profile.

TST-AUTH-012:
Student cannot assign admin role.

TST-AUTH-013:
Malformed or expired credentials
are rejected by backend operations.

TST-AUTH-014:
Session change invalidates
sensitive cached UI state.

## Security Requirement

A protected frontend route
is not an authorization test.

Direct unauthorized API requests
must also be tested.

---

# 18. COURSE MARKETPLACE TESTING

## Test Cases

TST-CAT-001:
Published courses appear.

TST-CAT-002:
Draft courses do not appear publicly.

TST-CAT-003:
Archived course visibility
follows approved policy.

TST-CAT-004:
Category filtering returns
appropriate results.

TST-CAT-005:
Search handles no results.

TST-CAT-006:
Search handles special characters safely.

TST-CAT-007:
Course detail page renders.

TST-CAT-008:
Curriculum preview excludes
protected lesson content.

TST-CAT-009:
Pagination remains consistent.

TST-CAT-010:
Price and currency display correctly.

TST-CAT-011:
An already-enrolled student sees
the correct learning action.

TST-CAT-012:
Malformed course identifiers
do not expose internal errors.

## Critical

The browser must not receive
private lesson assets through
public marketplace responses.

---

# 19. CHECKOUT TESTING

Checkout is a critical boundary
between the frontend and backend.

## Test Cases

TST-CHECK-001:
Student selects a valid course.

TST-CHECK-002:
Unauthenticated checkout
requires authentication.

TST-CHECK-003:
Backend rejects an unpublished course.

TST-CHECK-004:
Backend determines the trusted price.

TST-CHECK-005:
Client-modified amount is ignored
or rejected safely.

TST-CHECK-006:
Client-modified currency is rejected.

TST-CHECK-007:
Duplicate checkout requests
follow the idempotency policy.

TST-CHECK-008:
Already-enrolled user follows
approved repurchase policy.

TST-CHECK-009:
Invalid payment method rejected.

TST-CHECK-010:
Gateway initialization failure
does not mark an order paid.

TST-CHECK-011:
Frontend handles checkout timeout.

TST-CHECK-012:
Retry does not create
unintended duplicate purchases.

## Required Invariant

Checkout initialization
must not grant course access.

---

# 20. ONLINE PAYMENT SECURITY TESTING

Payment security is P0.

Test the trusted backend
against realistic provider behavior.

## Test Cases

TST-PAY-001:
Valid authenticated provider event
finalizes the correct order.

TST-PAY-002:
Invalid signature rejected.

TST-PAY-003:
Forged payment callback rejected.

TST-PAY-004:
Incorrect order identifier rejected.

TST-PAY-005:
Incorrect amount rejected.

TST-PAY-006:
Incorrect currency rejected.

TST-PAY-007:
Duplicate event does not
duplicate enrollment.

TST-PAY-008:
Concurrent duplicate callbacks
preserve one correct final state.

TST-PAY-009:
Failed payment does not unlock course.

TST-PAY-010:
Pending payment does not unlock course.

TST-PAY-011:
Cancelled payment does not unlock course.

TST-PAY-012:
Old failure event cannot
downgrade an already paid order.

TST-PAY-013:
Unknown transaction reference rejected.

TST-PAY-014:
Verified event belongs to
the expected payment attempt.

TST-PAY-015:
Webhook replay protections
work according to provider rules.

TST-PAY-016:
Network interruption between
provider and backend is recoverable.

TST-PAY-017:
Database failure rolls back
incomplete financial changes.

TST-PAY-018:
Successful verified payment creates
the intended entitlement.

TST-PAY-019:
Amount snapshot is preserved
after later course price changes.

TST-PAY-020:
Refund follows approved
entitlement revocation policy.

## Critical Invariants

- Unverified payment cannot grant access.
- Event duplication cannot duplicate grants.
- A student cannot directly mark an order paid.
- Trusted amount and currency must match.
- Financial finalization must be atomic.
- Every accepted provider event
  must have an auditable origin.

---

# 21. PAYMENT WEBHOOK TESTING

Payment webhooks may arrive without
a Supabase user JWT.

Provider authentication is separate
from student authentication.

## Authentication Tests

- Invalid cryptographic signature
- Missing required signature
- Invalid signing secret
- Malformed raw request
- Unsupported event type
- Invalid timestamp or replay window
  where the provider supports it

## State Tests

- Duplicate event ID
- Distinct events for same payment
- Out-of-order success/failure events
- Unknown payment attempt
- Amount mismatch
- Currency mismatch
- Repeated settlement
- Already-finalized order

## Concurrency Tests

Send overlapping authorized requests.

Verify:

- One consistent order state
- One intended enrollment
- No duplicate funding grant
- Correct audit records
- No partially committed state

## Important Security Test

An unauthenticated forged event
must not reserve a verified event ID
and block later legitimate processing.

Verify provider authenticity
before recording the event
as authenticated.

---

# 22. BANK TRANSFER TESTING

Bank transfers require independent
financial verification.

A receipt alone is not proof
that money has arrived.

## Test Cases

TST-BANK-001:
Student views official bank details.

TST-BANK-002:
Student uploads a valid receipt.

TST-BANK-003:
Unsupported file type rejected.

TST-BANK-004:
Oversized receipt rejected.

TST-BANK-005:
Receipt ownership verified.

TST-BANK-006:
Receipt submission stays pending.

TST-BANK-007:
Pending receipt does not
unlock the course.

TST-BANK-008:
Unauthorized approval rejected.

TST-BANK-009:
Finance administrator can review
an authorized receipt.

TST-BANK-010:
Approval requires the approved
bank-credit verification workflow.

TST-BANK-011:
Rejected receipt does not
grant enrollment.

TST-BANK-012:
Approved verified receipt
grants the intended enrollment.

TST-BANK-013:
Duplicate approval request
is idempotent or safely rejected.

TST-BANK-014:
Concurrent approvals do not
create conflicting outcomes.

TST-BANK-015:
Resubmission preserves original
receipt and review history.

TST-BANK-016:
Student cannot read another
student's bank receipt.

TST-BANK-017:
Content manager cannot approve
without finance permission.

TST-BANK-018:
Finance reviewer cannot approve
their own purchase when prohibited.

TST-BANK-019:
Verified settlement reference
cannot fund multiple orders
under the approved uniqueness policy.

TST-BANK-020:
Approval and enrollment grant
are committed atomically.

## Important

Bank verification itself may
require an authorized human decision.

Automated tests should verify
the surrounding authorization,
validation, state transitions,
and accounting invariants.

Do not automate fake approval
of real customer transactions.

---

# 23. ENROLLMENT TESTING

Enrollments determine access
to paid content.

## Test Cases

TST-ENR-001:
Verified payment grants enrollment.

TST-ENR-002:
Pending payment grants no enrollment.

TST-ENR-003:
Rejected bank transfer grants no enrollment.

TST-ENR-004:
Student cannot insert active enrollment.

TST-ENR-005:
Student cannot edit enrollment status.

TST-ENR-006:
Student cannot extend access expiration.

TST-ENR-007:
Student cannot read another
student's enrollment.

TST-ENR-008:
Active entitlement grants
appropriate course access.

TST-ENR-009:
Expired entitlement denies access.

TST-ENR-010:
Revoked entitlement denies access.

TST-ENR-011:
Admin grant requires current
authorized permissions.

TST-ENR-012:
Duplicate verified purchase events
do not produce duplicate grants.

TST-ENR-013:
Reactivation follows approved policy.

TST-ENR-014:
Refund behavior follows
approved business requirements.

TST-ENR-015:
Failed enrollment transaction
does not leave a falsely paid,
inconsistent business state.

## Access Check

Never rely solely on the
status field being "active".

Also evaluate expiration
and applicable revocation state.

---

# 24. DATABASE TESTING

Database testing is P0-sensitive.

Use pgTAP and suitable
integration tests.

## Test Categories

- Schema existence
- Required columns
- Data types
- Primary keys
- Foreign keys
- Check constraints
- Unique constraints
- Index definitions
- Default values
- Triggers and functions
- RLS policies
- Grants
- Business state transitions
- Transactional behavior

## Example Scenarios

TST-DB-001:
Required tables exist.

TST-DB-002:
Order amounts cannot be negative.

TST-DB-003:
Invalid currency rejected.

TST-DB-004:
Order ownership foreign key valid.

TST-DB-005:
Duplicate current enrollment rejected.

TST-DB-006:
Duplicate verified provider event
rejected by uniqueness constraint.

TST-DB-007:
Invalid lesson type rejected.

TST-DB-008:
Invalid order state rejected.

TST-DB-009:
Financial grants enforce
approved source uniqueness.

TST-DB-010:
Migration sequence applies cleanly.

TST-DB-011:
Database permissions match
the approved access matrix.

TST-DB-012:
Privileged functions have
restricted EXECUTE permissions.

---

# 25. ROW LEVEL SECURITY TESTING

RLS tests must verify effective
access using realistic caller contexts.

Do not test every operation
only through privileged credentials.

## RLS Role Matrix

Guest:

- Read published course metadata.
- Cannot read private profiles.
- Cannot read private orders.
- Cannot read paid lesson content.
- Cannot upload bank receipts
  as an anonymous user.

Student A:

- Read own profile.
- Read own orders.
- Read own enrollments.
- Read/write permitted own progress.
- Cannot read Student B's records.

Student B:

- Cannot access Student A's profile.
- Cannot access Student A's orders.
- Cannot access Student A's receipts.
- Cannot access Student A's progress.

Content Manager:

- Manage only authorized courses.
- Cannot approve bank payments
  solely through content permission.
- Cannot assign super-admin roles.

Finance Admin:

- Review authorized payments.
- Cannot modify unrelated course content
  solely through finance permission.
- Cannot bypass trusted review logic.

Super Admin:

- May perform approved operations.
- Privileged changes remain auditable.

## Required Test IDs

TST-RLS-001:
Anonymous private profile read denied.

TST-RLS-002:
Cross-student profile read denied.

TST-RLS-003:
Cross-student order read denied.

TST-RLS-004:
Direct payment update denied.

TST-RLS-005:
Direct enrollment activation denied.

TST-RLS-006:
Direct role assignment denied.

TST-RLS-007:
Unpublished course access denied.

TST-RLS-008:
Paid lesson content denied
without entitlement.

TST-RLS-009:
Unauthorized finance operation denied.

TST-RLS-010:
Unauthorized course editing denied.

TST-RLS-011:
Function EXECUTE grants restricted.

TST-RLS-012:
Security-definer function
cannot be misused by students.

## Test Implementation Warning

SQL tests must correctly simulate
the intended PostgreSQL role
and authenticated user identity.

Also test selected cases
through actual Supabase client requests.

A passing test running as an
administrative database role
does not prove RLS works for students.

---

# 26. SUPABASE EDGE FUNCTION TESTING

Edge Functions contain trusted
backend business logic.

Use Deno tests for appropriate
unit and integration behavior.

## Unit Tests

Test pure functions:

- Input validation
- Provider event parsing
- Currency comparisons
- Business state mapping
- Error classification
- Request normalization

## Integration Tests

Test:

- HTTP methods
- Authentication
- Authorization
- Request validation
- Database error handling
- Response structure
- Idempotency behavior
- Provider authentication
- Secret handling
- CORS behavior as configured

## Required Error Cases

- Missing authentication
- Expired authentication
- Invalid JSON
- Unsupported content type
- Missing required field
- Invalid object identifier
- Forbidden resource
- Rate-limited request
- Backend timeout
- Provider failure
- Unexpected internal exception

Do not expose stack traces
or privileged error details
to browser clients.

---

# 27. API CONTRACT TESTING

Claude and Codex develop
against shared API contracts.

Contract tests must verify:

- Operation name
- HTTP method
- Request body
- Response body
- Authentication requirements
- Authorization requirements
- Error codes
- Data types
- Status values
- Version compatibility

## Example

Operation:

create-checkout-order

Expected Request:

course_id
payment_method

Expected Response:

order_id
order_status
checkout_information

## Security Contract

The request must not control
the authoritative course price.

The backend must validate
the actual published course.

## Contract Changes

If Codex changes an API contract:

- Update the approved contract.
- Notify the dependent Claude task.
- Update backend tests.
- Update frontend model tests.
- Verify integration.

The same process applies
to changes proposed by Claude.

Do not silently break
the other agent's implementation.

---

# 28. TEST DOUBLES AND MOCKS

Use mocks and fakes only
at appropriate boundaries.

## Good Uses

- Repository unit tests
- Widget rendering
- Simulated network errors
- Simulated loading states
- API contract fixture testing
- Deterministic time behavior
- Controlled payment provider responses

## Insufficient Uses

Mock-only tests are not adequate
to prove:

- RLS enforcement
- Payment authenticity
- Database transaction atomicity
- Private storage permissions
- Actual webhook behavior
- End-to-end enrollment security

## Rules

- Keep fixtures realistic.
- Match approved API contracts.
- Do not invent production states.
- Validate against real integrations.
- Label simulated responses clearly.

Mocked success is not
verified backend success.

---

# 29. PRIVATE STORAGE TESTING

Protected assets include:

- Paid PDFs
- Paid lesson images
- Bank receipts
- Protected resources

## Test Cases

TST-STO-001:
Anonymous private object read denied.

TST-STO-002:
Unpaid student PDF read denied.

TST-STO-003:
Paid student authorized PDF delivery.

TST-STO-004:
Revoked student new access denied.

TST-STO-005:
Cross-student bank receipt access denied.

TST-STO-006:
Unauthorized bucket listing denied.

TST-STO-007:
Unauthorized asset deletion denied.

TST-STO-008:
Invalid upload path rejected.

TST-STO-009:
Expired signed URL no longer
authorizes a new applicable request.

TST-STO-010:
Backend validates entitlement
before issuing private access.

## Important

A signed URL may permit access
until expiration.

Already downloaded bytes may
remain available to the user.

Tests must not assume the browser
can erase previously received content.

---

# 30. PDF READER TESTING

The PDF reader is a central
learning feature.

Test:

- PDF loading
- Page navigation
- Zoom
- Fit-to-width
- Scrolling
- Reading progress
- Reader toolbar
- Large documents
- Mobile layouts
- Desktop layouts
- Error handling
- Authorized access

## Test Cases

TST-PDF-001:
Valid authorized PDF opens.

TST-PDF-002:
Invalid PDF displays safe error.

TST-PDF-003:
Page forward works.

TST-PDF-004:
Page backward works.

TST-PDF-005:
Invalid page input is handled.

TST-PDF-006:
Zoom in works.

TST-PDF-007:
Zoom out works.

TST-PDF-008:
Fit-to-width works.

TST-PDF-009:
Reading position persists.

TST-PDF-010:
Large document navigation remains usable.

TST-PDF-011:
Narrow screen layout works.

TST-PDF-012:
Desktop reader layout works.

TST-PDF-013:
Expired authorization is handled.

TST-PDF-014:
Unauthorized PDF access denied
by the delivery backend.

TST-PDF-015:
Relevant watermark behavior
matches the approved threat model.

TST-PDF-016:
PDF toolbar supports keyboard navigation.

TST-PDF-017:
Loading and retry behavior works.

## PDF Library Evaluation

Candidate:

pdfrx

Status:
Pending actual compatibility testing.

Evaluate:

- Flutter Web support
- Large file behavior
- Zoom performance
- Text clarity
- Keyboard accessibility
- Mobile scrolling
- Private data delivery compatibility
- Memory consumption
- Supported browsers

Do not assume a library meets
requirements without executing tests.

---

# 31. PDF SECURITY TESTING

Security tests must focus
on achievable controls.

Verify:

- Private storage
- Current entitlement checks
- Safe delivery authorization
- Watermarking policy
- Expired access behavior
- Error handling
- Protected resource isolation

## Watermark Tests

If server-applied watermarking
is part of the approved design:

- Correct student identification
- Correct document/course association
- Watermark generation succeeds
- Unwatermarked original remains private
- Generated copy is scoped correctly
- Cache behavior follows policy

## Critical Limitation

Flutter Web cannot guarantee
prevention of screenshots,
screen recordings,
developer tool extraction,
or external camera capture.

Do not create a release test
expecting absolute screenshot prevention.

Document residual risks honestly.

---

# 32. VIDEO PLAYER TESTING

Test:

- Authorized playback
- Unauthorized playback denial
- Loading state
- Buffering state
- Playback error state
- Pause/resume
- Seek controls
- Progress tracking
- Expired playback authorization
- Mobile browser behavior

## Test Cases

TST-VID-001:
Authorized video plays.

TST-VID-002:
Unpaid student playback denied.

TST-VID-003:
Revoked access denies
new protected playback authorization.

TST-VID-004:
Loading state displayed.

TST-VID-005:
Playback failure handled.

TST-VID-006:
Resume position restored.

TST-VID-007:
Video controls accessible.

TST-VID-008:
Mobile layout is usable.

TST-VID-009:
Playback authorization expires
according to provider policy.

Video delivery must be tested
against the chosen actual provider.

Mocks alone are insufficient.

---

# 33. LEARNING PROGRESS TESTING

Test:

- Initial progress
- Progress updates
- Completion state
- Resume position
- PDF page
- Video position
- Cross-user isolation
- Entitlement enforcement
- Retry behavior

## Test Cases

TST-LEARN-001:
Student starts a lesson.

TST-LEARN-002:
Progress is saved.

TST-LEARN-003:
Resume position is restored.

TST-LEARN-004:
Completion state updates.

TST-LEARN-005:
Student cannot edit another
student's progress.

TST-LEARN-006:
Unauthorized lesson progress
write is denied.

TST-LEARN-007:
Invalid progress values rejected.

TST-LEARN-008:
Repeated progress writes
do not corrupt current state.

TST-LEARN-009:
Progress failure is handled
without falsely confirming persistence.

---

# 34. ADMINISTRATION TESTING

The admin system contains
sensitive business functionality.

## Test Areas

- Dashboard statistics
- Course creation
- Course editing
- Publishing
- Lesson uploads
- Student management
- Enrollment management
- Payment review
- Financial reporting
- Role assignment
- Audit history

## Test Cases

TST-ADMIN-001:
Authorized admin dashboard opens.

TST-ADMIN-002:
Student admin API access denied.

TST-ADMIN-003:
Authorized course creation works.

TST-ADMIN-004:
Unauthorized course modification denied.

TST-ADMIN-005:
Unpublished course remains private.

TST-ADMIN-006:
Authorized publication works.

TST-ADMIN-007:
Finance reviewer sees
only permitted financial information.

TST-ADMIN-008:
Unauthorized bank approval denied.

TST-ADMIN-009:
Role escalation attempt rejected.

TST-ADMIN-010:
Sensitive action produces audit record.

TST-ADMIN-011:
Dashboard figures match
approved backend query definitions.

TST-ADMIN-012:
Administrative errors
do not expose private records.

---

# 35. FILE UPLOAD TESTING

Test uploads for:

- Bank receipts
- Course thumbnails
- Lesson images
- PDFs
- Other approved assets

## Validation

- Allowed MIME type
- File extension
- Actual file content where feasible
- File size
- Authenticated ownership
- Storage destination
- Allowed object path
- Duplicate behavior
- Access policies

## Security Scenarios

- Extension/content mismatch
- Oversized file
- Invalid image
- Malformed PDF
- Suspicious file metadata
- Unauthorized upload path
- Another student's receipt overwrite
- Unauthorized object replacement
- Unsafe filename handling

Add content scanning when required
by the approved upload threat model.

Never trust a browser-provided
MIME type alone.

Never process dangerous uploads
through unrestricted privileged tools.

---

# 36. FULL END-TO-END TESTING

End-to-end tests verify
complete integrated user journeys.

## Journey A - Online Purchase

1. Register or log in.
2. Browse course marketplace.
3. Select published course.
4. View course details.
5. Begin checkout.
6. Select online payment.
7. Complete provider sandbox payment.
8. Backend verifies provider event.
9. Order becomes paid.
10. Enrollment becomes active.
11. My Courses updates.
12. Paid lesson opens.

Expected:

Student receives access
only after verified payment.

## Journey B - Bank Transfer

1. Student logs in.
2. Selects course.
3. Selects bank transfer.
4. Views official bank instructions.
5. Uploads receipt.
6. Sees pending state.
7. Attempts paid lesson access.
8. Access is denied.
9. Finance admin reviews submission.
10. Authorized verification is completed.
11. Approval commits.
12. Enrollment becomes active.
13. Student opens course.

Expected:

No access before approval.

## Journey C - Rejected Transfer

1. Submit receipt.
2. Finance reviewer rejects submission.
3. Student sees rejection status.
4. Student attempts paid content access.

Expected:

Access remains denied.

## Journey D - Course Management

1. Authorized admin logs in.
2. Creates draft course.
3. Adds sections.
4. Adds lessons.
5. Uploads private media.
6. Publishes approved course.
7. Public marketplace shows course.

Expected:

Draft content remains protected
before publication.

## Journey E - Learning

1. Enrolled student opens course.
2. Opens PDF.
3. Navigates pages.
4. Saves progress.
5. Logs out.
6. Logs in again.
7. Resumes learning.

Expected:

Authorized access and progress
are handled correctly.

## Journey F - Unauthorized Access

1. Student without purchase logs in.
2. Tries protected learning route.
3. Calls content API directly.
4. Requests private storage object.

Expected:

Backend denies unauthorized access.

---

# 37. BROWSER INTEGRATION TESTING

Flutter Web requires actual
browser-based verification.

Recommended approach:

Use Flutter integration_test
with a configured browser runner.

Example after required setup:

```bash id="o2cyg3"
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome
```

The example assumes:

- integration_test is configured.
- The target test file exists.
- The driver file exists.
- A compatible ChromeDriver is installed
  and running as required.

Do not report this command passed
unless the environment was configured
and the test actually executed.

## Browser Matrix

Candidate browsers:

- Chrome
- Edge
- Firefox
- Safari

Exact versions and support targets
must be approved before release.

Test at least:

- Navigation
- Authentication
- Payment status
- File upload
- PDF reading
- Video playback
- Responsive behavior

Document browser-specific failures.

---

# 38. RESPONSIVE TESTING

Follow DESIGN_SYSTEM.md.

Reference widths:

390 logical pixels

768 logical pixels

1440 logical pixels

Also test near major breakpoints.

Suggested additional widths:

320
599
600
1023
1024

## Required Areas

- Authentication forms
- Course cards
- Course details
- Checkout
- Bank receipt upload
- Student dashboard
- Learning workspace
- PDF reader
- Admin navigation
- Financial review tables

## Check

- No unintended overflow
- No clipped important text
- Usable controls
- Correct navigation adaptation
- Appropriate content density
- Stable loading states
- Readable PDFs
- Usable dialogs and forms

Test portrait and landscape
when relevant.

---

# 39. LIGHT AND DARK THEME TESTING

All major screens must support:

Light theme

Dark theme

## Verify

- Correct design tokens
- Text readability
- Surface contrast
- Form field visibility
- Error message readability
- Disabled state clarity
- PDF toolbar visibility
- Admin table readability
- Focus indicator visibility

Use golden tests where practical.

## Golden Test Rules

- Use stable fonts.
- Use deterministic data.
- Control test dimensions.
- Avoid unnecessary animation.
- Review intentional image changes.
- Do not approve golden updates blindly.

A passing golden test
does not replace interaction testing.

---

# 40. ACCESSIBILITY TESTING

Target:

WCAG 2.2 AA where applicable.

This is a proposed target,
not a claim of conformance.

## Test Areas

- Semantic labels
- Keyboard navigation
- Focus order
- Focus visibility
- Color contrast
- Text scaling
- Touch target usability
- Error identification
- Screen-reader announcements
- Navigation consistency
- Reduced motion where relevant

## Critical Screens

- Registration
- Login
- Checkout
- Receipt upload
- Course learning
- PDF reader
- Admin payment review

## Important

Automated accessibility tests
cannot detect every usability issue.

Combine automated checks
with manual assistive-technology
and keyboard verification.

The PDF reader must be evaluated
for actual document accessibility,
not just toolbar accessibility.

---

# 41. PERFORMANCE TESTING

Performance testing must use
measured representative conditions.

## Frontend Metrics

- Initial application load
- Time to interactive content
- Navigation responsiveness
- Widget rendering
- Large course lists
- PDF rendering
- Large PDF page navigation
- Memory consumption

## Backend Metrics

- Catalog query latency
- Checkout creation latency
- Payment finalization latency
- Bank review latency
- Enrollment lookup latency
- Protected content authorization latency

## Suggested Reporting

Record:

Metric:
Environment:
Dataset Size:
Concurrent Users:
Median:
P95:
Error Rate:
Measured Result:
Approved Threshold:

Do not invent target compliance.

Performance acceptance thresholds
must be established based on
realistic workloads and business needs.

---

# 42. LOAD AND CONCURRENCY TESTING

Load tests should focus on
high-risk shared resources.

## Recommended Scenarios

- Many students browsing courses.
- Simultaneous checkout creation.
- Duplicate payment callbacks.
- Multiple reviewers accessing queue.
- Concurrent bank approvals.
- Multiple students requesting PDFs.
- Progress updates from many sessions.

## Requirements

- Use synthetic data.
- Use approved test environments.
- Set traffic limits.
- Avoid unapproved provider charges.
- Avoid impacting production customers.
- Record resource consumption.

## Payment Concurrency

Verify:

- No double financial finalization.
- No duplicate entitlement grants.
- No inconsistent audit trail.
- No partial transaction state.

---

# 43. RELIABILITY AND FAILURE TESTING

Test controlled failures.

## Scenarios

- Client loses network connection.
- Backend temporarily unavailable.
- Provider callback delayed.
- Duplicate webhook arrives.
- Storage access expires.
- Upload interrupted.
- Notification delivery fails.
- User logs out during request.
- Admin approval request times out.
- Database transaction fails.

## Expected Behavior

- Safe error message
- No unauthorized access
- No false payment confirmation
- No duplicate business mutation
- Recoverable retry when permitted
- Accurate status after refresh

## Financial Recovery

Simulate provider success
followed by internal processing failure.

Verify the recovery strategy
can reconcile the state safely.

---

# 44. BACKUP AND RESTORE TESTING

Production readiness requires
verified recovery procedures.

## Database

Test restoration of:

- Courses
- Orders
- Payment records
- Enrollments
- Student progress
- Audit records

## Storage

Test restoration of:

- Private PDFs
- Lesson media
- Bank receipts
- Important course assets

## Important

A PostgreSQL backup does not
automatically preserve all
Supabase Storage object bytes.

Separate database and object
recovery verification is required.

## Recovery Evidence

Record:

Backup Date:
Restore Environment:
Restore Procedure:
Records Verified:
Objects Verified:
Recovery Time:
Data Loss Observed:
Issues:
Reviewer:

Do not claim backup readiness
without an actual restore test.

---

# 45. SECURITY VERIFICATION

Use SECURITY.md as the
security test baseline.

A proposed verification framework
may reference applicable controls
from OWASP ASVS 5.0 Level 2.

This does not mean the product
is certified or compliant.

## Security Test Categories

Authentication

Authorization

Session management

Input validation

Data protection

Access control

File upload security

API security

Financial integrity

Logging

Configuration security

Dependency security

## Required Negative Tests

- Unauthorized user impersonation
- Cross-account object access
- Admin privilege escalation
- Client-modified payment amounts
- Forged provider events
- Unauthorized enrollment creation
- Unpublished lesson exposure
- Private receipt exposure
- Unsafe database function execution

Important:

A successful UI test
does not establish security.

---

# 46. SECRETS AND PRIVACY TESTING

Test that client-distributed
assets contain no privileged secrets.

Never expose:

- Supabase service credentials
- Payment provider secrets
- Private database passwords
- Video signing secrets
- Email provider credentials

## Required Checks

- Repository secret scanning
- CI configuration review
- Environment file exclusion
- Browser bundle inspection
- Log redaction
- Error response inspection
- Test artifact privacy

## Test Data Rules

Use synthetic:

- Users
- Emails
- Bank account references
- Receipts
- Courses
- Transactions
- Enrollment records

Do not commit real student receipts,
payment credentials, or financial records.

---

# 47. TEST FIXTURE STRATEGY

Fixtures must be:

- Synthetic
- Deterministic
- Minimal
- Reusable
- Clearly named
- Independently resettable

## Suggested Fixtures

Student A:
Active account.

Student B:
Separate account.

Content Manager:
Assigned to one course.

Finance Admin:
Authorized review role.

Super Admin:
Authorized administration role.

Published Course:
Visible to visitors.

Draft Course:
Hidden from visitors.

Paid Order:
Verified sandbox state.

Pending Order:
No entitlement.

Rejected Bank Submission:
No entitlement.

Active Enrollment:
Authorized learning access.

Revoked Enrollment:
Access denied.

Expired Enrollment:
Access denied.

Use fake documents and media.

Never use real student financial evidence.

---

# 48. TEST DATA ISOLATION

Claude and Codex must not
modify the same mutable test state
without an isolation strategy.

## Preferred Methods

Separate local Supabase instances.

Separate approved test databases.

Independent synthetic fixture sets.

Unique test identifiers.

Isolated temporary directories.

## Shared Test Resources

If sharing is unavoidable:

- Coordinate test execution.
- Avoid destructive resets.
- Use stable fixture ownership.
- Serialize conflicting tests.
- Record test environment usage.

## Important

Separate Git worktrees do not
automatically isolate:

- PostgreSQL instances
- Docker resources
- Service ports
- Cloud Storage
- External payment sandboxes

Both agents must explicitly
verify their test environment.

---

# 49. CLAUDE TESTING RESPONSIBILITIES

Suggested initial focus:

- Flutter unit tests
- Widget tests
- Responsive layout tests
- Navigation tests
- Authentication UI tests
- Marketplace tests
- Checkout UI tests
- PDF reader tests
- Admin UI tests
- Browser integration tests
- Accessibility checks

Claude may also work on
backend tests when assigned.

## Superpowers Integration

When installed and relevant,
Claude should use:

test-driven-development

systematic-debugging

verification-before-completion

requesting-code-review

receiving-code-review

Use actual available skill instructions.

Do not claim unavailable tools
were used.

---

# 50. CODEX TESTING RESPONSIBILITIES

Suggested initial focus:

- Supabase database tests
- PostgreSQL constraints
- RLS tests
- Edge Function tests
- Payment verification tests
- Bank transfer security tests
- Enrollment consistency tests
- Privileged function tests
- Migration validation
- CI/CD verification
- Backend performance testing

Codex may also work on
Flutter tests when assigned.

## Important

The owner of a security-sensitive
feature must implement meaningful
negative tests.

Do not delegate all security verification
to the other agent.

Both agents remain responsible
for their assigned changes.

---

# 51. CROSS-AGENT TESTING PROTOCOL

Parallel testing workflow:

CLAUDE
   |
   v
Frontend Implementation
   |
   v
Widget + UI Tests
   |
   v
PR A

CODEX
   |
   v
Backend Implementation
   |
   v
Database + Security Tests
   |
   v
PR B

PR A + PR B
   |
   v
Contract Verification
   |
   v
Integration Testing
   |
   v
Security Review
   |
   v
Approved Merge
   |
   v
Post-Merge Verification

## Mandatory Rules

- Separate branches and workspaces.
- Shared test contracts approved.
- No conflicting test fixture changes.
- No uncontrolled database resets.
- Each agent reports actual test results.
- Integration tests run against
  compatible combined changes.

Passing isolated tests
does not prove integrated behavior.

---

# 52. TEST OWNERSHIP RULES

Every test task must have
one accountable owner.

Task metadata:

Task ID:
Agent:
Branch:
Allowed Scope:
Test Scope:
Dependencies:
Shared Resources:
Required Evidence:
PR:

## Ownership Example

Task:
CSA-156

Owner:
CLAUDE

Scope:
PDF reader UI tests.

Task:
CSA-152

Owner:
CODEX

Scope:
Unauthorized PDF delivery tests.

Both tasks may proceed concurrently
when their interfaces are approved.

Do not edit the same test file
or shared fixture without coordination.

---

# 53. PULL REQUEST TEST REQUIREMENTS

Every PR must state
which checks actually ran.

## PR Testing Section

Formatting:
PASS / FAIL / NOT RUN

Static Analysis:
PASS / FAIL / NOT RUN

Unit Tests:
PASS / FAIL / NOT RUN

Widget Tests:
PASS / FAIL / NOT RUN

Database Tests:
PASS / FAIL / NOT RUN

Backend Function Tests:
PASS / FAIL / NOT RUN

Integration Tests:
PASS / FAIL / NOT RUN

Security Tests:
PASS / FAIL / NOT RUN

Accessibility:
PASS / FAIL / NOT RUN

Responsive Verification:
PASS / FAIL / NOT RUN

## Evidence

Include where available:

- CI run
- Test output summary
- Relevant test names
- Browser screenshots
- Security test results
- Environment identification

Do not paste secrets or
private customer data into PRs.

---

# 54. REQUIRED LOCAL COMMANDS

Run commands applicable
to the changed code.

## Flutter Dependencies

```bash id="k27wo1"
flutter pub get
```

## Formatting

```bash id="z8h3lw"
dart format --output=none --set-exit-if-changed .
```

## Static Analysis

```bash id="u6k3zi"
flutter analyze
```

## Unit and Widget Tests

```bash id="a6ny3k"
flutter test
```

## Coverage Collection

```bash id="qru6xv"
flutter test --coverage
```

Coverage collection does not
automatically enforce a quality threshold.

## Production Web Build

```bash id="yk9i10"
flutter build web --release
```

## Local Supabase Setup

When configured:

```bash id="k5ajm7"
supabase start
```

## Database Tests

```bash id="c2b7x9"
supabase test db
```

## Database Lint

```bash id="u9n3lo"
supabase db lint --fail-on error
```

## Edge Function Unit Tests

When Deno tests are configured:

```bash id="d3ss82"
deno test supabase/functions/tests/
```

Individual function test suites
may require narrowly scoped
test permissions.

Do not default to unrestricted
Deno permissions without justification.

## Important

Commands are examples of
the intended test workflow.

They must not be reported as passed
until executed successfully.

---

# 55. CONTINUOUS INTEGRATION STRATEGY

Use GitHub Actions.

## Pull Request Checks

Minimum:

1. Checkout code.
2. Configure approved Flutter version.
3. Restore dependencies.
4. Verify formatting.
5. Run static analysis.
6. Run unit/widget tests.
7. Build Flutter Web.

For backend changes:

8. Start isolated Supabase test stack.
9. Apply and validate migrations.
10. Run pgTAP tests.
11. Run Edge Function tests.
12. Run relevant security checks.

## Optional Scheduled Checks

- Dependency vulnerability review
- Full browser regression suite
- Extended integration tests
- Performance baseline comparison
- Storage security checks

## Pre-Release Checks

- Complete E2E journeys
- Payment sandbox verification
- Bank transfer workflow
- RLS authorization matrix
- PDF/video access security
- Backup/restore verification
- Browser compatibility
- Accessibility review

---

# 56. CI SECURITY

CI must use least privilege.

## Requirements

- Minimize GITHUB_TOKEN permissions.
- Protect deployment credentials.
- Avoid exposing secrets
  to untrusted pull request code.
- Review third-party actions.
- Prefer immutable reviewed action versions.
- Do not print secret values.
- Avoid unsafe shell interpolation.
- Restrict production deployment authority.

## Pull Request Safety

Do not run untrusted PR code
with privileged secrets merely
to execute automated tests.

Use isolated synthetic test resources.

Review privileged workflow triggers
before enabling them.

## Important

If GitHub repository settings
cannot automatically enforce
all required checks or reviews,
record and perform manual controls.

Do not claim unenforced rules
are automatically protected.

---

# 57. CI FAILURE POLICY

A failed required check
must be investigated.

Procedure:

1. Read the failure output.
2. Identify the affected test.
3. Reproduce when possible.
4. Determine root cause.
5. Correct implementation or test.
6. Run relevant checks again.
7. Record the resolution.

Never:

- Disable meaningful tests.
- Remove security assertions.
- Hardcode expected success.
- Hide failures in CI configuration.
- Merge known critical regressions.
- Claim flaky tests are harmless
  without investigation.

---

# 58. FLAKY TEST MANAGEMENT

A flaky test is not automatically
a passing test.

Common causes:

- Timing dependence
- Shared mutable state
- Uncontrolled network calls
- External provider instability
- Unseeded randomness
- Unsynchronized asynchronous operations
- Browser rendering differences

## Procedure

1. Record the failure.
2. Determine reproducibility.
3. Identify the cause.
4. Improve deterministic setup.
5. Isolate dependencies.
6. Verify the fix repeatedly.
7. Restore normal CI enforcement.

Temporary quarantine requires:

- Documented reason
- Task owner
- Related issue
- Approved scope
- Follow-up action

P0 security tests must not
be silently quarantined.

---

# 59. CODE COVERAGE POLICY

Coverage helps identify
untested implementation areas.

However:

High line coverage does not
prove correctness or security.

## Proposed Targets

Critical domain logic:
Aim for strong branch coverage,
with a proposed 90% or higher
measured statement coverage.

General business logic:
Proposed initial target of 80%
measured statement coverage.

UI code:
Use risk-based widget and
interaction coverage rather than
an arbitrary global percentage.

These are proposed planning targets.

They are not current achieved metrics
or automatic release certifications.

## Required Critical Coverage

All approved payment transitions.

All approved bank review transitions.

Enrollment grant/revocation rules.

Role permission checks.

Protected content authorization.

Important error branches.

## Rules

- Do not write meaningless tests
  merely to increase coverage.
- Review uncovered critical branches.
- Record measured coverage accurately.
- Do not invent percentages.

---

# 60. REGRESSION TESTING

Every fixed defect should receive
a regression test where practical.

## Workflow

1. Reproduce the bug.
2. Write a failing test.
3. Fix the root cause.
4. Verify the test passes.
5. Run related regression tests.
6. Submit a focused PR.

## Critical Regression Areas

- Payment finalization
- Bank approval
- Enrollment activation
- RLS access control
- Admin role changes
- Private PDF delivery
- Protected video playback
- Course publication
- Authentication sessions

Security regressions take priority
over cosmetic improvements.

---

# 61. DEFECT SEVERITY LEVELS

## SEV-1 - CRITICAL

Examples:

- Payment bypass
- Unauthorized paid content access
- Privilege escalation
- Exposed financial credentials
- Major cross-user data leak

Response:

Block release.

## SEV-2 - HIGH

Examples:

- Broken checkout
- Missing verified enrollment
- Bank approval malfunction
- Major authentication failure

Response:

Block affected release
until resolved or explicitly
handled under an approved policy.

## SEV-3 - MEDIUM

Examples:

- Noncritical UI malfunction
- Reader controls fail on
  a limited supported layout
- Recoverable progress display error

Response:

Prioritize based on user impact.

## SEV-4 - LOW

Examples:

- Minor visual inconsistency
- Cosmetic spacing issue
- Noncritical wording error

Response:

Schedule appropriate correction.

Severity must reflect actual impact,
not which agent implemented the code.

---

# 62. BUG REPORT TEMPLATE

Title:

[BUG] Short description

## Identification

Bug ID:
Related CSA Task:
Severity:
Environment:
Application Revision:

## Reproduction Steps

1.
2.
3.

## Expected Result

Describe expected behavior.

## Actual Result

Describe actual behavior.

## Evidence

Screenshots/logs/test output.

Remove sensitive information.

## Impact

Affected feature or users.

## Suspected Cause

Optional, clearly identified
as a hypothesis.

## Assigned Owner

CLAUDE / CODEX / OTHER

## Regression Test

Test ID or required new test.

## Resolution

PR and verification evidence.

---

# 63. TEST REPORT TEMPLATE

Document:
Test Execution Report

## Metadata

Run ID:
Date:
Environment:
Commit SHA:
Branch:
Agent:
Related Task:
CI Run:

## Results

Total Executed:
Passed:
Failed:
Blocked:
Skipped:
Flaky:

## Commands Executed

List actual commands.

## Failures

Test ID:
Failure:
Impact:
Related Issue:

## Security Findings

Describe relevant findings.

## Integration Findings

Describe relevant incompatibilities.

## Limitations

List unexecuted checks.

## Final Assessment

PASS / FAIL / BLOCKED

A passing assessment must reflect
required test execution and
acceptance criteria.

---

# 64. RELEASE TEST MATRIX

Before production release,
verify the following areas.

| Area | Priority | Required Verification |
|---|---|---|
| Authentication | P0/P1 | Auth + isolation |
| Roles | P0 | Unauthorized escalation |
| Marketplace | P1 | Public/draft visibility |
| Checkout | P0 | Server-side pricing |
| Online Payments | P0 | Verified events and concurrency |
| Bank Transfers | P0 | Review authorization and settlement |
| Enrollments | P0 | Trusted grants and revocation |
| PDF Storage | P0 | Unauthorized access denied |
| PDF Reader | P1 | Readability and navigation |
| Video Delivery | P0/P1 | Playback authorization |
| Learning Progress | P1 | Ownership and persistence |
| Administration | P0/P1 | RBAC and audit |
| Database | P0 | RLS, grants, constraints |
| Infrastructure | P0 | Secrets and recovery |
| Responsive UI | P1 | Supported layout widths |
| Accessibility | P1 | Relevant WCAG checks |
| Performance | P1 | Approved measured thresholds |

Each area must have an identified
test owner and current evidence.

---

# 65. TASKS.MD TEST MAPPING

Relevant master task range:

CSA-177 through CSA-204

## User Journey Testing

CSA-177:
Registration journey.

CSA-178:
Online purchase journey.

CSA-179:
Bank approval journey.

CSA-180:
Purchase-to-learning entitlement.

CSA-181:
Course publishing journey.

## Security

CSA-182:
RLS and grants audit.

CSA-183:
Cross-student isolation.

CSA-184:
Finance permissions.

CSA-185:
Private storage policies.

CSA-186:
Upload security.

CSA-187:
Web security.

CSA-188:
Secrets and logs.

CSA-189:
Dependency review.

## UI/UX

CSA-190:
Mobile layouts.

CSA-191:
Tablet layouts.

CSA-192:
Desktop layouts.

CSA-193:
Themes.

CSA-194:
Keyboard accessibility.

CSA-195:
Critical workflow usability.

## Performance

CSA-196:
Flutter startup.

CSA-197:
Database query performance.

CSA-198:
Large PDFs.

CSA-199:
Video playback.

## Reliability

CSA-200:
Backup/recovery.

CSA-201:
Financial failure recovery.

CSA-202:
Security blocker resolution.

CSA-203:
Release-blocking defects.

CSA-204:
Final regression acceptance.

Testing must also be implemented
throughout feature development.

Do not defer all tests
until Phase 8.

---

# 66. PHASE-BY-PHASE TEST GATES

## Phase 0 - Planning

- [ ] Acceptance criteria defined.
- [ ] Critical security scenarios identified.
- [ ] Test architecture approved.

## Phase 1 - Foundations

- [ ] Flutter test infrastructure works.
- [ ] Database test tooling works.
- [ ] CI executes baseline checks.
- [ ] Agent test isolation demonstrated.

## Phase 2 - Design System

- [ ] Reusable widget tests.
- [ ] Theme verification.
- [ ] Responsive component checks.
- [ ] Accessibility foundation review.

## Phase 3 - Authentication

- [ ] Authentication flow tests.
- [ ] Profile RLS tests.
- [ ] Role authorization tests.

## Phase 4 - Marketplace

- [ ] Catalog tests.
- [ ] Draft publication security tests.
- [ ] Search and filter tests.

## Phase 5 - Payments

- [ ] Financial validation tests.
- [ ] Payment webhook tests.
- [ ] Bank approval tests.
- [ ] Concurrency tests.
- [ ] Enrollment grant tests.

## Phase 6 - Learning

- [ ] Content authorization tests.
- [ ] PDF reader tests.
- [ ] Video playback tests.
- [ ] Progress persistence tests.

## Phase 7 - Administration

- [ ] Admin permissions.
- [ ] Course management.
- [ ] Financial review.
- [ ] Audit records.

## Phase 8 - Hardening

- [ ] Full regression.
- [ ] Security verification.
- [ ] Accessibility evaluation.
- [ ] Performance evaluation.
- [ ] Recovery tests.

## Phase 9 - Launch

- [ ] Production readiness review.
- [ ] Approved smoke tests.
- [ ] Monitoring verification.
- [ ] Rollback plan reviewed.

No phase is complete based only
on a written checklist.

Evidence is required.

---

# 67. PARALLEL DEVELOPMENT TEST GATE

Before Claude and Codex merge work:

- [ ] Each task owner confirmed.
- [ ] Separate workspaces used.
- [ ] File ownership respected.
- [ ] API contracts compatible.
- [ ] Database migrations ordered.
- [ ] Independent tests executed.
- [ ] Required CI checks pass.
- [ ] Security checks pass where relevant.
- [ ] Integration behavior verified.
- [ ] Required reviews completed.

After merge:

- [ ] Verify combined functionality.
- [ ] Update task status.
- [ ] Record integration evidence.
- [ ] Release shared-file locks.
- [ ] Refresh dependent branches.

A merged repository must be tested
as a combined system.

---

# 68. TEST DEFINITION OF READY

A test task is READY when:

- [ ] Requirement identified.
- [ ] Test owner assigned.
- [ ] Test layer selected.
- [ ] Expected behavior defined.
- [ ] Test data available.
- [ ] Environment available.
- [ ] Dependencies satisfied.
- [ ] Security implications reviewed.
- [ ] Acceptance criteria testable.

---

# 69. TEST DEFINITION OF DONE

A test task is DONE only when:

- [ ] Required test implemented.
- [ ] Test executes successfully.
- [ ] Expected assertions validated.
- [ ] Negative paths covered if required.
- [ ] Test data is synthetic.
- [ ] Environment is documented.
- [ ] No uncontrolled shared state.
- [ ] Relevant CI checks pass.
- [ ] Security implications reviewed.
- [ ] Test evidence recorded.
- [ ] Required review completed.
- [ ] Test merged or formally accepted.

A test file existing
does not mean the test passed.

---

# 70. RELEASE BLOCKERS

Production release must be blocked when:

- Unverified payments unlock courses.
- Bank receipt uploads grant access automatically.
- Students can modify paid enrollments.
- RLS exposes another student's data.
- Finance permissions can be bypassed.
- Private PDFs are publicly accessible.
- Critical authorization tests fail.
- Financial state becomes inconsistent.
- Production secrets are exposed.
- Required backup recovery is unverified.
- Critical release checks have not run.
- A high-risk unresolved defect remains.

No AI agent may waive
these requirements independently.

---

# 71. TEST GOVERNANCE

Project Lead:

- Approves test policy.
- Resolves quality disputes.
- Reviews release evidence.
- Approves risk decisions.

Claude:

- Owns assigned tests.
- Implements appropriate UI verification.
- Reports actual results.

Codex:

- Owns assigned tests.
- Implements appropriate backend verification.
- Reports actual results.

Authorized Reviewers:

- Review critical implementation.
- Evaluate security evidence.
- Confirm required quality gates.

AI cross-review is useful.

It does not automatically replace
required independent human approval
for security-sensitive releases.

---

# 72. OPEN TESTING DECISIONS

TEST-OPEN-001:
Final supported browser matrix.

TEST-OPEN-002:
Approved performance thresholds.

TEST-OPEN-003:
Final coverage policy.

TEST-OPEN-004:
Browser E2E automation framework.

TEST-OPEN-005:
Payment provider sandbox setup.

TEST-OPEN-006:
Protected video test environment.

TEST-OPEN-007:
PDF document size benchmarks.

TEST-OPEN-008:
Accessibility acceptance process.

TEST-OPEN-009:
Independent security review scope.

TEST-OPEN-010:
Load test concurrency targets.

TEST-OPEN-011:
Staging environment isolation.

TEST-OPEN-012:
Backup/recovery acceptance thresholds.

TEST-OPEN-013:
CI branch-protection enforcement.

TEST-OPEN-014:
Test report retention policy.

TEST-OPEN-015:
Cross-agent integration test ownership.

TEST-OPEN-016:
Flaky test quarantine approval process.

TEST-OPEN-017:
Financial reconciliation test schedule.

TEST-OPEN-018:
Pre-release regression checklist owner.

Resolve these decisions before
dependent release verification.

---

# 73. RECOMMENDED INITIAL TEST SETUP

Suggested starting order:

1. Configure Flutter unit tests.
2. Configure Flutter widget tests.
3. Create reusable synthetic fixtures.
4. Configure Supabase local stack.
5. Configure pgTAP tests.
6. Add initial RLS tests.
7. Configure Edge Function testing.
8. Configure GitHub Actions.
9. Establish task-level test reporting.
10. Validate two-agent test isolation.
11. Add authentication integration tests.
12. Add course catalog integration tests.
13. Add payment security tests.
14. Add enrollment authorization tests.
15. Add PDF/content security tests.
16. Add browser E2E tests.
17. Establish release regression suite.

Do not begin critical payment development
without a usable backend testing strategy.

---

# 74. FINAL TESTING DIRECTIVE

Acedra must deliver secure,
correct, reliable, and accessible software.

Every development task requires
appropriate verification.

Critical financial operations must be:

- Authenticated
- Authorized
- Validated
- Transactional
- Idempotent
- Auditable
- Tested

Protected content must require
current backend authorization.

Database access must be tested
against actual RLS and grant behavior.

Flutter must be tested for
responsive behavior, accessibility,
and correct state handling.

Claude and Codex must maintain
independent test environments
where parallel execution could conflict.

Every test result must be honest.

Never fabricate passing tests.

Never remove meaningful security tests.

Never treat mocked payment success
as verified payment completion.

Never mark incomplete testing DONE.

TEST REAL BEHAVIOR.
TEST FAILURE PATHS.
TEST PERMISSIONS.
TEST FINANCIAL INTEGRITY.
TEST PRIVATE CONTENT ACCESS.
USE SYNTHETIC DATA.
ISOLATE PARALLEL WORK.
VERIFY BEFORE COMPLETION.
REVIEW BEFORE MERGE.
BLOCK UNSAFE RELEASES.

END OF TESTING.md
