
# SOFTWARE REQUIREMENTS SPECIFICATION
# Course Selling Application

Document ID: CSA-SRS-001
Version: 1.1
Status: Approved Requirements Baseline - Explicit Downstream Gates Retained
Project: Course Selling Application
Primary Platform: Flutter Web
Future Platforms: Android and iOS
Development Approach: Agile + Clean Architecture
Classification: Internal Project Documentation

Review date: 2026-10-11
Review evidence: [CSA-001/002 SRS and MVP baseline](docs/requirements/CSA-001-002-SRS-MVP.md).
Payment provider/currency confirmed by project owner: PayHere / LKR, Sri Lanka.
The project owner approved the MVP scope, role permissions and bank policy on
2026-10-11. The linked [approval record](docs/requirements/README.md) records
the accepted baseline and unresolved operational/release gates. This approval
does not claim implementation, test completion or production readiness.

---

# 1. INTRODUCTION

## 1.1 Purpose

This Software Requirements Specification (SRS)
defines the functional and non-functional
requirements of the Course Selling Application.

The system will allow students to discover,
purchase, and access digital educational courses.

Administrators will manage courses, students,
payments, learning content, and enrollments.

The application must deliver:

- Secure account management
- Professional course marketplace
- Reliable online payment processing
- Manual bank transfer verification
- Protected educational content
- Premium PDF reading experience
- Responsive student and admin interfaces
- Dark and light mode support
- Scalable and maintainable architecture
- Strong security and privacy controls

This document serves as the requirements
baseline for design, implementation, testing,
and acceptance.

---

## 1.2 Product Vision

Build a modern, secure, professional
e-learning commerce platform.

Students should be able to purchase courses
and study comfortably on supported devices.

Administrators should have complete,
role-appropriate operational control.

The system should use free and open-source
development tools where practical while
maintaining production-level quality.

---

## 1.3 Project Objectives

OBJ-001:
Provide a simple and trustworthy way for
students to purchase online courses.

OBJ-002:
Provide secure access to purchased content.

OBJ-003:
Provide a high-quality video, text, image,
and PDF learning experience.

OBJ-004:
Support automatic online payment confirmation
and manual bank transfer approval.

OBJ-005:
Provide a professional administrative
management interface.

OBJ-006:
Protect student information, payments,
and proprietary course materials.

OBJ-007:
Support responsive web layouts and
light/dark application themes.

OBJ-008:
Establish a maintainable foundation for
future mobile applications and expansion.

---

# 2. DOCUMENT CONVENTIONS

## 2.1 Requirement Identification

Every requirement has a unique identifier.

Examples:

FR-AUTH-001
FR-PAY-001
FR-PDF-001
NFR-SEC-001

FR = Functional Requirement
NFR = Non-Functional Requirement
BR = Business Rule

---

## 2.2 Priority Classification

MUST:
Required for MVP acceptance.

SHOULD:
Important, but may be scheduled after MVP.

COULD:
Optional enhancement.

FUTURE:
Outside the initial release.

Requirements marked MUST are release-blocking
unless an approved scope change is recorded.

---

## 2.3 Requirement Language

"Shall" indicates a mandatory requirement.

"Should" indicates a recommendation.

"May" indicates an optional capability.

Requirements should be independently testable.

---

# 3. PRODUCT SCOPE

## 3.1 In Scope - MVP

All MUST requirements remain binding. SHOULD features are deferred unless
explicitly promoted. The approved [MVP acceptance matrix](docs/requirements/CSA-001-002-SRS-MVP.md)
defines verification gates. Checkout supports one course per order; carts and
bundles are outside MVP. Public curriculum preview contains approved metadata;
playable free lessons remain optional under FR-CAT-012 and expose no paid assets.

The initial application shall include:

1. Student registration and authentication
2. Student profiles
3. Public course marketplace
4. Course search and filtering
5. Course details and curriculum previews
6. Online payment integration
7. Bank transfer receipt submission
8. Administrative payment approval
9. Purchased course enrollment
10. Student learning dashboard
11. Video lessons
12. Text lessons
13. Image lessons
14. Protected PDF reader
15. Learning progress tracking
16. Admin dashboard
17. Course management
18. Student management
19. Payment and enrollment management
20. Responsive web interfaces
21. Dark and light modes
22. Basic email notifications
23. Security controls and audit logging

---

## 3.2 Outside MVP Scope

The following features are reserved for
future development:

- Native Android application
- Native iOS application
- Live classes
- Course subscriptions
- Affiliate marketing
- Multi-instructor marketplace
- Advanced quizzes
- Graded assignments
- Automatic certificates
- AI learning assistants
- Gamification
- Advanced recommendation engines
- Offline protected course downloads
- Community discussion forums

These features require separate approval
before being added to the MVP.

---

# 4. USER ROLES

The approved [permission matrix](docs/requirements/CSA-003-ROLES.md) is normative
for operation-level authority. Course authoring is assignment-scoped; only super
admins publish/unpublish, change prices and issue audited manual grants. Finance
and super-admin operations require MFA in production. Self-approval of purchases,
self-role changes and self-issued complimentary grants are prohibited. Current
roles and assignments are checked on each sensitive request. No role bypasses
independent payment verification, entitlement checks or audit requirements.

## 4.1 Guest User

A guest is an unauthenticated visitor.

Permissions:

- View public landing pages
- Browse published courses
- Search available courses
- View course details
- View permitted course previews
- Register and log in

Restrictions:

- Cannot access purchased lessons
- Cannot access private PDFs
- Cannot view student information
- Cannot perform administrative operations

---

## 4.2 Registered Student

Permissions:

- Manage own profile
- Browse and purchase courses
- Submit bank transfer receipts
- View own payment status
- View own purchase history
- Access actively enrolled courses
- Track learning progress
- Read authorized course content

Restrictions:

- Cannot access unpaid course content
- Cannot view other students' private data
- Cannot approve payments
- Cannot modify course ownership or prices
- Cannot perform admin operations

---

## 4.3 Content Manager

Permissions:

Course operations require a current authorized course assignment or an
explicitly authorized course-creation operation. A role label alone does not
grant access to every course.

- Create and edit courses
- Manage curriculum
- Upload lessons and learning resources
- Course publishing and price changes require the separate super-admin authority

Restrictions:

- Cannot approve financial transactions
  unless separately assigned that permission
- Cannot access unrelated private student data

---

## 4.4 Finance Administrator

Permissions:

- Review submitted receipts
- Verify bank transfer payments
- Approve or reject payments
- View relevant order history
- View relevant financial reports

Restrictions:

- Cannot modify unrelated course content
- Cannot bypass financial audit requirements

---

## 4.5 Super Administrator

Permissions:

- Manage administrative roles
- Manage courses and users
- Manage payments and enrollments
- Access operational reports
- Configure authorized system settings
- Review audit records

All privileged operations must be authorized
and audited where appropriate.

---

# 5. SYSTEM OVERVIEW

## 5.1 Main Subsystems

The application shall contain:

1. Authentication System
2. Course Marketplace
3. Course Management System
4. Checkout and Payment System
5. Enrollment Management System
6. Learning Management System
7. Protected Content System
8. PDF Reading System
9. Administration System
10. Notification System
11. Reporting and Audit System

---

## 5.2 Primary Technology Constraints

The current preferred technology stack is:

Frontend:
- Flutter
- Dart
- Material 3
- Riverpod
- go_router

Backend:
- Supabase
- PostgreSQL
- Supabase Auth
- Edge Functions
- Row Level Security

Storage:
- Private object storage

Version Control:
- Git and GitHub

Testing:
- Flutter tests
- Integration tests
- Backend security tests

Final package and provider selections
must be documented in ARCHITECTURE.md.

---

# 6. FUNCTIONAL REQUIREMENTS

# 6.1 AUTHENTICATION SYSTEM

FR-AUTH-001 [MUST]
The system shall allow users to register
using email and password.

FR-AUTH-002 [MUST]
The system shall validate required
registration fields.

FR-AUTH-003 [MUST]
The system shall support email verification.

FR-AUTH-004 [MUST]
The system shall allow registered users
to log in securely.

FR-AUTH-005 [MUST]
The system shall provide logout functionality.

FR-AUTH-006 [MUST]
The system shall support password recovery.

FR-AUTH-007 [MUST]
The system shall securely manage user sessions.

FR-AUTH-008 [MUST]
The system shall handle expired or invalid
sessions without granting unauthorized access.

FR-AUTH-009 [MUST]
The system shall prevent unauthorized
administrative operations.

FR-AUTH-010 [SHOULD]
The system should support Google login.

FR-AUTH-011 [SHOULD]
The system should allow users to review
and revoke active sessions.

FR-AUTH-012 [MUST]
The system shall provide understandable
authentication error messages without
revealing sensitive account information.

---

# 6.2 STUDENT PROFILE SYSTEM

FR-PROFILE-001 [MUST]
Students shall be able to view their profiles.

FR-PROFILE-002 [MUST]
Students shall be able to update
their permitted profile information.

FR-PROFILE-003 [MUST]
Students shall be able to change their
password through a secure process.

FR-PROFILE-004 [MUST]
Students shall only be able to access
their own private account information.

FR-PROFILE-005 [MUST]
Students shall be able to view their
purchased and actively enrolled courses.

FR-PROFILE-006 [SHOULD]
Students should be able to upload
a profile picture.

FR-PROFILE-007 [SHOULD]
Students should be able to request
account deletion and data access
through an appropriate privacy process.

FR-PROFILE-008 [MUST]
The system shall retain financial records
only as required by applicable legal and
business retention policies.

---

# 6.3 COURSE MARKETPLACE

FR-CAT-001 [MUST]
The system shall display published courses.

FR-CAT-002 [MUST]
Each course listing shall display
its title, thumbnail, and price.

FR-CAT-003 [MUST]
Students shall be able to search courses.

FR-CAT-004 [MUST]
Students shall be able to filter courses
by category.

FR-CAT-005 [SHOULD]
Students should be able to sort courses
by price, newest, and other supported criteria.

FR-CAT-006 [MUST]
The system shall provide a detailed
course information page.

FR-CAT-007 [MUST]
The course details page shall show:

- Course title
- Description
- Price and currency
- Course thumbnail
- Learning objectives
- Curriculum overview
- Number of lessons
- Instructor information, if applicable
- Enrollment or purchase action

FR-CAT-008 [MUST]
Only published courses shall appear
in the public course marketplace.

FR-CAT-009 [MUST]
Draft or unpublished course content
shall not be exposed to unauthorized users.

FR-CAT-010 [SHOULD]
The system should display related courses.

FR-CAT-011 [MUST]
The system shall clearly distinguish
owned and unpurchased courses.

FR-CAT-012 [SHOULD]
The system should support selected
free preview lessons.

---

# 6.4 COURSE MANAGEMENT

FR-COURSE-001 [MUST]
Authorized administrators shall be able
to create courses.

FR-COURSE-002 [MUST]
Authorized administrators shall be able
to edit course information.

FR-COURSE-003 [MUST]
Each course shall support:

- Title
- Description
- Thumbnail
- Category
- Price
- Currency
- Learning objectives
- Publication status
- Ordered curriculum

FR-COURSE-004 [MUST]
Administrators shall be able to create
sections and lessons.

FR-COURSE-005 [MUST]
Administrators shall be able to
reorder sections and lessons.

FR-COURSE-006 [MUST]
The system shall support these lesson types:

- Video
- Text
- Image
- PDF

FR-COURSE-007 [MUST]
Administrators shall be able to save
courses as drafts.

FR-COURSE-008 [MUST]
Administrators shall be able to publish
and unpublish courses.

FR-COURSE-009 [MUST]
Course modifications shall not silently
invalidate existing purchases.
Unpublishing removes public visibility and new purchases but preserves existing
entitlements. Revocation requires the separately approved audited access policy.

FR-COURSE-010 [MUST]
Permanent course deletion shall require
appropriate authorization and shall not
silently destroy financial or audit records.

FR-COURSE-011 [SHOULD]
Administrators should be able to
preview courses before publication.

FR-COURSE-012 [SHOULD]
The system should support course archiving.

---

# 6.5 CHECKOUT SYSTEM

FR-CHECKOUT-001 [MUST]
A student shall be able to initiate
the purchase of an available course.

FR-CHECKOUT-002 [MUST]
The system shall create a unique order
identifier for each purchase attempt.

FR-CHECKOUT-003 [MUST]
The system shall display an order summary
before payment.

FR-CHECKOUT-004 [MUST]
The order summary shall display:

- Course name
- Final price
- Currency
- Payment method
- Applicable fees or taxes, if any
- Total payable amount

FR-CHECKOUT-005 [MUST]
The system shall support:

1. Online payment gateway
2. Bank transfer

FR-CHECKOUT-006 [MUST]
The authoritative order price shall
be calculated or verified by the backend.

FR-CHECKOUT-007 [MUST]
The system shall not trust a client-provided
price as the source of payment truth.

FR-CHECKOUT-008 [MUST]
Order records shall preserve the amount
and currency agreed at checkout.

FR-CHECKOUT-009 [MUST]
Repeated checkout requests shall not
cause unintended duplicate payments
or enrollments.

FR-CHECKOUT-010 [MUST]
Checkout failures shall display an
understandable recovery path.

MVP Assumption:
One course is purchased per order.
Shopping-cart checkout is outside MVP.

---

# 6.6 ONLINE PAYMENT GATEWAY

FR-PAY-001 [MUST]
The system shall integrate with an
approved online payment provider.

FR-PAY-002 [MUST]
Online payment initiation shall use
the provider's documented secure flow.

FR-PAY-003 [MUST]
The backend shall verify payment
notifications using provider-approved methods.

FR-PAY-004 [MUST]
The backend shall validate the:

- Order identifier
- Payment status
- Payment amount
- Currency
- Provider transaction reference
- Notification authenticity

FR-PAY-005 [MUST]
The system shall not grant enrollment
solely from a frontend success page.

FR-PAY-006 [MUST]
A verified successful payment shall
transition the associated order to paid.

FR-PAY-007 [MUST]
Course access shall be granted only
after successful trusted verification.

FR-PAY-008 [MUST]
Payment processing shall safely handle
duplicate provider notifications.

FR-PAY-009 [MUST]
The system shall handle delayed, failed,
cancelled, and uncertain payment outcomes.

FR-PAY-010 [MUST]
An uncertain payment shall remain pending
verification rather than granting access.

FR-PAY-011 [MUST]
The system shall maintain transaction history.

FR-PAY-012 [MUST]
Students shall be able to view their
own payment status.

FR-PAY-013 [MUST]
The application shall not directly store
raw payment card credentials.

FR-PAY-014 [SHOULD]
The system should send confirmation
when a payment is verified.

---

# 6.7 BANK TRANSFER PAYMENT SYSTEM

The approved [bank verification policy](docs/requirements/CSA-005-BANK-POLICY.md)
is normative. Receipt types are JPEG/PNG/PDF with a 5 MiB maximum and server-side
validation in private storage. A currently authorized independent finance reviewer
must verify settled credit against the exact LKR amount and official destination.
The same verified bank transaction cannot fund multiple orders. Receipt appearance
or submission alone never grants access. Inspection technology, bank destination,
reviewer assignments, retention and exceptional matching remain explicit gates.

FR-BANK-001 [MUST]
Students shall be able to select
bank transfer as a payment method.

FR-BANK-002 [MUST]
The system shall display administrator-
configured bank transfer instructions.

FR-BANK-003 [MUST]
The system shall display the payable
amount, currency, and order reference.

FR-BANK-004 [MUST]
Students shall be able to upload
a payment receipt.

FR-BANK-005 [MUST]
The system shall validate receipt
file type and maximum file size.

FR-BANK-006 [MUST]
Receipts shall be stored privately.

FR-BANK-007 [MUST]
Receipt submission shall create
a pending verification record.

FR-BANK-008 [MUST]
Submitting a receipt shall not
automatically unlock course access.

FR-BANK-009 [MUST]
Authorized finance administrators
shall be able to review receipts.

FR-BANK-010 [MUST]
An administrator shall be able to
approve or reject a receipt after
verifying the actual bank transaction.

FR-BANK-011 [MUST]
Approval shall record:

- Payment identifier
- Reviewer identifier
- Decision
- Timestamp
- Verification reference or notes

FR-BANK-012 [MUST]
Rejected payments shall remain
ineligible for course access.

FR-BANK-013 [MUST]
The student shall be informed
when a receipt is rejected.

FR-BANK-014 [MUST]
Students shall be able to resubmit
a receipt when resubmission is permitted.

FR-BANK-015 [MUST]
An approved bank transfer shall result
in a valid enrollment transaction.

FR-BANK-016 [MUST]
Concurrent approval actions shall not
create duplicate enrollments.

FR-BANK-017 [SHOULD]
The system should flag possible
duplicate payment references.

FR-BANK-018 [MUST]
Only authorized personnel shall
access uploaded bank receipts.

---

# 6.8 ENROLLMENT MANAGEMENT

FR-ENROLL-001 [MUST]
Successful verified purchases shall
create course entitlements.

FR-ENROLL-002 [MUST]
A student shall only access paid content
with a valid course entitlement.

FR-ENROLL-003 [MUST]
The backend shall verify entitlements
before granting protected content access.

FR-ENROLL-004 [MUST]
The system shall prevent duplicate
active enrollments for the same purchase
where duplicates are not intended.

FR-ENROLL-005 [MUST]
Administrators shall be able to view
student course enrollments.

FR-ENROLL-006 [MUST]
Authorized administrators shall be able
to revoke access with a recorded reason.

FR-ENROLL-007 [SHOULD]
Authorized administrators should be able
to grant complimentary access through
an audited workflow.

FR-ENROLL-008 [MUST]
Enrollment state changes shall be auditable.

FR-ENROLL-009 [MUST]
An enrollment shall reference the
student, course, and access-grant source.

FR-ENROLL-010 [MUST]
Access rules for refunds, expired grants,
and revoked enrollments shall be enforced
consistently by the backend.

---

# 6.9 STUDENT LEARNING DASHBOARD

FR-LEARN-001 [MUST]
Students shall have a My Courses page.

FR-LEARN-002 [MUST]
The My Courses page shall display
active enrolled courses.

FR-LEARN-003 [MUST]
Students shall be able to open
an authorized course.

FR-LEARN-004 [MUST]
The system shall display the
course curriculum.

FR-LEARN-005 [MUST]
Students shall navigate between
authorized lessons.

FR-LEARN-006 [MUST]
The system shall save lesson progress.

FR-LEARN-007 [MUST]
Students shall be able to resume learning.
MVP persists completion and the last-opened lesson, plus PDF page/position.
Video timestamp persistence remains SHOULD under FR-VIDEO-005.

FR-LEARN-008 [MUST]
The system shall display course
completion progress.

FR-LEARN-009 [SHOULD]
Students should be able to bookmark lessons.

FR-LEARN-010 [MUST]
Unauthorized lessons shall not reveal
protected learning materials.

---

# 6.10 VIDEO LESSONS

FR-VIDEO-001 [MUST]
The application shall support
video-based course lessons.

FR-VIDEO-002 [MUST]
Authorized students shall be able
to play video lessons.

FR-VIDEO-003 [MUST]
The player shall include:

- Play and pause
- Timeline seek
- Volume control
- Full-screen mode
- Loading and error feedback

FR-VIDEO-004 [SHOULD]
The player should support
multiple playback speeds.

FR-VIDEO-005 [SHOULD]
The system should save video progress.

FR-VIDEO-006 [MUST]
Paid video access shall be checked
by trusted backend mechanisms.

FR-VIDEO-007 [MUST]
Private video content shall not rely
on permanent unrestricted public URLs.

FR-VIDEO-008 [SHOULD]
The player should support captions
when caption files are available.

---

# 6.11 TEXT AND IMAGE LESSONS

FR-TEXT-001 [MUST]
The application shall support
formatted text lessons.

FR-TEXT-002 [MUST]
Text lessons shall support:

- Headings
- Paragraphs
- Lists
- Images
- Links
- Basic tables where appropriate

FR-TEXT-003 [MUST]
Text shall remain readable on
mobile, tablet, and desktop screens.

FR-IMAGE-001 [MUST]
The application shall support
image-based lessons.

FR-IMAGE-002 [MUST]
Images shall preserve aspect ratio.

FR-IMAGE-003 [SHOULD]
Images should support zoom functionality.

FR-IMAGE-004 [MUST]
Paid image assets shall require
appropriate authorization.

FR-IMAGE-005 [SHOULD]
Images should include meaningful
alternative text when applicable.

---

# 6.12 PREMIUM PDF READER

The PDF reader is a high-priority
business-critical module.

## Reading Requirements

FR-PDF-001 [MUST]
Authorized students shall be able
to open protected PDF lessons.

FR-PDF-002 [MUST]
The PDF reader shall render text
clearly at supported zoom levels.

FR-PDF-003 [MUST]
The reader shall support page navigation.

FR-PDF-004 [MUST]
The reader shall support zoom in and out.

FR-PDF-005 [MUST]
The reader shall support fit-to-width.

FR-PDF-006 [MUST]
The reader shall support full-screen
or expanded reading mode.

FR-PDF-007 [MUST]
The reader shall support smooth scrolling
within reasonable device constraints.

FR-PDF-008 [MUST]
The reader shall save the student's
last reading position.

FR-PDF-009 [MUST]
The reader shall adapt to mobile,
tablet, and desktop viewports.

FR-PDF-010 [SHOULD]
The reader should support page thumbnails.

FR-PDF-011 [SHOULD]
The reader should support bookmarks.

FR-PDF-012 [SHOULD]
The reader should support document
outline navigation when available.

FR-PDF-013 [SHOULD]
Text search should be available
when the PDF contains searchable text
and the security policy permits it.

FR-PDF-014 [MUST]
The reader shall show understandable
loading and failure states.

FR-PDF-015 [MUST]
The PDF interface shall respect
application light and dark themes.

The document's actual page colors
shall not be forcibly altered if
this reduces readability.

---

## PDF Protection Requirements

FR-PDF-SEC-001 [MUST]
Paid PDF files shall be stored
in private storage.

FR-PDF-SEC-002 [MUST]
The backend shall verify active
course entitlement before authorizing access.

FR-PDF-SEC-003 [MUST]
Protected PDFs shall not have
permanent public access URLs.

FR-PDF-SEC-004 [MUST]
The reader shall avoid providing
unnecessary download and print controls.

FR-PDF-SEC-005 [MUST]
The system shall support personalized
visible watermarks on sensitive PDFs.

FR-PDF-SEC-006 [MUST]
Watermarks shall remain readable
without significantly obscuring content.

FR-PDF-SEC-007 [MUST]
Access tokens or authorized resource URLs
shall be limited in scope and lifetime
where the delivery design supports them.

FR-PDF-SEC-008 [MUST]
The system shall not disclose
another student's private information
in PDF watermarks or access responses.

FR-PDF-SEC-009 [SHOULD]
The system should log relevant protected
document access events.

FR-PDF-SEC-010 [MUST]
Unauthorized PDF requests shall
not disclose protected document content.

---

## Important Security Limitation

Web browsers cannot reliably prevent all:

- Screenshots
- Screen recording
- Operating system capture
- Browser developer tools
- External camera recording
- Extraction by determined authorized users

The application must not claim
that copying is impossible.

Security must use layered access controls,
reasonable deterrents, and traceability.

Native mobile applications may provide
stronger operating-system-level protection.

---

# 6.13 ADMIN DASHBOARD

FR-ADMIN-001 [MUST]
Authorized administrators shall
have a dedicated dashboard.

FR-ADMIN-002 [MUST]
The dashboard shall display
operational statistics.

Required statistics:

- Total students
- Total courses
- Total active enrollments
- Pending bank payments
- Confirmed revenue

Each statistic shall be returned and displayed only when the current actor
has the corresponding permission. The backend shall omit unauthorized counts,
receipt aggregates and financial totals, not merely hide them in the UI.

FR-ADMIN-003 [MUST]
Administrators shall access modules
according to their permissions.

FR-ADMIN-004 [MUST]
The dashboard shall provide navigation
to authorized management modules.

FR-ADMIN-005 [MUST]
Unauthorized roles shall not be
able to execute protected operations
through direct API requests.

---

# 6.14 STUDENT ADMINISTRATION

FR-STUDENT-001 [MUST]
Authorized administrators shall
be able to view student records.

FR-STUDENT-002 [MUST]
Administrators shall be able
to search student records.

FR-STUDENT-003 [MUST]
Administrators shall be able
to view student enrollments.

FR-STUDENT-004 [MUST]
Administrators shall only see
student information necessary
for their assigned duties.

FR-STUDENT-005 [SHOULD]
Authorized administrators should
be able to restrict abusive accounts
through an audited process.

FR-STUDENT-006 [MUST]
Administrators shall not directly
modify payment history without
a controlled audited workflow.

---

# 6.15 ADMIN PAYMENT MANAGEMENT

FR-APAY-001 [MUST]
Finance administrators shall
be able to view pending payments.

FR-APAY-002 [MUST]
Finance administrators shall
be able to filter payments by status.

FR-APAY-003 [MUST]
Authorized reviewers shall be able
to inspect private payment receipts.

FR-APAY-004 [MUST]
Authorized reviewers shall be able
to approve or reject bank payments.

FR-APAY-005 [MUST]
All approval and rejection actions
shall create audit records.

FR-APAY-006 [MUST]
The system shall prevent unauthorized
users from approving payments.

FR-APAY-007 [MUST]
The system shall handle attempts
to review an already finalized payment
without creating conflicting results.

FR-APAY-008 [SHOULD]
The system should provide
financial transaction reports.

---

# 6.16 NOTIFICATION SYSTEM

FR-NOTIFY-001 [MUST]
The system shall provide email
verification messages.

FR-NOTIFY-002 [MUST]
The system shall notify students
when bank transfer verification
is approved or rejected.
The decision shall appear in the student's order status and generate a
transactional email. Delivery failures shall be observable and shall not reverse
committed payment or access; automatic retry remains SHOULD under FR-NOTIFY-006.

FR-NOTIFY-003 [SHOULD]
The system should provide purchase
confirmation messages.

FR-NOTIFY-004 [SHOULD]
The system should notify students
when important course access changes occur.

FR-NOTIFY-005 [MUST]
A failed notification delivery shall
not incorrectly reverse a verified payment
or enrollment transaction.

FR-NOTIFY-006 [SHOULD]
The system should retry temporary
notification delivery failures safely.

---

# 7. BUSINESS RULES

BR-001:
Only a valid entitlement grants
access to paid lessons.

BR-002:
Submitting a bank receipt does not
count as verified payment.

BR-003:
Online payments must be verified
using trusted provider information.

BR-004:
A verified payment shall not create
duplicate course access grants.

BR-005:
Only authorized financial roles
may approve bank transfers.

BR-006:
Payment approval shall be auditable.

BR-007:
Course publication does not override
student enrollment permissions.

BR-008:
Unpublished courses shall not appear
in the public marketplace.

BR-009:
Content access shall be enforced
by the backend, not only the UI.

BR-010:
Refund and revocation behavior must
follow the approved access policy.

BR-011:
Financial history shall remain
consistent when operations fail.

BR-012:
Administrative actions affecting
payment or access must identify
the responsible administrator.

BR-013:
A student's learning progress shall
belong to that student.

BR-014:
An unauthorized user shall not
receive another student's data.

BR-015:
System timestamps shall be stored
consistently, preferably in UTC,
and displayed in appropriate local time.

BR-016:
Money shall use precise currency-safe
representations rather than binary
floating-point values for accounting.

---

# 8. PAYMENT STATE MODEL

## 8.1 Order States

An order may have:

- CREATED
- PENDING_PAYMENT
- PENDING_VERIFICATION
- PAID
- FAILED
- CANCELLED
- REFUNDED

Permitted transitions must be controlled
by backend business rules.
Payment verification, order transition, entitlement action and required audit
evidence shall commit atomically; transaction failure grants no access. External
notification delivery follows commit. Refund/chargeback transitions remain gated
on CSA-006 rather than inferred from these state names.

---

## 8.2 Bank Transfer States

- AWAITING_RECEIPT
- SUBMITTED
- UNDER_REVIEW
- APPROVED
- REJECTED

Rejection permits a new linked submission under the same still-payable order,
returning that order to PENDING_PAYMENT. Rejected evidence remains immutable.
Paid, cancelled and refunded orders cannot be revived through resubmission.
The approved bank policy defines legal transitions, settlement non-reuse,
idempotency, concurrency and dispute handling.

---

## 8.3 Enrollment States

- ACTIVE
- EXPIRED
- REVOKED

An enrollment may additionally contain
a start date and optional expiry date.

Enrollment must be based on a valid
authorized grant source.

---

# 9. NON-FUNCTIONAL REQUIREMENTS

# 9.1 SECURITY

NFR-SEC-001 [MUST]
All protected operations shall enforce
server-side authorization.

NFR-SEC-002 [MUST]
The application shall use HTTPS
for production network communication.

NFR-SEC-003 [MUST]
The application shall not expose
server-side secrets to Flutter Web.

NFR-SEC-004 [MUST]
Protected exposed database tables shall use enabled Row Level Security and
reviewed grants. Trusted APIs shall additionally enforce operation and resource
authorization. Privileged backend credentials shall never be exposed to clients.

NFR-SEC-005 [MUST]
Sensitive operations shall validate input.

NFR-SEC-006 [MUST]
The system shall apply rate limiting
to vulnerable authentication and API endpoints.

NFR-SEC-007 [MUST]
File uploads shall enforce approved
types, sizes, and authorization.

NFR-SEC-008 [MUST]
The application shall avoid logging passwords,
tokens, and unnecessary personal data.

NFR-SEC-009 [MUST]
Security-sensitive changes shall be reviewed.

NFR-SEC-010 [MUST]
The application shall use secure defaults.

NFR-SEC-011 [MUST]
Security testing shall include
unauthorized access attempts.

NFR-SEC-012 [MUST]
Production secrets shall be maintained
outside the client source code.

Security verification should reference
relevant OWASP ASVS requirements.

---

# 9.2 PERFORMANCE

The following are proposed targets.
Final performance budgets must be approved
using representative devices, networks,
course files, and expected user traffic.

NFR-PERF-001 [MUST]
Core navigation shall remain responsive
during normal application use.

NFR-PERF-002 [SHOULD]
Cached or previously initialized
application navigation should feel immediate.

NFR-PERF-003 [SHOULD]
Course catalog API requests should target
a p95 server response time below 1 second
under the agreed reference workload.

NFR-PERF-004 [SHOULD]
The PDF reader should display the first page
within 4 seconds under an agreed test network
and representative document size.

NFR-PERF-005 [MUST]
The application shall avoid loading
unnecessary course assets.

NFR-PERF-006 [MUST]
Images shall use suitable formats
and resolution limits.

NFR-PERF-007 [MUST]
Large course lists shall use pagination
or incremental loading.

NFR-PERF-008 [MUST]
Performance regressions shall be evaluated
before production release.

---

# 9.3 RELIABILITY

NFR-REL-001 [MUST]
Payment processing shall preserve data
consistency during failures.

NFR-REL-002 [MUST]
Duplicate payment events shall be
handled safely.

NFR-REL-003 [MUST]
Critical database changes shall use
transactions where appropriate.

NFR-REL-004 [MUST]
The system shall provide meaningful
recovery behavior for network failures.

NFR-REL-005 [MUST]
Production operations shall include
backup and recovery procedures.

NFR-REL-006 [SHOULD]
The platform should target 99.5%
monthly availability, subject to the
approved hosting plan and SLA.

NFR-REL-007 [MUST]
Recovery point and recovery time
objectives shall be specified before launch.

---

# 9.4 USABILITY AND UI/UX

NFR-UX-001 [MUST]
The application shall provide
consistent navigation.

NFR-UX-002 [MUST]
The application shall support
light and dark themes.

NFR-UX-003 [MUST]
The system shall adapt to
mobile, tablet, and desktop screens.

NFR-UX-004 [MUST]
Forms shall display meaningful
validation messages.

NFR-UX-005 [MUST]
Critical actions shall provide
clear feedback.

NFR-UX-006 [MUST]
The interface shall include
loading, empty, error, and success states.

NFR-UX-007 [MUST]
Purchase and bank approval states
shall use clear, understandable labels.

NFR-UX-008 [MUST]
The student learning interface shall
minimize unnecessary distractions.

NFR-UX-009 [MUST]
Course content shall remain readable
without horizontal page overflow
on supported screen sizes.

NFR-UX-010 [SHOULD]
The system should preserve user theme
preferences between sessions.

---

# 9.5 RESPONSIVE DESIGN

Reference design widths:

- Mobile: 390 px
- Tablet: 768 px
- Desktop: 1440 px

These values are design references,
not the only supported viewport sizes.

NFR-RESP-001 [MUST]
Layouts shall adapt to intermediate widths.

NFR-RESP-002 [MUST]
Student navigation shall remain usable
on small mobile screens.

NFR-RESP-003 [MUST]
The admin dashboard shall remain usable
on supported narrow screens.

NFR-RESP-004 [MUST]
PDF controls shall remain accessible
on mobile layouts.

NFR-RESP-005 [MUST]
Important actions shall not become
unreachable at narrow viewport widths.

---

# 9.6 ACCESSIBILITY

NFR-ACC-001 [MUST]
The interface shall support reasonable
keyboard navigation.

NFR-ACC-002 [MUST]
Interactive elements shall provide
accessible names where applicable.

NFR-ACC-003 [MUST]
Text shall have sufficient contrast.

NFR-ACC-004 [MUST]
Important status messages shall not
depend on color alone.

NFR-ACC-005 [MUST]
Visible keyboard focus shall be preserved.

NFR-ACC-006 [SHOULD]
The product should target WCAG 2.2 AA
for applicable student-facing web UI.

NFR-ACC-007 [MUST]
The application shall document
accessibility limitations associated
with protected course documents.

---

# 9.7 MAINTAINABILITY

NFR-MAIN-001 [MUST]
The application shall follow the
approved feature-first architecture.

NFR-MAIN-002 [MUST]
Code shall follow established Dart
formatting and lint conventions.

NFR-MAIN-003 [MUST]
Critical business logic shall have tests.

NFR-MAIN-004 [MUST]
Major architecture changes shall
be documented.

NFR-MAIN-005 [MUST]
Changes shall follow the project's
approved GitHub workflow.

NFR-MAIN-006 [MUST]
AI coding agents shall follow AGENTS.md.

NFR-MAIN-007 [MUST]
Dependency changes shall be justified.

---

# 9.8 PRIVACY AND ETHICS

NFR-PRIV-001 [MUST]
The platform shall collect only
necessary student information.

NFR-PRIV-002 [MUST]
Private student information shall
be access-controlled.

NFR-PRIV-003 [MUST]
Financial receipts shall be private.

NFR-PRIV-004 [MUST]
The platform shall provide clear
privacy and data-use information.

NFR-PRIV-005 [MUST]
The platform shall not secretly
record students' screens or activities.

NFR-PRIV-006 [MUST]
Users shall be informed of any
personalized content watermarking.

NFR-PRIV-007 [MUST]
The platform shall have documented
retention and deletion policies.

NFR-PRIV-008 [MUST]
The platform shall respect applicable
copyright and intellectual property rights.

NFR-PRIV-009 [MUST]
The platform shall not misrepresent
its security protections.

---

# 10. USER INTERFACE REQUIREMENTS

Screen identifiers describe logical views and may share routes/components.
Their MVP priority follows the corresponding functional requirement. UI-AD-007
and UI-AD-015 remain deferred with FR-COURSE-011 and FR-APAY-008; required
operational statistics remain in scope. Listing an optional screen does not
promote a SHOULD requirement to MUST.

## 10.1 Student Screens

The UI shall include:

UI-ST-001: Landing Page
UI-ST-002: Login Page
UI-ST-003: Registration Page
UI-ST-004: Password Recovery
UI-ST-005: Email Verification
UI-ST-006: Home Dashboard
UI-ST-007: Course Catalog
UI-ST-008: Search Results
UI-ST-009: Course Details
UI-ST-010: Curriculum Preview
UI-ST-011: Checkout
UI-ST-012: Bank Transfer Instructions
UI-ST-013: Receipt Upload
UI-ST-014: Payment Status
UI-ST-015: My Courses
UI-ST-016: Learning Workspace
UI-ST-017: Video Player
UI-ST-018: PDF Reader
UI-ST-019: Text/Image Reader
UI-ST-020: Student Profile
UI-ST-021: Account Settings
UI-ST-022: Payment History

---

## 10.2 Admin Screens

UI-AD-001: Admin Dashboard
UI-AD-002: Course List
UI-AD-003: Create/Edit Course
UI-AD-004: Curriculum Builder
UI-AD-005: Lesson Editor
UI-AD-006: Content Upload
UI-AD-007: Course Preview
UI-AD-008: Student List
UI-AD-009: Student Details
UI-AD-010: Payment List
UI-AD-011: Receipt Review
UI-AD-012: Payment Approval
UI-AD-013: Enrollment Management
UI-AD-014: Order History
UI-AD-015: Reports
UI-AD-016: Settings

All UI screens shall conform to
the approved DESIGN_SYSTEM.md.

---

# 11. EXTERNAL INTERFACES

## 11.1 Authentication Interface

The frontend shall communicate with
the approved authentication provider.

Authentication responses shall be
handled securely.

---

## 11.2 Payment Gateway Interface

The backend shall communicate with
the selected payment provider.

Provider response authenticity shall
be verified using official methods.

Private payment credentials shall
remain server-side.

---

## 11.3 Storage Interface

Private storage shall provide
access-controlled course assets
and payment receipt storage.

Resource access shall depend on
the authenticated user's permissions.

---

## 11.4 Video Interface

The video provider shall support:

- Browser-compatible playback
- Authorized video delivery
- Reasonable playback performance
- Course access integration

The provider and pricing plan
remain subject to selection.

---

## 11.5 Email Interface

The system shall support transactional
email delivery for required messages.

Email failures shall be observable.

---

# 12. DATA REQUIREMENTS

The system is expected to contain
the following logical entities.

Exact schemas are defined separately
in DATABASE_DESIGN.md.

## 12.1 Users

- User identifier
- Authentication identifier
- Display name
- Email
- Account status
- Created timestamp
- Updated timestamp

## 12.2 Roles and Permissions

- Role identifier
- Role name
- Permission identifiers
- User-role associations

## 12.3 Courses

- Course identifier
- Title
- Description
- Category
- Price
- Currency
- Thumbnail reference
- Publication state
- Created timestamp
- Updated timestamp

## 12.4 Course Sections

- Section identifier
- Course identifier
- Section title
- Display order

## 12.5 Lessons

- Lesson identifier
- Section identifier
- Lesson title
- Lesson type
- Content reference
- Display order
- Preview flag

## 12.6 Orders

- Order identifier
- Student identifier
- Course identifier
- Amount
- Currency
- Payment method
- Order status
- Created timestamp

## 12.7 Payments

- Payment identifier
- Order identifier
- Provider or transfer reference
- Amount
- Currency
- Verification status
- Verification timestamp

## 12.8 Bank Transfer Submissions

- Submission identifier
- Order identifier
- Private receipt reference
- Submission status
- Reviewer identifier
- Review notes
- Review timestamp

## 12.9 Enrollments

- Enrollment identifier
- Student identifier
- Course identifier
- Grant source
- Access status
- Start timestamp
- Optional expiry timestamp

## 12.10 Learning Progress

- Progress identifier
- Student identifier
- Lesson identifier
- Completion state
- Last position
- Updated timestamp

## 12.11 Audit Logs

- Audit identifier
- Actor identifier
- Action
- Resource type
- Resource identifier
- Timestamp
- Relevant non-sensitive metadata

Database relationships, indexes,
constraints, and access policies
must be documented separately.

---

# 13. PRIMARY USER WORKFLOWS

## 13.1 Registration Workflow

1. Student opens registration page.
2. Student enters required details.
3. System validates input.
4. Account is created securely.
5. Verification email is issued.
6. Student completes verification.
7. Student can authenticate.
8. Student accesses the application.

---

## 13.2 Online Purchase Workflow

1. Student selects a course.
2. Student opens checkout.
3. System creates an order.
4. Student selects online payment.
5. Payment provider processes payment.
6. Backend receives verification data.
7. Backend validates payment authenticity.
8. Backend marks payment verified.
9. System grants course entitlement.
10. Student sees the course in My Courses.

Failure:
Unverified payments do not grant access.

---

## 13.3 Bank Transfer Workflow

1. Student selects a course.
2. Student chooses bank transfer.
3. System displays payment instructions.
4. Student transfers money.
5. Student uploads a receipt.
6. System records pending verification.
7. Finance administrator reviews receipt.
8. Administrator checks actual bank credit.
9. Administrator approves or rejects.
10. System records the decision.
11. Approved payment grants enrollment.
12. Student receives status notification.

Failure:
Rejected or pending receipts do not
grant course access.

---

## 13.4 Course Learning Workflow

1. Student opens My Courses.
2. Student selects an enrolled course.
3. System verifies entitlement.
4. System loads authorized curriculum.
5. Student selects a lesson.
6. Protected content is authorized.
7. Student studies the lesson.
8. System saves learning progress.
9. Student returns later.
10. System restores supported progress.

---

## 13.5 Admin Course Creation Workflow

1. Authorized admin opens Course Management.
2. Admin selects Create Course.
3. Admin enters course information.
4. Admin saves a draft.
5. Admin adds curriculum sections.
6. Admin creates lessons.
7. Admin uploads content.
8. System validates required information.
9. Admin previews the course.
10. Admin publishes the course.
11. Course becomes available publicly.

---

# 14. ACCEPTANCE TEST SCENARIOS

## AT-001: Successful Registration

Given:
A visitor has valid registration details.

When:
The visitor submits registration.

Then:
The system creates an account and
initiates email verification.

---

## AT-002: Unauthorized Course Access

Given:
A student has no active entitlement.

When:
The student requests a paid lesson
through the application or direct API.

Then:
The protected content is not disclosed.

---

## AT-003: Verified Online Purchase

Given:
A valid order exists.

When:
The backend verifies a successful
payment notification.

Then:
The payment becomes verified and
the student receives valid course access.

---

## AT-004: Invalid Payment Callback

Given:
An unverified or tampered callback.

When:
The backend processes the request.

Then:
No paid enrollment is granted.

---

## AT-005: Duplicate Callback

Given:
A verified payment already processed.

When:
The provider sends the same event again.

Then:
The system does not create a duplicate
payment or unintended entitlement.

---

## AT-006: Pending Bank Transfer

Given:
A receipt has been submitted.

When:
The student attempts to open paid lessons
before authorized payment approval.

Then:
The system denies protected content access.

---

## AT-007: Admin Receipt Approval

Given:
An authorized finance administrator
has verified the bank transaction.

When:
The administrator approves the payment.

Then:
The system records the decision,
updates payment state, and grants access.

---

## AT-008: Unauthorized Admin Action

Given:
A student without financial permissions.

When:
The student directly requests a
payment approval operation.

Then:
The operation is rejected and
no financial state changes occur.

---

## AT-009: Protected PDF

Given:
A student has a valid course entitlement.

When:
The student opens a PDF lesson.

Then:
The reader displays the authorized
document with supported reading controls.

---

## AT-010: PDF Access Revocation

Given:
A student's entitlement is revoked.

When:
The student requests protected PDF
content after revocation.

Then:
The backend denies new protected access.

Previously delivered document bytes
cannot be guaranteed to be recalled.

---

## AT-011: Responsive Layout

Given:
The application is opened on supported
mobile, tablet, and desktop viewports.

When:
The user navigates core screens.

Then:
Important content and controls remain
readable, visible, and operable.

---

## AT-012: Theme Switching

Given:
A student is using the application.

When:
The student switches between
light and dark modes.

Then:
Navigation, text, cards, and controls
update without loss of functionality.

---

## AT-013: Learning Progress

Given:
An enrolled student opens a lesson.

When:
The student makes progress and returns later.

Then:
The system restores the saved
supported learning position.

---

## AT-014: Payment Failure Recovery

Given:
A payment provider returns a failure
or uncertain result.

When:
The student returns to the application.

Then:
The system displays the appropriate status,
does not unlock the course prematurely,
and provides a safe recovery action.

---

# 15. SECURITY ACCEPTANCE CRITERIA

Before production release:

- [ ] Authentication controls verified.
- [ ] Authorization boundaries tested.
- [ ] Database RLS policies tested.
- [ ] Payment callback verification tested.
- [ ] Duplicate payment handling tested.
- [ ] Bank approval permissions tested.
- [ ] Private storage access tested.
- [ ] PDF authorization tested.
- [ ] Secret exposure review completed.
- [ ] Upload validation tested.
- [ ] Administrative audit logging verified.
- [ ] Relevant high-severity findings resolved.

---

# 16. UI/UX ACCEPTANCE CRITERIA

- [ ] Core student screens implemented.
- [ ] Core admin screens implemented.
- [ ] Consistent design tokens used.
- [ ] Dark and light themes implemented.
- [ ] Mobile layouts verified.
- [ ] Tablet layouts verified.
- [ ] Desktop layouts verified.
- [ ] Relevant keyboard interactions tested.
- [ ] Loading states implemented.
- [ ] Empty states implemented.
- [ ] Error states implemented.
- [ ] PDF reader usability evaluated.
- [ ] Payment status communication verified.

---

# 17. SYSTEM LIMITATIONS

LIMIT-001:
Browser screenshot prevention cannot
be guaranteed.

LIMIT-002:
Browser screen recording prevention
cannot be guaranteed.

LIMIT-003:
Authorized users may still capture
content using external devices.

LIMIT-004:
PDF security mechanisms provide
risk reduction, not absolute protection.

LIMIT-005:
Free hosting plans may impose storage,
bandwidth, execution, or reliability limits.

LIMIT-006:
Production payment providers may charge
transaction or service fees.

LIMIT-007:
Video delivery costs may increase
with content size and student activity.

LIMIT-008:
Offline viewing of protected paid
courses is not part of the MVP.

---

# 18. PROJECT ASSUMPTIONS

ASSUMPTION-001:
The first release targets modern web browsers.

ASSUMPTION-002:
The student owns a valid email address.

ASSUMPTION-003:
The business owns or licenses all
published course content.

ASSUMPTION-004:
A selected payment provider supports
the intended business and currency.

ASSUMPTION-005:
The backend infrastructure supports
secure private content delivery.

ASSUMPTION-006:
The MVP uses one-course-per-order checkout.

ASSUMPTION-007:
Students require an internet connection
to access paid learning content.

ASSUMPTION-008:
The business will provide official bank
account information for bank payments.

ASSUMPTION-009:
An authorized administrator can verify
incoming bank payments independently.

---

# 19. EXTERNAL DEPENDENCIES

- Flutter SDK
- Dart SDK
- Supabase services
- Payment gateway provider
- Email delivery provider
- Protected video delivery provider
- Domain and HTTPS hosting
- Supported browsers
- Object storage infrastructure

All external dependencies shall be reviewed
for maintenance, security, licensing,
pricing, and operational reliability.

---

# 20. OPEN REQUIREMENTS AND DECISIONS

The following items require final approval
before relevant implementation begins.

DEC-001:
Production payment gateway.
Selected: PayHere, confirmed by the project owner on 2026-10-11.
Merchant activation and integration verification remain separate gates.

DEC-002:
Primary billing currency.
Selected: LKR, confirmed by the project owner on 2026-10-11.

DEC-003:
Supported countries and customer regions.
Business country confirmed: Sri Lanka. The full customer-territory and
cross-border acceptance policy remains open.

DEC-004:
Bank receipt size and file-type limits.
Approved on 2026-10-11: 5 MiB maximum; JPEG, PNG and PDF. Safe inspection and
resource limits remain implementation/production gates in the bank policy.

DEC-005:
Bank transfer review and dispute process.
Baseline approved on 2026-10-11: independent exact credit verification,
no self-approval, immutable reviews, same-order resubmission and a different
reviewer for disputes. Named reviewers, response targets and contacts remain open.

DEC-006:
Course enrollment lifetime and expiry rules.

DEC-007:
Refund policy and refunded-course access.

DEC-008:
Content watermark format and privacy policy.

DEC-009:
Protected video hosting provider.

DEC-010:
Maximum expected concurrent users.

DEC-011:
Hosting budget and operational limits.

DEC-012:
Supported browser/version matrix.

DEC-013:
Initial interface and course languages.

DEC-014:
Data retention periods and deletion rules.

DEC-015:
Final availability and recovery objectives.

DEC-016:
Admin permission and approval separation policy.
Approved on 2026-10-11: the normative CSA-003 permission matrix and separation
rules. Operator assignment and secure bootstrap remain implementation gates.

DEC-017:
Production PDF document size/performance limits.

DEC-018:
Accessibility accommodations for restricted PDFs.

All approved decisions shall be recorded
in the relevant architecture or policy document.

---

# 21. RELEASE ACCEPTANCE

The MVP shall be considered ready for
production release only when:

- [ ] All approved MUST requirements are met.
- [ ] Critical workflows have passed testing.
- [ ] Online payment verification is operational.
- [ ] Bank transfer approval is operational.
- [ ] Enrollment authorization is verified.
- [ ] Protected content access is verified.
- [ ] Admin permissions are verified.
- [ ] Main responsive layouts are tested.
- [ ] Security review is completed.
- [ ] Critical defects are resolved.
- [ ] Backup and recovery procedures exist.
- [ ] Production monitoring is operational.
- [ ] Privacy and commercial policies are published.
- [ ] Production deployment is reviewed.
- [ ] Known limitations are documented.

Any unmet mandatory requirement requires
a recorded exception or an approved scope change.

---

# 22. REQUIREMENT CHANGE MANAGEMENT

Requirement changes shall follow:

1. Identify the requested change.
2. Record business justification.
3. Evaluate security implications.
4. Evaluate UI/UX implications.
5. Evaluate database impact.
6. Evaluate development dependencies.
7. Evaluate testing impact.
8. Obtain required approval.
9. Update SRS.md.
10. Update PLAN.md and TASKS.md.
11. Update related architecture decisions.
12. Implement and verify the approved change.

Avoid undocumented scope changes.

---

# 23. TRACEABILITY

Every development task should reference
the applicable requirement identifiers.

Example:

GitHub Issue:
Implement bank transfer receipt upload.

Related Requirements:
FR-BANK-003
FR-BANK-004
FR-BANK-005
FR-BANK-006
FR-BANK-007

Related Tests:
Receipt format validation
Unauthorized upload rejection
Private storage access verification
Pending payment state verification

Every critical requirement should be
traceable to implementation and testing.

---

# 24. FINAL SYSTEM ACCEPTANCE STATEMENT

The Course Selling Application must deliver
a secure, professional, maintainable, and
accessible e-learning commerce experience.

Students must be able to:

- Register and log in.
- Browse available courses.
- Purchase courses securely.
- Submit bank transfer receipts.
- Access authorized purchased content.
- Study using a premium learning interface.
- Read protected PDFs comfortably.
- Track their learning progress.

Administrators must be able to:

- Manage courses and lessons.
- Manage student enrollments.
- Verify financial transactions.
- Approve bank transfer payments.
- Manage authorized content.
- Monitor operational activity.
- Protect student and financial information.

The application must follow:

- PLAN.md
- AGENTS.md
- ARCHITECTURE.md
- DESIGN_SYSTEM.md
- SECURITY.md
- CONTRIBUTING.md

Development must prioritize:

SECURITY
CORRECTNESS
PRIVACY
USABILITY
ACCESSIBILITY
MAINTAINABILITY
RELIABILITY
TESTABILITY

END OF SOFTWARE REQUIREMENTS SPECIFICATION
