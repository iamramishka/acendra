# CSA-164 authorized course-media upload foundation

Owner: CODEX. Issue: #106. Branch: feat/csa-164-media-upload.

Endpoints are admin-create-media-upload and admin-finalize-media-upload. Preparation accepts request_id UUID, course_id, lesson_id, asset_type (course_pdf/lesson_image), file_name, content_type, size_bytes. Finalization accepts request_id UUID and asset_id. Responses contain data or a safe error.code. Creation returns a private signed upload token, server path and asset ID; finalization returns validated status after inspecting actual stored bytes. Tokens and private paths must not be logged or exposed in catalog records.

Current authenticated account/session, current content role, current course assignment, course/lesson relationship, and super-admin MFA are checked in trusted SQL on preparation, reservation reads, and finalization, including replay. Metadata reservations remain pending and immutable. Finalization atomically records immutable validation audit and lesson association. It does not publish courses or grant enrollment.

Trusted deployment code must inject an approved immutable policy reference, PDF/image byte limits, inspection timeout and inspector implementation. Inspector verdicts must bind exact MIME, size, SHA256, policy reference, safe/parseable/unencrypted flags and resource limits. Signature checks alone never mark an asset ready. Production entrypoints supply neither policy nor inspector and therefore remain hard disabled. No environment toggle bypass exists. Video/Mux integration is deferred to its separate approved provider work.

Approved course-media limits and operational parser/scanner/resource limits were unavailable during this implementation; no receipt limits are reused. The private bucket has no browser read/list/overwrite policies. Signed upload tokens may survive assignment revocation until expiry, but every finalization rechecks current authority; immutable paths and non-upsert prevent replacements.

Verification: 22 Node handler tests passed; 23 SQL assertions passed on isolated PostgreSQL 17 modeled auth/storage harness (127.0.0.1:58465), including actual migrations. Actual Supabase storage/token behavior and CI remain acceptance gates. Existing shared configuration, master API contracts and TASKS are owned by parent integration. No production deployment or merge is authorized by this handoff.


PDF uploads use the existing private course-pdfs bucket with originals/<asset-id>/v1.pdf, matching accepted CSA-139/140 delivery identity and immutable object guards. Images use private course-media with course/lesson/asset paths. PDF SQL and handler enforce the accepted 50 MiB delivery hard cap; an approved upload policy may lower it. Requests stream at most 8192 bytes before JSON parsing; Auth/RPC/token JSON responses are bounded to 65536 bytes. Request UUIDs are normalized to canonical lowercase. Mode must be prepare or finalize.

