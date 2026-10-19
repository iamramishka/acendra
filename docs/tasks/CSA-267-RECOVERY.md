# CSA-267 recovery and integration

Date: 2026-10-19 (Asia/Colombo). Owner: CODEX, Check GitHub issues chat.
Status: IN_PROGRESS. Authority: project owner requested fixing open issues and
merging into dev. This is source integration authorization, not live activation.

## Ownership and preservation

PR #195 was closed without merge and its fork no longer resolves. Its immutable
head `6f3a3cef29d2204ea2979d30353f6b0fe3315902` was recovered from the upstream
pull-request ref. The existing source checkout and all other worktrees are untouched.

Branch: `fix/csa-267-recover-integration`.
Worktree: `C:/Users/ramis/.codex/worktrees/csa267-recovery/acendra`.
Scope: preserve and review the 37-file CSA-267 patch, fix media-path defects with
focused regressions, update CSA-267 evidence, and submit a replacement PR into dev.
Temporary shared ownership: only the existing CSA-267 additive core thumbnail,
package test registration, function configuration and new artwork migration changes.
Do not edit existing migrations, global tokens, dependencies or another task's code.

The active chats Review and merge PRs 185–188 and Review and merge PRs 189–194
retain their PR ownership. Issues #183/#192 and PR #187 for #160 remain with those
reviewers. PR #196 and uncommitted primary-checkout edits are excluded.

Dependencies: reviewed current dev and established media-upload authorization.
Verification: handler/parser/SQL/source review, focused Node/Python/Flutter checks
when resources allow, migration replay and full hosted checks before merge.
Approval authority: project owner/authorized maintainer and required GitHub review.

## Current external gates

GitHub reports the repository private. The latest Flutter job for PR #196 never
started: account payment/spending-limit gate (annotation on check 118090288810).
Do not treat this as a source-code failure or bypass required checks. No billing
setting, spending limit, review requirement or branch protection is changed here.
Media service provisioning, real scanner/Storage acceptance and deployment remain
separate release gates. No live activation is authorized by this record.
