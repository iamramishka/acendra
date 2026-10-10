
# SECURITY.md
# Acedra - Application Security Policy

Document ID: CSA-SEC-001
Version: 1.0
Status: Proposed - Pending Approval
Project: Acedra Course Selling Application
Primary Platform: Flutter Web
Backend: Supabase + PostgreSQL
Architecture: Modular Monolith
Security Standard: OWASP ASVS 5.0
Classification: Internal Engineering Documentation

---

# 1. PURPOSE

This document establishes mandatory security
requirements, policies, procedures, and
verification standards for Acedra.

Acedra is a commercial learning platform
that manages:

- Student identities
- Authentication sessions
- Personal information
- Online payments
- Bank transfer receipts
- Course purchases
- Course enrollments
- Proprietary learning content
- Protected PDF documents
- Video lessons
- Administrative permissions
- Financial audit records

The system must protect:

1. Confidentiality
2. Integrity
3. Availability
4. Authentication
5. Authorization
6. Financial correctness
7. Student privacy
8. Intellectual property
9. Auditability
10. Operational resilience

Security is mandatory throughout
the software development lifecycle.

---

# 2. SECURITY PHILOSOPHY

The application shall follow:

## Security by Design

Security requirements must be identified
before features are implemented.

## Secure by Default

Access is denied unless explicitly allowed.

## Defense in Depth

Use multiple independent security controls.

## Least Privilege

Users and services receive only
necessary permissions.

## Zero Trust Principles

Never trust an action solely because
it originated from the application UI.

## Privacy by Design

Collect and retain only necessary data.

## Fail Securely

Errors must never grant unauthorized access.

## Verifiable Security

Security controls must be tested,
not merely documented.

## Honest Security Communication

Never claim content protection
is stronger than it actually is.

---

# 3. RELATED DOCUMENTS

Security controls must remain aligned with:

- SRS.md
- PLAN.md
- AGENTS.md
- ARCHITECTURE.md
- DATABASE_DESIGN.md
- DESIGN_SYSTEM.md
- CONTRIBUTING.md
- TESTING.md
- Relevant Architecture Decision Records

Document responsibilities:

SRS.md:
Security-related functional requirements.

ARCHITECTURE.md:
Technical security boundaries and flows.

DATABASE_DESIGN.md:
Database constraints, grants, and RLS.

SECURITY.md:
Security policy and verification standards.

AGENTS.md:
Mandatory developer and AI-agent behavior.

PLAN.md:
Implementation priorities and milestones.

---

# 4. SECURITY STANDARDS

The project should use the following
standards and guidance as references.

Primary:

- OWASP ASVS 5.0
- OWASP Cheat Sheet Series
- OWASP Top 10
- OWASP API Security Top 10

Additional:

- CWE vulnerability classifications
- CVSS for vulnerability severity
- WCAG 2.2 accessibility principles
- Official Flutter security guidance
- Official Supabase security documentation
- Official payment provider security guidance

Use ASVS Level 2 as the proposed
security verification target for
authentication, payments, administration,
and other sensitive functionality.

This is a project target, not a claim
of achieved ASVS compliance.

Specific verification requirements must
be mapped to actual test evidence.

---

# 5. SECURITY OWNERSHIP

Every security-sensitive area must
have a responsible owner.

## 5.1 Project Owner

Responsibilities:

- Approve security policy.
- Approve production risk exceptions.
- Authorize security-related spending.
- Review major incidents.
- Approve production access.

## 5.2 Technical Lead

Responsibilities:

- Maintain security architecture.
- Review critical code changes.
- Approve permission models.
- Review threat models.
- Coordinate vulnerability remediation.
- Verify release security evidence.

## 5.3 Developers

Responsibilities:

- Follow AGENTS.md.
- Use approved architecture.
- Validate external inputs.
- Write security-related tests.
- Avoid exposing secrets.
- Report discovered vulnerabilities.

## 5.4 Finance Administrators

Responsibilities:

- Verify bank transfers.
- Protect financial records.
- Follow approval procedures.
- Report suspicious transactions.
- Never share administrative credentials.

## 5.5 AI Coding Agents

AI agents must follow the same security
requirements as human contributors.

Agents cannot approve their own
security-critical production releases.

When a qualified independent reviewer
is unavailable, record this limitation
and apply an approved review process.

---

# 6. SUPPORTED VERSIONS

Security maintenance applies to
approved supported releases.

| Version | Security Support |
|---------|------------------|
| Current production release | Supported |
| Previous production releases | Case by case |
| Unreleased development builds | Internal only |
| Unsupported historical versions | No guarantee |

Before launch, no production release
should be claimed as supported.

Once production releases exist,
update this table with actual versions.

---

# 7. VULNERABILITY REPORTING POLICY

Security vulnerabilities must be
reported through a private channel.

## 7.1 Reporting Channels

Preferred:

GitHub private vulnerability reporting,
when available and enabled.

Alternative:

Designated security contact:
[CONFIGURE_SECURITY_CONTACT_BEFORE_LAUNCH]

Do not invent or publish an email address
that is not actively monitored.

Note:

GitHub private vulnerability reporting
is available for eligible public repositories.

A private repository requires an
appropriate confidential reporting channel.

## 7.2 Information to Provide

A vulnerability report should include:

- Description of the issue
- Affected functionality
- Affected version
- Reproduction steps
- Potential business impact
- Evidence without unnecessary private data
- Suggested mitigation, if known

## 7.3 Responsible Disclosure

Reporters should:

- Avoid publishing active exploits.
- Avoid accessing unrelated accounts.
- Avoid downloading private student records.
- Avoid destructive testing.
- Avoid disrupting production.
- Avoid submitting unnecessary sensitive data.
- Contact maintainers privately.

Testing outside authorized scope
is not permitted by this document.

## 7.4 Proposed Response Targets

These are internal response targets,
subject to team capacity.

Critical:
Initial triage target within 24 hours.

High:
Initial triage target within 2 business days.

Medium:
Initial triage target within 5 business days.

Low:
Review during routine security backlog triage.

These targets are not guaranteed
resolution deadlines or legal commitments.

## 7.5 Coordinated Disclosure

The team should:

1. Acknowledge the report.
2. Verify the vulnerability.
3. Assess severity.
4. Limit exposure.
5. Develop a remediation.
6. Test the remediation.
7. Deploy an approved fix.
8. Coordinate appropriate disclosure.

Do not publish exploit details
before a coordinated response.

---

# 8. SECURITY CLASSIFICATION

## 8.1 Critical

Examples:

- Remote compromise of privileged systems
- Unauthorized access to all student records
- Compromise of production secret credentials
- Arbitrary paid enrollment creation
- Major payment verification bypass
- Large-scale private content exposure

## 8.2 High

Examples:

- Unauthorized admin operation
- Cross-account data access
- Receipt storage exposure
- Payment amount manipulation
- Major authorization bypass
- Significant protected file leakage

## 8.3 Medium

Examples:

- Restricted information disclosure
- Weak endpoint rate limiting
- Recoverable session security weakness
- Limited access control defects

## 8.4 Low

Examples:

- Minor security configuration weaknesses
- Low-impact information leakage
- Limited security hardening opportunities

Severity must consider real impact,
exploitability, exposure, and context.

Use CVSS as supporting guidance
when appropriate.

---

# 9. SECURITY THREAT MODEL

The project shall maintain an
application-specific threat model.

## 9.1 Important Assets

- Student accounts
- Authentication tokens
- Payment records
- Bank receipts
- Course entitlements
- Course PDFs
- Video content
- Database credentials
- Payment verification secrets
- Administrative accounts
- Audit logs
- Backups

## 9.2 Trust Boundaries

Boundary A:
Browser to authentication provider.

Boundary B:
Browser to authorized data APIs.

Boundary C:
Browser to trusted Edge Functions.

Boundary D:
Backend to payment gateway.

Boundary E:
Backend to PostgreSQL.

Boundary F:
Backend to private object storage.

Boundary G:
Backend to video provider.

Boundary H:
Developer/CI access to production.

## 9.3 Threat Categories

THREAT-001:
Unauthorized course access.

THREAT-002:
Forged payment confirmation.

THREAT-003:
Duplicate payment event processing.

THREAT-004:
Fake bank receipt approval.

THREAT-005:
Administrative privilege escalation.

THREAT-006:
Cross-student data exposure.

THREAT-007:
Leaked private PDF URLs.

THREAT-008:
Compromised backend secrets.

THREAT-009:
Malicious file uploads.

THREAT-010:
Cross-site scripting.

THREAT-011:
Abuse of public APIs.

THREAT-012:
Sensitive data leaked through logs.

THREAT-013:
Unauthorized data deletion.

THREAT-014:
Compromised CI/CD pipeline.

THREAT-015:
Lost or corrupted storage assets.

THREAT-016:
Unpatched third-party dependencies.

Threat models must be updated when
trust boundaries or sensitive workflows change.

---

# 10. AUTHENTICATION SECURITY

Authentication Provider:
Supabase Auth

## 10.1 Required Controls

- Email/password authentication
- Email verification
- Secure password recovery
- Secure session handling
- Session expiry
- Logout
- Authentication rate limiting
- Abuse prevention where appropriate
- Safe authentication error messages

## 10.2 Password Rules

- Never store plaintext passwords.
- Never write custom reversible
  password storage mechanisms.
- Delegate password hashing to
  the approved authentication provider.
- Never log passwords.
- Never email passwords.
- Never expose password reset tokens.
- Use secure reset and recovery flows.

Password requirements should follow
current provider and relevant
authentication security guidance.

## 10.3 Administrative Accounts

For finance and super-administrator accounts:

- Require individual user identities.
- Use strong authentication.
- Require MFA before production launch
  where the approved provider supports it.
- Review privileged access periodically.
- Revoke access promptly when no longer needed.
- Avoid shared administrative accounts.

Any MFA limitation requires a documented
risk decision and compensating controls.

---

# 11. SESSION SECURITY

## 11.1 Session Requirements

- Validate sessions on protected requests.
- Handle expired tokens.
- Protect refresh tokens.
- Revoke sessions when appropriate.
- Avoid exposing session credentials in URLs.
- Do not log session tokens.
- Minimize token lifetime and exposure.

## 11.2 Flutter Web Considerations

The browser is an untrusted environment.

JavaScript-accessible session storage
may be exposed by successful XSS attacks.

Mitigations include:

- Preventing XSS
- Limiting external scripts
- Applying appropriate CSP
- Restricting sensitive browser persistence
- Reviewing session storage choices
- Using short-lived access credentials

Browser storage is not an appropriate
place for server-side secrets.

## 11.3 Logout

On logout:

- End the intended authenticated session.
- Clear sensitive in-memory state.
- Invalidate user-specific client caches.
- Remove protected content from app state.
- Navigate to the appropriate public screen.

Previously copied content cannot be
guaranteed to disappear from a device.

---

# 12. AUTHORIZATION SECURITY

Authentication answers:
Who is the user?

Authorization answers:
What may the user do?

## 12.1 Access Control Models

Use:

- Role-Based Access Control
- Ownership-Based Access Control
- Course Entitlement-Based Access Control
- Row Level Security

## 12.2 Roles

- Guest
- Student
- Content Manager
- Finance Administrator
- Super Administrator

## 12.3 Authorization Rules

- Deny access by default.
- Verify permissions on trusted infrastructure.
- Never trust frontend roles.
- Never trust client-provided user IDs.
- Never trust client-provided enrollment status.
- Recheck permissions for sensitive actions.
- Audit privileged role changes.
- Apply least privilege.

## 12.4 Role Storage

Administrative privileges must not
depend on user-editable profile metadata.

Role assignment must use
a trusted administrative workflow.

Avoid relying on stale authorization
claims when immediate revocation is required.

---

# 13. SUPABASE DATABASE SECURITY

Database:
PostgreSQL

## 13.1 Row Level Security

RLS must be enabled for exposed tables
containing protected application data.

Policies must explicitly define
allowed operations.

Review:

- SELECT
- INSERT
- UPDATE
- DELETE

## 13.2 Database Grants

Database grants and RLS policies
must both be reviewed.

A permissive table grant does not
remove the need for a correct RLS policy.

An RLS policy does not replace
appropriate table-level privileges.

## 13.3 Student Permissions

Students may access:

- Own profile
- Own orders
- Own payments
- Own enrollments
- Own learning progress
- Authorized course metadata

Students must not access:

- Other students' private records
- Administrative permission assignments
- Private payment verification fields
- Internal audit data
- Unauthorized course content

## 13.4 Administrative Permissions

Admin permissions must be
defined at the operation level.

Examples:

Content Manager:
Can manage permitted course content.

Finance Administrator:
Can review relevant financial submissions.

Super Administrator:
Can perform explicitly authorized
platform-wide management operations.

Avoid unrestricted access to every
student record for every administrator.

## 13.5 RLS Testing

Every protected table should have
positive and negative access tests.

Test:

- Anonymous access
- Authenticated student access
- Cross-student access
- Invalid ownership
- Administrative access
- Direct API manipulation
- Unauthorized updates
- Unauthorized deletion

RLS tests are mandatory before release.

---

# 14. PRIVILEGED DATABASE OPERATIONS

Operations such as payment finalization
and enrollment creation must run
inside trusted transactional logic.

## 14.1 Transaction Requirements

Critical financial operations must:

- Validate trusted input.
- Lock relevant records when needed.
- Enforce valid state transitions.
- Avoid duplicate updates.
- Create audit events.
- Commit related changes atomically.
- Roll back safely on failure.

## 14.2 SECURITY DEFINER Functions

Prefer SECURITY INVOKER where possible.

If SECURITY DEFINER is required:

- Justify elevated privileges.
- Restrict EXECUTE permissions.
- Use a safe search_path.
- Schema-qualify database objects.
- Validate authorization internally.
- Avoid unsafe dynamic SQL.
- Review function ownership.
- Test unauthorized invocation.

Never expose unrestricted privileged
functions to anonymous users.

## 14.3 Database Migrations

- Store migrations in Git.
- Review RLS and grants together.
- Test migrations before production.
- Avoid unreviewed destructive changes.
- Preserve financial history.
- Document rollback limitations.

---

# 15. SUPABASE KEY SECURITY

## 15.1 Publishable Keys

Supabase publishable keys may be
used in the Flutter client.

They do not grant unrestricted data access
when the API, grants, and RLS are configured
correctly.

Do not mistake a publishable key
for a substitute for authorization.

## 15.2 Secret Keys

Supabase secret/service-role credentials
must remain on trusted infrastructure.

Never store them in:

- Flutter source code
- Flutter Web build output
- Public repositories
- Public configuration files
- Browser-accessible JavaScript
- Client-side local storage

Secret/service-role access may bypass RLS.

## 15.3 Credential Management

- Use managed secrets storage.
- Restrict who can access credentials.
- Separate environments.
- Rotate credentials when appropriate.
- Rotate immediately after suspected leakage.
- Monitor privileged credential usage.
- Never print secrets in CI logs.

---

# 16. EDGE FUNCTION SECURITY

Edge Functions handle operations that
require trusted execution.

Examples:

- Checkout creation
- Payment verification
- Bank receipt approval
- Protected document authorization
- Video playback authorization
- Privileged enrollment management

## 16.1 Protected Function Rules

- Authenticate callers.
- Verify current authorization.
- Validate request data.
- Reject unknown input fields where appropriate.
- Apply rate limits.
- Return controlled errors.
- Avoid leaking internal information.
- Record meaningful security events.

## 16.2 Public Webhook Exceptions

Some payment providers require
publicly reachable webhook endpoints.

Such endpoints may need Supabase
JWT verification disabled.

If so:

- Verify the provider's required signature
  or authentication mechanism.
- Verify the raw payload as required.
- Reject invalid notifications.
- Prevent replay or duplicate processing.
- Do not expose privileged functionality.

Disabling platform JWT verification
does not mean disabling security.

## 16.3 Service Privileges

Privileged backend clients must be
created only within trusted execution.

Never return privileged credentials
to Flutter or external callers.

---

# 17. API SECURITY

All application APIs must follow
secure request handling practices.

## 17.1 Input Validation

Validate:

- Required fields
- Types
- Formats
- Lengths
- Identifier validity
- Allowed enumeration values
- File metadata
- Business-state constraints

Frontend validation is for usability.

Backend validation is authoritative.

## 17.2 Output Protection

- Return only necessary fields.
- Avoid exposing internal diagnostics.
- Avoid returning privileged database data.
- Use consistent error codes.
- Avoid leaking sensitive identifiers.
- Redact private metadata where appropriate.

## 17.3 Rate Limiting

Apply appropriate limits to:

- Authentication attempts
- Password recovery
- Checkout creation
- Receipt uploads
- Payment status polling
- Protected content authorization
- Expensive search requests
- Administrative operations

## 17.4 CORS

Restrict browser origins appropriately.

CORS is not an authentication
or authorization mechanism.

Never rely on CORS alone
to protect an endpoint.

---

# 18. PAYMENT GATEWAY SECURITY

Payment verification is one of
the highest-risk business operations.

## 18.1 Payment Rules

- Orders must be created on the backend.
- Prices must come from trusted records.
- Amount and currency must be validated.
- Payment notifications must be authenticated.
- Provider transaction references must be checked.
- Duplicate events must be handled safely.
- Enrollment must follow verified payment.

Never grant access based only on:

- Frontend success state
- Redirect query parameter
- Client-provided payment ID
- Unverified callback
- User-controlled payment status

## 18.2 Payment Processing Flow

1. Student selects a course.
2. Backend creates a pending order.
3. Backend determines authoritative price.
4. Provider checkout is initialized.
5. Student completes provider checkout.
6. Provider sends confirmation.
7. Backend authenticates the notification.
8. Backend validates amount and currency.
9. Backend validates order and payment status.
10. Database transaction finalizes payment.
11. Course entitlement is granted.
12. Audit event is recorded.

## 18.3 Idempotency

Payment processing must tolerate retries.

Implement:

- Unique provider event references
- Unique payment transaction constraints
- Atomic state transitions
- Safe duplicate callback responses
- Concurrency protection

A repeated successful event must not
create unintended duplicate enrollments.

## 18.4 Refunds and Chargebacks

Refund and chargeback handling must
follow approved business rules.

- Record financial state changes.
- Validate trusted provider events.
- Apply approved entitlement policies.
- Preserve historical transaction records.
- Avoid deleting financial audit evidence.

## 18.5 Card Data

Use an approved hosted or provider-managed
payment flow where practical.

Do not collect or store raw card credentials
inside the Flutter application or database.

Applicable payment industry obligations
must be reviewed with the selected provider.

---

# 19. BANK TRANSFER SECURITY

Bank receipt verification requires
both technical and human controls.

## 19.1 Receipt Rules

- Store receipts privately.
- Authorize uploads.
- Restrict permitted file types.
- Limit file sizes.
- Validate file content.
- Prevent public object listing.
- Limit finance staff access.
- Retain review history.

## 19.2 Payment Approval

A submitted receipt must not
automatically unlock a course.

The administrator must independently
verify that payment reached
the official bank account.

## 19.3 Approval Requirements

Record:

- Order ID
- Submission ID
- Payment reference
- Reviewer ID
- Decision
- Review timestamp
- Verification notes
- Associated enrollment action

## 19.4 Fraud Protection

Flag potentially suspicious patterns:

- Reused transaction references
- Duplicate receipt submissions
- Amount mismatches
- Repeated rejected submissions
- Unusual approval activity

A flag is not proof of fraud.

Provide fair manual review procedures.

## 19.5 Concurrency

Two administrators must not
finalize conflicting decisions.

Use trusted transactional state changes.

An already finalized submission
must not be silently approved again.

---

# 20. FILE UPLOAD SECURITY

Uploaded files must be treated
as untrusted content.

## 20.1 Allowed Files

Allowed file formats must be defined
per use case.

Example receipt candidates:

- JPEG
- PNG
- PDF

Final formats and maximum sizes
require project approval.

## 20.2 Validation Requirements

- Validate user authorization.
- Validate declared extension.
- Validate MIME type.
- Inspect actual file signatures.
- Reject unsupported file types.
- Apply file-size limits.
- Use generated storage object names.
- Avoid trusting original filenames.
- Prevent path traversal.
- Apply scanning where feasible.

A MIME type supplied by the browser
must not be trusted by itself.

## 20.3 File Viewing

Receipt previews must not execute
untrusted scripts or active content.

Use isolated or safely configured
document viewers where necessary.

Consider malware scanning and
content disarm/reconstruction
for supported high-risk formats.

## 20.4 Storage Handling

Upload and deletion operations must
use authorized storage APIs.

Do not directly manipulate storage
metadata as a substitute for
proper object lifecycle operations.

---

# 21. PRIVATE STORAGE SECURITY

Recommended private asset groups:

- Paid PDFs
- Bank receipts
- Paid lesson images
- Restricted course documents
- Private administrative attachments

## 21.1 Storage Requirements

- Private buckets.
- Strict access policies.
- Backend entitlement verification.
- Limited access grants.
- No permanent public links.
- No unrestricted listing.
- Appropriate access logging.
- Defined retention rules.

## 21.2 Public Storage

Public buckets should contain only
approved non-sensitive assets.

Examples:

- Published thumbnails
- Public marketing images
- Approved public icons

Never upload financial receipts
or valuable paid PDFs to public buckets.

---

# 22. PROTECTED PDF SECURITY

PDF security is a major business priority.

However, security must be represented honestly.

## 22.1 Required Protection Layers

1. Authenticated user identity
2. Course entitlement verification
3. Private document storage
4. Controlled document delivery
5. Limited access lifetime
6. Personalized watermarking
7. Secure reader integration
8. Reasonable access monitoring

## 22.2 Signed URL Security

Signed URLs are bearer-style links.

Anyone who obtains a valid signed URL
may be able to access the resource.

Requirements:

- Use limited expiry periods.
- Generate URLs after authorization.
- Avoid placing URLs in routine logs.
- Avoid unnecessary browser exposure.
- Evaluate CDN cache behavior.
- Reauthorize new access requests.

Expiry does not guarantee immediate
revocation of previously cached content.

## 22.3 PDF Download Controls

The UI may:

- Omit download buttons.
- Omit print buttons.
- Restrict reader menus.
- Avoid exposing direct file links.
- Display personalized watermarks.

These controls are deterrents.

They do not make browser-delivered
file bytes impossible to extract.

## 22.4 Watermark Security

Watermarks should be:

- Student-specific
- Traceable
- Readable
- Privacy-conscious
- Difficult to remove casually

A client-side watermark overlay
does not modify the underlying PDF.

If delivered file bytes must carry
a watermark, generate a server-side
watermarked derivative or equivalent
protected page representation.

## 22.5 Screenshot Limitations

Flutter Web cannot guarantee
blocking of:

- Operating system screenshots
- Screen recording tools
- Browser developer tools
- External camera recording
- Determined authorized copying

Never promise 100% prevention.

Do not install browser-side controls
that pretend to provide OS-level protection.

## 22.6 Accessibility

Protection measures must not
unnecessarily prevent:

- Reading
- Zooming
- Keyboard navigation
- Accessible interaction
- Legitimate student accommodations

Readable learning content remains
an essential product requirement.

---

# 23. VIDEO CONTENT SECURITY

Paid video content must require
active course authorization.

## 23.1 Required Controls

- Protected video storage or hosting
- Backend authorization
- Limited playback sessions
- No permanent public media URLs
- Protected provider credentials
- Appropriate session expiration
- Controlled access after revocation

## 23.2 Streaming Limitations

Signed playback links and browser
controls do not guarantee DRM.

Video protection capabilities depend
on the selected provider and platform.

Do not claim complete recording prevention.

## 23.3 Video Access Tests

Test:

- Unauthenticated playback request
- Unpaid student playback request
- Valid enrolled student playback
- Expired entitlement
- Revoked enrollment
- Expired playback authorization

---

# 24. FLUTTER WEB SECURITY

Flutter Web runs in an
untrusted browser environment.

## 24.1 Browser Security Requirements

- Enforce HTTPS.
- Configure secure hosting headers.
- Minimize third-party scripts.
- Protect against XSS.
- Avoid exposing server secrets.
- Treat browser storage as untrusted.
- Protect sensitive API interactions.

## 24.2 Rich Text Security

Course descriptions and lessons
may contain rich formatting.

If HTML or external content is supported:

- Sanitize untrusted markup.
- Reject dangerous script content.
- Restrict unsafe links.
- Validate embedded media.
- Use approved rendering components.

Do not execute untrusted lesson HTML
inside a privileged application context.

## 24.3 Recommended Security Headers

Evaluate:

- Content-Security-Policy
- Strict-Transport-Security
- X-Content-Type-Options
- Referrer-Policy
- Permissions-Policy
- Frame-ancestors restrictions

Header configuration must be tested
with Flutter and approved integrations.

## 24.4 CSRF

If any backend endpoints authenticate
using automatically attached cookies,
implement appropriate CSRF controls.

Bearer-token APIs require their own
authentication and authorization protections.

## 24.5 Browser Caching

Private documents and sensitive API data
must have deliberate caching policies.

Avoid intentional persistent browser caching
of raw paid course documents.

Client-side caching controls cannot
guarantee deletion of copied content.

---

# 25. ADMIN DASHBOARD SECURITY

The admin interface handles
sensitive operational functions.

## 25.1 Required Protections

- Authenticated administrator session
- Backend role checks
- Least privilege
- Strong authentication
- Audit logging
- Safe session expiration
- Secure administrative APIs

## 25.2 Sensitive Actions

Examples:

- Approve payment
- Reject payment
- Grant enrollment
- Revoke enrollment
- Change admin role
- Delete course
- Change production bank details

These operations require explicit
authorization and appropriate audit records.

## 25.3 Administrative Confirmation

Use clear confirmation workflows
for high-impact operations.

Confirmation dialogs improve usability.

They do not replace backend security.

## 25.4 Sensitive Data Display

Show only information necessary
for the administrator's task.

Avoid unnecessary exposure of:

- Full financial account details
- Student private information
- Access tokens
- Internal credentials
- Private file storage paths

---

# 26. DATA PRIVACY AND ETHICS

Student privacy is a core requirement.

## 26.1 Data Minimization

Collect only information needed for:

- Account creation
- Course delivery
- Payment processing
- Customer support
- Security
- Applicable legal obligations

Do not collect unnecessary personal details.

## 26.2 Transparency

Students should understand:

- Data collected
- Purpose of collection
- Relevant service providers
- Retention periods
- Privacy rights
- Watermarking
- Necessary security logging

## 26.3 Financial Information

Bank receipts may contain
sensitive financial information.

Restrict access, minimize retention,
and avoid unnecessary reproduction.

## 26.4 Account Deletion

Define a documented deletion process.

Account deletion may need to preserve
certain transaction records where legally
or operationally required.

Do not silently retain unnecessary
personal information indefinitely.

## 26.5 Ethical Monitoring

Allowed with appropriate disclosure:

- Security event logging
- Payment verification logs
- Course access event logging
- Administrative audit logs

Not permitted:

- Secret student screen recording
- Unauthorized device surveillance
- Collection unrelated to system purpose
- Deceptive tracking practices

## 26.6 Legal Review

Applicable privacy and consumer laws
must be evaluated before production launch.

If operating in Sri Lanka, review
the applicable Personal Data Protection
Act requirements and current amendments.

This document does not substitute
for jurisdiction-specific legal advice.

---

# 27. DATA CLASSIFICATION

Classify data by sensitivity.

## PUBLIC

Examples:

- Published course titles
- Approved course descriptions
- Public thumbnails

## INTERNAL

Examples:

- Internal development documents
- Non-sensitive operational metrics
- Engineering planning records

## CONFIDENTIAL

Examples:

- Student profiles
- Orders
- Enrollments
- Learning history
- Course content
- Administrative records

## RESTRICTED

Examples:

- Private bank receipts
- Production secrets
- Payment verification credentials
- Authentication tokens
- Sensitive financial records

Controls must match data classification.

Never place restricted data
in public repositories or buckets.

---

# 28. DATA RETENTION

Retention must be defined
per data category.

Required categories:

- User profiles
- Authentication metadata
- Payment records
- Bank receipts
- Course progress
- Security logs
- Audit records
- Backups
- Support records

Each category requires:

- Retention purpose
- Retention duration
- Access restrictions
- Deletion procedure
- Legal justification where applicable

Do not invent legal retention periods.

Finalize periods after business
and legal requirements are reviewed.

---

# 29. LOGGING AND AUDIT SECURITY

## 29.1 Security Events

Log relevant events such as:

- Failed authorization
- Admin role changes
- Payment verification failures
- Payment approvals/rejections
- Enrollment grants/revocations
- Suspicious repeated requests
- Restricted content access failures

## 29.2 Safe Log Content

Recommended fields:

- Event ID
- Timestamp
- Request correlation ID
- Operation
- Outcome
- Safe error code
- Pseudonymous actor reference

## 29.3 Prohibited Log Content

Never log:

- Plaintext passwords
- Authentication tokens
- Payment gateway secrets
- Private API keys
- Full bank receipts
- Raw card information
- Complete signed document URLs

## 29.4 Audit Integrity

Important administrative audit records
must be protected against unauthorized
editing and deletion.

Provide appropriate retention
and controlled administrative access.

## 29.5 Monitoring

Monitor:

- Unusual payment behavior
- Repeated authorization failures
- Sensitive endpoint abuse
- Unexpected administrative changes
- Service authentication failures
- Private content delivery errors

Avoid treating every failed login
as confirmed malicious behavior.

---

# 30. SECRET MANAGEMENT

## 30.1 Secret Storage

Use trusted environment configuration
or an approved secrets manager.

Do not place production secrets in Git.

## 30.2 Environment Separation

Maintain distinct credentials for:

- Development
- Staging
- Production

## 30.3 Secret Rotation

Rotate secrets:

- After suspected compromise
- After confirmed credential exposure
- When provider policy requires it
- During approved security maintenance

Document dependency and service impact.

## 30.4 Emergency Rotation

After a confirmed leak:

1. Identify affected credentials.
2. Restrict further unauthorized use.
3. Rotate or revoke compromised secrets.
4. Update trusted services.
5. Validate normal functionality.
6. Review related logs.
7. Assess possible data exposure.
8. Record incident evidence.

Removing a leaked secret from Git history
does not make the credential safe again.

---

# 31. GITHUB SECURITY RULES

Repository:
Private during initial development.

Default Branch:
main

## 31.1 Repository Protection

- Restrict repository access.
- Use individual GitHub accounts.
- Prefer MFA for maintainers.
- Protect main where supported.
- Use pull requests.
- Require passing checks.
- Avoid force-pushing shared release branches.
- Review sensitive changes.

GitHub enforcement availability
depends on the repository plan.

## 31.2 Required Security Files

- SECURITY.md
- AGENTS.md
- CONTRIBUTING.md
- .gitignore
- .github/dependabot.yml
- .github/workflows/
- CODEOWNERS where appropriate

## 31.3 Secret Scanning

Use GitHub secret scanning
or an approved equivalent.

Availability may depend
on repository settings and plan.

Treat a detected committed secret
as potentially compromised.

## 31.4 Dependency Management

- Monitor dependency vulnerabilities.
- Review dependency updates.
- Check package licenses.
- Avoid abandoned dependencies.
- Pin and review relevant versions.
- Test updates before deployment.

## 31.5 GitHub Actions Security

- Minimize GITHUB_TOKEN permissions.
- Avoid injecting untrusted PR content
  into shell commands.
- Do not expose production secrets
  to untrusted pull request workflows.
- Review third-party Actions.
- Prefer commit-SHA pinning for
  third-party Actions where practical.
- Restrict production deployment credentials.
- Use protected deployment environments
  where available.

## 31.6 Production Deployments

No AI agent or developer may deploy
unreviewed security-critical changes.

Use documented approval and
deployment procedures.

---

# 32. SECURITY TESTING

Security controls must be tested
at multiple application layers.

## 32.1 Authentication Tests

- Invalid login
- Expired session
- Unauthorized password reset
- Logout behavior
- Revoked session behavior
- Privileged account protection

## 32.2 Authorization Tests

- Student accessing another profile
- Student viewing another order
- Student modifying payment status
- Student creating paid enrollment
- Non-admin approving a payment
- Unauthorized content access
- Role escalation attempts

## 32.3 Payment Tests

- Valid verified payment
- Forged provider notification
- Incorrect amount
- Incorrect currency
- Unknown order
- Duplicate callback
- Concurrent callback
- Replayed provider notification
- Delayed payment notification
- Refund handling

## 32.4 Bank Transfer Tests

- Valid receipt submission
- Invalid file type
- Oversized upload
- Unauthorized receipt access
- Duplicate receipt submission
- Non-admin approval
- Concurrent approval
- Rejection workflow
- Approved payment enrollment

## 32.5 PDF Access Tests

- Guest requests private PDF
- Unpaid student requests PDF
- Enrolled student requests PDF
- Student accesses another private asset
- Revoked student requests new access
- Expired access authorization
- Signed URL leakage risk review
- Appropriate watermark behavior

## 32.6 Database Security Tests

- RLS SELECT behavior
- RLS INSERT behavior
- RLS UPDATE behavior
- RLS DELETE behavior
- Storage access rules
- Function EXECUTE permissions
- Invalid ownership
- Administrative boundaries

## 32.7 Security Regression

Security tests must run after changes
to related code, grants, policies,
database functions, or configuration.

---

# 33. AUTOMATED SECURITY CHECKS

Minimum CI pipeline:

1. Dart formatting
2. Flutter static analysis
3. Unit tests
4. Widget tests
5. Database permission tests
6. Backend function tests
7. Dependency checks
8. Secret detection
9. Production build verification

Example Flutter commands:

dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release

Database tests:

supabase test db

Additional security checks must be
configured based on approved tooling.

Never claim automated checks passed
unless they actually ran successfully.

---

# 34. INCIDENT RESPONSE POLICY

A security incident may involve:

- Compromised credentials
- Data exposure
- Unauthorized payment approval
- Database intrusion
- Private document exposure
- Malicious upload
- Unavailable critical services
- Unauthorized administrator behavior

## 34.1 Incident Response Stages

STAGE 1:
Detect

STAGE 2:
Triage

STAGE 3:
Contain

STAGE 4:
Investigate

STAGE 5:
Eradicate

STAGE 6:
Recover

STAGE 7:
Review

## 34.2 Incident Containment

Possible actions:

- Revoke compromised credentials.
- Restrict affected accounts.
- Disable vulnerable endpoints.
- Pause unsafe financial operations.
- Invalidate exposed access grants.
- Isolate affected resources.
- Preserve relevant evidence.

Containment must consider
business continuity and data integrity.

## 34.3 Investigation

Determine:

- What happened?
- When did it occur?
- Which systems were affected?
- Which data may be exposed?
- Which accounts were involved?
- Which controls failed?
- Is the threat still active?

## 34.4 Recovery

- Apply verified fixes.
- Restore systems safely.
- Validate permissions.
- Check payment consistency.
- Confirm critical flows.
- Monitor for recurrence.

## 34.5 Notification

Determine whether students,
partners, regulators, or other parties
must be notified.

Follow applicable legal obligations
and the approved incident communication plan.

## 34.6 Post-Incident Review

Document:

- Root cause
- Impact
- Timeline
- Response actions
- Corrective changes
- Test coverage improvements
- Preventive controls

Do not conceal material security incidents.

---

# 35. BACKUP SECURITY

Backups are sensitive assets.

## 35.1 Backup Scope

Include:

- PostgreSQL database
- Private PDF storage
- Bank receipt storage
- Relevant course assets
- Application configuration
- Important operational metadata

## 35.2 Supabase Backup Limitation

Database backups do not automatically
include the actual objects in Storage.

Stored file bytes require a separate
backup and recovery strategy.

## 35.3 Backup Requirements

- Restrict backup access.
- Encrypt backups appropriately.
- Separate backup credentials.
- Define retention periods.
- Keep recoverable copies.
- Test restoration periodically.
- Avoid exposing backups publicly.

## 35.4 Recovery Objectives

Define:

RPO:
Recovery Point Objective

RTO:
Recovery Time Objective

Actual values require approval
based on business needs and hosting costs.

---

# 36. THIRD-PARTY SECURITY

External providers may include:

- Supabase
- Payment gateway
- Video streaming provider
- Email provider
- Analytics service
- Monitoring service

Before integration, evaluate:

- Security documentation
- Data handling practices
- Hosting location
- Relevant compliance obligations
- Authentication methods
- Secret management
- Incident response procedures
- Cost and operational reliability

Avoid granting providers
unnecessary access to student data.

---

# 37. SECURITY AND ACCESSIBILITY

Security must not create
unnecessary exclusion.

Examples:

- PDF zoom must remain available.
- Payment errors must be understandable.
- Keyboard interaction must remain possible.
- Accessible alternatives must be evaluated.
- Security warnings must be readable.
- Important messages must not rely on color.

Restrictions designed to discourage copying
must be assessed against legitimate
student accessibility requirements.

---

# 38. SECURITY RULES FOR AI AGENTS

AI agents must:

1. Read SECURITY.md.
2. Read AGENTS.md.
3. Identify security implications.
4. Follow approved architecture.
5. Use test-driven development for
   critical security-sensitive logic.
6. Avoid introducing unapproved privileges.
7. Verify database authorization.
8. Review input validation.
9. Protect secrets.
10. Report risks honestly.

AI agents must NEVER:

- Disable RLS to fix application errors.
- Grant paid access from client code.
- Bypass payment verification.
- Expose private receipts.
- Commit production credentials.
- Log access tokens.
- Use real customer data for routine tests.
- Invent completed security reviews.
- Hide vulnerabilities.
- Weaken permissions silently.
- Deploy critical changes without approval.
- Promise impossible screenshot protection.

---

# 39. SECURITY EXCEPTIONS

Some controls may require
approved temporary exceptions.

An exception must record:

- Security control
- Reason for exception
- Affected component
- Risk assessment
- Compensating controls
- Responsible owner
- Approval
- Expiration date
- Remediation plan

Exceptions must not be permanent
by default.

Known critical vulnerabilities
must not be casually accepted.

---

# 40. PRODUCTION SECURITY CHECKLIST

Before production launch:

## Identity and Access

- [ ] Authentication flows tested.
- [ ] Email verification configured.
- [ ] Administrative permissions reviewed.
- [ ] MFA approach finalized for privileged users.
- [ ] Session handling tested.
- [ ] Account recovery tested.

## Database

- [ ] Required RLS policies enabled.
- [ ] Database grants reviewed.
- [ ] Cross-user access tests passed.
- [ ] Privileged function permissions reviewed.
- [ ] Database migrations reviewed.

## Payments

- [ ] Gateway callback verification tested.
- [ ] Amount validation tested.
- [ ] Currency validation tested.
- [ ] Duplicate callback protection tested.
- [ ] Refund handling reviewed.
- [ ] Financial audit logging verified.

## Bank Transfers

- [ ] Private receipt storage verified.
- [ ] Upload validation tested.
- [ ] Finance permissions tested.
- [ ] Concurrent approval protection tested.
- [ ] Rejection workflow tested.
- [ ] Approval audit history verified.

## Course Content

- [ ] Private PDFs protected.
- [ ] Unauthorized content access tested.
- [ ] Signed URL behavior reviewed.
- [ ] Watermarks evaluated.
- [ ] Video authorization tested.
- [ ] Revoked access behavior tested.
- [ ] PDF protection limitations documented.

## Application

- [ ] HTTPS configured.
- [ ] Relevant security headers configured.
- [ ] Rich-content rendering reviewed.
- [ ] Secrets excluded from Flutter Web.
- [ ] Dependencies reviewed.
- [ ] Sensitive logs redacted.
- [ ] Appropriate rate limits configured.

## Operations

- [ ] Backups configured.
- [ ] Object storage backup strategy configured.
- [ ] Restore procedure tested.
- [ ] Incident response contacts defined.
- [ ] Monitoring configured.
- [ ] Production deployment reviewed.
- [ ] Critical findings resolved.
- [ ] Privacy and retention policies reviewed.

No production launch without
a documented security release decision.

---

# 41. SECURITY DEFINITION OF DONE

A security-sensitive task is complete when:

- [ ] Related requirements are satisfied.
- [ ] Threats are considered.
- [ ] Input validation is implemented.
- [ ] Backend authorization is verified.
- [ ] Database policies are correct.
- [ ] Secrets are protected.
- [ ] Relevant tests are executed.
- [ ] Negative tests are included.
- [ ] Sensitive logging is reviewed.
- [ ] Error handling is secure.
- [ ] Documentation is updated.
- [ ] Required review is completed.
- [ ] Known limitations are reported.

Passing UI tests alone does not
prove that a feature is secure.

---

# 42. OPEN SECURITY DECISIONS

SEC-OPEN-001:
Finalize vulnerability reporting contact.

SEC-OPEN-002:
Approve production MFA requirements.

SEC-OPEN-003:
Select payment gateway and verification method.

SEC-OPEN-004:
Define bank receipt size and type limits.

SEC-OPEN-005:
Finalize PDF delivery strategy.

SEC-OPEN-006:
Finalize watermark privacy requirements.

SEC-OPEN-007:
Select protected video provider.

SEC-OPEN-008:
Approve audit log retention policy.

SEC-OPEN-009:
Approve personal data retention policy.

SEC-OPEN-010:
Finalize backup and recovery objectives.

SEC-OPEN-011:
Choose incident monitoring tools.

SEC-OPEN-012:
Approve security testing strategy.

SEC-OPEN-013:
Review applicable privacy obligations.

SEC-OPEN-014:
Approve production administrator access policy.

SEC-OPEN-015:
Define acceptable residual content-copy risks.

All open decisions must be resolved
before dependent production release.

---

# 43. SECURITY POLICY MAINTENANCE

Review this document:

- Before production launch
- After major architecture changes
- After significant security incidents
- After major provider changes
- During periodic security reviews

Security policy changes should:

1. Explain the reason.
2. Identify affected components.
3. Evaluate new risks.
4. Update relevant tests.
5. Receive appropriate approval.
6. Be recorded in Git.

Update related documents when necessary.

---

# 44. FINAL SECURITY DIRECTIVE

Acedra must protect student trust,
financial integrity, and valuable
educational content.

The application must enforce:

- Secure authentication
- Least-privilege authorization
- Trusted payment verification
- Safe bank transfer approvals
- Private content storage
- Protected document delivery
- Responsible data processing
- Secure development practices
- Auditable administrative operations
- Reliable incident response
- Verified security testing

Security controls must be practical,
transparent, maintainable, and testable.

No frontend component may independently
grant paid course access.

No unverified payment may unlock a course.

No student may access another student's
private financial information.

No server-side secret may be embedded
in Flutter Web.

No content protection feature may claim
that browser screenshots or recordings
are impossible.

No critical security change may be
considered complete without verification.

SECURITY BY DESIGN.
PRIVACY BY DESIGN.
LEAST PRIVILEGE.
DEFENSE IN DEPTH.
TRUSTED PAYMENTS.
PROTECTED CONTENT.
AUDITABLE OPERATIONS.
VERIFIABLE SECURITY.

END OF SECURITY POLICY
