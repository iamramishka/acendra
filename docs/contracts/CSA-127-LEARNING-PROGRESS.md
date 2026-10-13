# CSA-127 learning progress model

Owner CODEX; issue #91; Phase 6 model foundation. Status IN_REVIEW.
Approved basis: DATABASE_DESIGN section 31 and SRS FR-LEARN-006/007/008.

`public.lesson_progress` stores one row per user/lesson, with generated UUID,
profile/lesson foreign keys, optional nonnegative integer `progress_seconds`,
positive `pdf_page`, normalized numeric within-page `pdf_position` from zero
to one, completion boolean, nullable `last_opened_at` and timestamps. Offset
requires a page; NaN/infinite/out-of-range offsets fail closed. Video timestamp
is optional (SHOULD); completion/last lesson/PDF resume supports the MVP MUST.

User/lesson/id are immutable on update. Creation time is preserved and update
time is database-managed. Resume queries order by last_opened_at with lesson_id
as a stable tie-breaker; separate user/update and lesson indexes support lookup.
Profile or lesson deletion cascades progress; this table is personal learning
state, not financial audit history. Financial deletion restrictions remain intact.

RLS is enabled; PUBLIC/anon/authenticated/service_role have no table grants and
no policies or callable mutation functions are added. CSA-133 must implement
owned, current-session, lesson/course-bound authorization before exposing reads
or writes. Persistence must consult the existing entitlement boundary; progress
never creates access. Cross-user denial, stale/revoked access and consistent
resume writes are CSA-133/155 integration scope, not proven by this schema.
Completion is student-controlled state, not trusted graded/certificate evidence.
