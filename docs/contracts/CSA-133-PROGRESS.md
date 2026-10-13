# CSA-133 learning progress RPC contract

Owner CODEX; integration issue #93, task issue #97. Approved bounded contract
recorded before implementation. Requires migrations through CSA-127/021.

`csa133_save_progress(p_lesson uuid, p_completed boolean, p_pdf_page integer =
null, p_pdf_position numeric = null, p_video_seconds integer = null)` stores a
complete resume snapshot for the current authenticated JWT subject. No user ID,
session ID, timestamps or entitlement can be supplied by the caller. Repeated
saves update one user/lesson row; concurrent saves use last serialized write.
Null position fields clear those fields. Completion can be set or cleared.

`csa133_read_progress(p_course uuid)` returns the current subject's saved
progress in section/lesson order, or an empty JSON array if nothing is saved.
Each returned record contains `lesson_id`, `is_completed`, `pdf_page`,
`pdf_position`, `progress_seconds`, `last_opened_at`, and `updated_at`.

Both RPCs require the JWT authenticated role, a live matching Supabase session,
an eligible account, and current source-based course entitlement. The
beneficiary/course advisory lock serializes access with grant and revocation
operations. Published lesson and section are required; course draft/archived
status does not remove previously valid entitlement. Unpublished progress is
retained privately and omitted from reads. No direct table grants are added.

PDF page must be positive; PDF offset requires page and is normalized to [0,1].
Video seconds must be nonnegative and cannot exceed a known lesson duration.
Other lesson types accept completion only. SQLSTATE `42501` means access denied
(including unknown lessons); `22023` means invalid typed resume input.

Progress is a student preference, not assessment evidence, payment verification,
course access, or certificate eligibility. This task introduces no media delivery
and no privileged frontend credentials. Production deployment remains separate.
