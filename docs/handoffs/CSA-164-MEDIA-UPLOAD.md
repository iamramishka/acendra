# CSA-164 authorized course-media upload foundation

## Current status — 2026-10-13

Foundation reviewed and merged into dev via [PR #107](https://github.com/iamramishka/acendra/pull/107).
Hosted PR checks passed; integration and shared test/config updates are complete.
Status remains IN_REVIEW for operational acceptance; production endpoints remain disabled.
Earlier pending-PR/integration/CI statements below describe the historical worker stage.
[Current evidence and remaining gates](../tasks/CSA-158-168-MERGE-RECONCILIATION.md) include the verified pre-existing
dev formatting failure, post-merge tests and activation prerequisites.

Owner: CODEX. Issue: #106. Branch: codex/feat/csa-164-media-upload.

Endpoints are admin-create-media-upload and admin-finalize-media-upload. Preparation accepts request_id UUID, course_id, lesson_id (null/omitted for thumbnails), asset_type (course_pdf/lesson_image/public_thumbnail), file_name, content_type, size_bytes. Finalization accepts request_id UUID and asset_id. Responses contain data or a safe error.code. Creation returns a private signed upload token, server path and asset ID; finalization returns validated status after inspecting actual stored bytes. Tokens and private paths must not be logged or exposed in catalog records.

Current authenticated account/session, current content role, current course assignment, course/lesson relationship, and super-admin MFA are checked in trusted SQL on preparation, reservation reads, and finalization, including replay. Metadata reservations remain pending and immutable. Finalization atomically records immutable validation audit and lesson association. It does not publish courses or grant enrollment.

Trusted deployment code must inject an approved immutable policy reference, PDF/image byte limits, inspection timeout and inspector implementation. Inspector verdicts must bind exact MIME, size, SHA256, policy reference, safe/parseable/unencrypted flags and resource limits. Signature checks alone never mark an asset ready. Production entrypoints supply neither policy nor inspector and therefore remain hard disabled. No environment toggle bypass exists. Video/Mux integration is deferred to its separate approved provider work.

The owner approved course PDFs up to 50 MiB and JPEG/PNG thumbnails up to 5 MiB on 2026-10-12. Video delivery remains deferred to Mux integration. Operational parser/scanner/resource limits remain pending. Lesson-image limits remain configurable without an approved operational default; no receipt limits are reused. The private bucket has no browser read/list/overwrite policies. Signed upload tokens may survive assignment revocation until expiry, but every finalization rechecks current authority; immutable paths and non-upsert prevent replacements.

Verification: 25 Node handler tests passed; 30 SQL assertions passed on isolated PostgreSQL 17 modeled auth/storage harness (127.0.0.1:58465), including actual migrations. Actual Supabase storage/token behavior and CI remain acceptance gates. Existing shared configuration, master API contracts and TASKS are owned by parent integration. No production deployment or merge is authorized by this handoff.


PDF uploads use the existing private course-pdfs bucket with originals/<asset-id>/v1.pdf, matching accepted CSA-139/140 delivery identity and immutable object guards. Images use private course-media with course/lesson/asset paths. PDF SQL and handler enforce the accepted 50 MiB delivery hard cap; an approved upload policy may lower it. Requests stream at most 8192 bytes before JSON parsing; Auth/RPC/token JSON responses are bounded to 65536 bytes. Request UUIDs are normalized to canonical lowercase. Mode must be prepare or finalize.


A second PDF source binding for an already associated lesson is rejected atomically, preserving the original source used by the accepted PDF resolver. Source replacement requires a separately reviewed workflow. The Promise timeout bounds waiting but does not terminate an external inspection process: the trusted inspector adapter must cancel external work and enforce parser/scanner CPU, memory, recursion, decompression and process-duration limits independently. Its withinResourceLimits verdict must reflect those enforced limits.

The approved thumbnail upload remains private in course-media at <course-id>/thumbnails/<asset-id>.<jpg|png>. Thumbnail finalization records validation/audit without a lesson association or public catalog thumbnail mutation. Course assignment, current session and content-role authority still apply. Production entrypoints remain unavailable until trusted inspector deployment code and its operational resource policy are accepted.
