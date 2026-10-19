# CSA268 course authoring

Owner: CODEX; GitHub #199. Source implementation IN_REVIEW. Requirements:
FR-COURSE-001–010/012. No hosted activation or production approval is implied.

`POST admin-course-management` accepts `{action,course_id,payload}`. All identities
are UUIDs. Writes additionally require UUID `request_id`; writes other than create
require original `expected_updated_at` (PostgreSQL microseconds retained).
Request body limit 64 KiB, response limit 16 MiB (bounded Unicode curriculum),
one 15-second Auth/RPC deadline.
Exact origin allowlist, JSON content type, no-store responses, bounded preflight.
Auth verifies the exact token before a service-only RPC derives authority from
current account/session/roles and course assignment. Content managers may create
and author assigned courses; super-admin requires AAL2. Finance/student roles
cannot author. There are no new direct client table or audit grants.

Actions and exact payloads:

| Action | Payload / result |
| --- | --- |
| get | `{}`; returns `{course,categories}` including exact `price_minor`, raw revision, slug, active categories and safe metadata |
| curriculum | `{}`; returns ordered `{sections,updated_at}` with nested lessons and publication markers |
| create / update | `{title,slug,category_id,short_description,description,price_minor,currency_code}`; create uses client UUID course_id as identity, creates a draft and records creator assignment |
| upsert_section | `{id,title,position,is_published}` |
| delete_section | `{id}`; deletes its draft lessons only when no enrollment/progress/media reference requires retention |
| upsert_lesson | `{id,section_id,title,description,lesson_type,position,is_preview,is_published,duration_seconds}` |
| delete_lesson | `{id}`; same retention/parent checks |
| reorder_sections | `{ids}`; complete unique current permutation |
| reorder_lessons | `{section_id,ids}`; complete unique current section permutation |

Writes return `{course_id,updated_at,replayed}`. Request identity is scoped to the
actor and exact action/course/revision/payload. Authorization is rechecked before
replay, and mismatched reuse conflicts. Every mutation and immutable audit/result
commit together. Course revisions advance for metadata and curriculum changes;
stale commands fail, rather than refetching and overwriting another editor.
Row-by-row HTTP reorder is replaced by two bulk updates inside one transaction.
A bounded free temporary position range is disjoint from both existing and final
positions; existing immediate uniqueness and seed ON CONFLICT remain compatible.
Incomplete, duplicate or foreign permutations are rejected.

Only LKR is supported. Prices are decimal-string exact nonnegative bigint minor
units, never floating-point trusted values. Title max 200 characters; slug max
200 with lowercase hyphen-separated segments; short description max 2,000, course
description max 40,000, lesson metadata description max 2,000. Curriculum is
bounded to 1,000 sections/lessons per course, and position is 0–1,000,000.
Supported metadata types: video, pdf, text, image. Descriptions are safe public
metadata, never paid lesson bodies or media access URLs. Private content upload
and delivery retain their separate reviewed contracts.

Curriculum writes require draft state. Archived courses cannot be edited.
Published metadata cannot remove required descriptions or select an inactive
category. Existing lesson parent cannot change through upsert; linked media
blocks type changes. Enrollment/progress/media history prevents destructive
curriculum removal. Existing enrollments also prevent switching a previously
published section or lesson off after course unpublication, preserving existing
paid delivery. Non-destructive title/ordering edits remain available. Publication remains the separate
[CSA165 operation](CSA-165-PUBLICATION.md), with current super-admin/AAL2 and full
content readiness. Saving a publication marker never grants protected access.

Errors: 401 AUTH_REQUIRED; 403 ADMIN_PERMISSION_REQUIRED/ORIGIN_FORBIDDEN;
400 INVALID_REQUEST; 409 COURSE_CONFLICT/UNPUBLISH_FIRST/CONTENT_IN_USE/
COURSE_NOT_READY; 404 COURSE_NOT_FOUND; 413 INVALID_REQUEST for oversize body;
415 UNSUPPORTED_MEDIA_TYPE; 503 COURSE_MANAGEMENT_UNAVAILABLE/SERVICE_UNAVAILABLE.
Raw database diagnostics, service credentials and private asset paths are not
returned. Clients preserve entered form data on errors and offer safe retry.

Release: replay the additive migration before deploying updated functions. Leave
`ACENDRA_COURSE_MANAGEMENT_ENABLED` and `ACENDRA_COURSE_PUBLICATION_ENABLED` absent
until separately reviewed hosted acceptance; lowercase `true` plus valid exact
HTTPS origins opts in. Verify current-role/AAL2, revoked/foreign/student denials,
real persistence, stale edits, ordering and readiness before release. Rollback
removes the flags; retain all audit/history/schema. No live settings, data, media
or entitlement state were changed by this implementation.

Course deletion/retention policy awaits the project owner's requested decision;
no permanent course/audit deletion operation is inferred from draft authoring.
