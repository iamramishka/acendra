# CSA-165 trusted publication

Owner CODEX root. Issue106. Base origin/dev56ce6fd. Development implementation;
IN_REVIEW pending hosted checks and authorized review. Deployment remains separate.

`POST admin-publish-course` accepts exact JSON `{course_id,expected_updated_at}`
with optional `action: "publish" | "unpublish"` (default publish). The timestamp
is preserved with PostgreSQL microseconds; frontend must use the returned value.
Require `Idempotency-Key` (1–128 ASCII alphanumeric, dot, underscore, colon, hyphen).
Bodies maximum8192 bytes. Exact configured origins only, no-store responses.

Verify exact bearer token through Auth before resolving actor/session claims.
Service-only `csa165_publish_course` rechecks eligible current account, current
AAL2 session and unrevoked super-admin role. Content managers and finance roles
cannot publish, as approved CSA003 overrides legacy API section55 wording.

Only draft→published or published→draft transitions are accepted. Archived state
requires a separate operation. Stale expected timestamps return409. A repeated
actor/key/payload returns the original response; changed payload conflicts and
revoked actors cannot replay. Mutation, immutable publication audit and replay
result commit together. Unpublication changes visibility/purchasability only;
existing source grants and entitlements survive.

Publication requires descriptions, valid price/currency/category, published
curriculum with lessons, and matching validated undeleted content with immutable
identity. Additional rejected or foreign asset kinds block publication. Optional
thumbnail references must match validated image thumbnails. Text lessons fail
closed until private text-body validation is implemented; public descriptions are
not paid lesson content. Video readiness requires validated Mux metadata; actual
provider readiness and upload integration remain separate prerequisites.

Role authority lock → course row → table SHARE curriculum/associations/media locks
hold a stable readiness snapshot through commit. Other writing boundaries must
retain this order. The table locks can briefly serialize authoring across courses;
MVP correctness is preferred to unsafe concurrent insert/delete publication.

The production entry point remains hard disabled. No environment variable enables
it. Reviewed activation requires actual hosted permission/readiness evidence and
owner deployment authorization. Local handler tests use an explicit test seam.
