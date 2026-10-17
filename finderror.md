> Repair status (2026-10-17): historical observations below are retained for traceability.
> Current implementation and verification status for all 25 findings is recorded in
> [CSA-171-FINDERROR-RESIDUAL.md](docs/tasks/CSA-171-FINDERROR-RESIDUAL.md).
> Live deployment and reporting activation have not been performed.

# Acedra — Bug Report / Issue Log

**Date:** 2026-10-17\
**Tester:** Claude (admin session — [test admin account])\
**Environment:** [hosted test deployment]/\
**Login:** [credentials removed; use the approved credential store]

---

## Summary

| # | Severity | Area | Issue |
|---|----------|------|-------|
| 1 | High | Dashboard | Empty student/admin dashboard |
| 2 | High | Auth | Auth state lost on Marketplace route |
| 3 | High | Data | Stats (students/courses/revenue) show hardcoded mock values |
| 4 | High | Data | Dashboard and Payments page show entirely different payment datasets |
| 5 | High | Marketplace | Sandbox/test course visible publicly in Marketplace |
| 6 | High | Admin | Admin panel not linked from any navigation |
| 7 | Medium | Marketplace | Course card displays app name ("Acedra") instead of course title |
| 8 | Medium | Marketplace | "Enroll Now" button does nothing |
| 9 | Medium | Marketplace | Course detail URL does not update (stays on #/marketplace) |
| 10 | Medium | Marketplace | Back arrow (←) on course detail doesn't navigate back |
| 11 | Medium | Admin | Course stats vs actual count mismatch (14 shown vs 3 in list) |
| 12 | Medium | Admin | Student stats vs actual count mismatch (128 shown vs 4 in list) |
| 13 | Medium | Admin | Pending payment count inconsistent across three views |
| 14 | Medium | Admin | Payment status tiles don't add up to record count |
| 15 | Medium | Admin | Course names in payments don't match course names in Courses page |
| 16 | Medium | Admin | "View all payments" link is non-functional |
| 17 | Medium | Admin | Cancel button on course Edit page doesn't navigate back |
| 18 | Medium | Admin | Finance Review blocked for admin user (requires MFA / finance role) |
| 19 | Low | Marketplace | "Courses" nav link non-functional on course detail view |
| 20 | Low | Marketplace | Course thumbnails missing (no image URLs configured) |
| 21 | Low | Admin | No course thumbnails in admin Courses list |
| 22 | Low | Admin | Sandbox course in Marketplace not visible in Admin Courses list |
| 23 | Low | Admin | All student/payment data uses @example.com placeholder emails |
| 24 | Low | Auth | Profile avatar (S) click does nothing — no dropdown or menu |
| 25 | Low | Auth | No admin-panel link for admin users in main authenticated nav |

---

## Detailed Findings

---

### ISSUE-001 — Empty Student Dashboard
**Severity:** High\
**Route:** `#/dashboard`\
**Description:** After logging in, the main dashboard displays only the word "Dashboard" in the center of the page. There are no stats, enrolled courses, quick links, or any useful widgets. This makes the dashboard completely useless.\
**Expected:** Student/admin dashboard with relevant data (enrolled courses, recent activity, account info).\
**Actual:** Blank screen with only the text "Dashboard".

---

### ISSUE-002 — Auth State Lost on Marketplace Route
**Severity:** High\
**Route:** `#/marketplace`\
**Description:** When navigating to the Marketplace, the navigation bar changes from the authenticated view ("My Courses | Explore | 🌙 | S") to the guest view ("Courses | Sign In | Get Started | 🌙"). The session appears to not propagate to the Marketplace shell, treating the user as a guest.\
**Expected:** Logged-in users should see their authenticated nav everywhere.\
**Actual:** Marketplace always renders the unauthenticated navigation, even for a logged-in admin.

---

### ISSUE-003 — Admin Dashboard Stats Are Hardcoded / Mock Data
**Severity:** High\
**Route:** `#/admin`\
**Description:** The admin dashboard stat tiles show:
- 128 Total Students — but the Students admin page lists only 4 students
- 14 Total Courses — but the Courses admin page lists only 3 courses
- LKR 245.8K Total Revenue — unverifiable against actual payment records
- 5 Pending Payments — Payments page shows 2 pending

These numbers appear to be hardcoded placeholder/mock values, not real database aggregates.\
**Expected:** Stats reflect actual data from the database.\
**Actual:** Stats show arbitrary numbers disconnected from actual records.

---

### ISSUE-004 — Admin Dashboard and Payments Page Show Different Datasets
**Severity:** High\
**Route:** `#/admin` vs `#/admin/payments`\
**Description:** The admin dashboard "Pending Payments" section lists:
- student1@example.com — Flutter Masterclass — Oct 17, 2026 — LKR 4500
- student2@example.com — Advanced Dart — Oct 16, 2026 — LKR 3200
- student3@example.com — UI/UX Fundamentals — Oct 16, 2026 — LKR 5800

The Payments admin page lists:
- ORD-2026-0001 — alice@example.com — Flutter & Dart Masterclass — Oct 14, 2026 — LKR 4999

These are two completely different student names, course names, amounts, and dates. One source is showing mock data; the other may show real records.\
**Expected:** Both surfaces draw from the same data source.\
**Actual:** Different datasets displayed, indicating one is hardcoded mock data.

---

### ISSUE-005 — Sandbox / Test Course Visible in Public Marketplace
**Severity:** High\
**Route:** `#/marketplace`\
**Description:** The marketplace displays a course titled "SANDBOX TEST ONLY - Checkout Verification" with description:\
> "Synthetic staging fixture. No real course or live payment."\
> "This isolated fixture verifies sandbox checkout only; it does not establish course publishing or protected lesson acceptance."

This test fixture is publicly visible to all users and is listed at LKR 100.00.\
**Expected:** Test/sandbox courses should be hidden from the public marketplace, or the course should not exist in production.\
**Actual:** Test course is publicly browsable and has an "Enroll Now" button.

---

### ISSUE-006 — Admin Panel Not Accessible from Navigation
**Severity:** High\
**Route:** All authenticated routes\
**Description:** There is no link to the admin panel (`#/admin`) in any navigation bar. An admin user logging in is taken to `#/dashboard` (which is blank), and there is no way to reach `#/admin` except by typing the URL directly. The profile avatar (S) also produces no dropdown.\
**Expected:** Admin users should see an "Admin" option in their nav or be redirected to `#/admin`.\
**Actual:** Admin users must know to manually navigate to `[hosted test deployment]/#/admin`.

---

### ISSUE-007 — Course Card Shows App Name Instead of Course Title
**Severity:** Medium\
**Route:** `#/marketplace`\
**Description:** The course card in the marketplace listing displays "Acedra" (the app name) as the course title instead of the actual course title ("SANDBOX TEST ONLY - Checkout Verification"). The price (LKR 100.00) is shown correctly.\
**Expected:** Course card shows the actual course title.\
**Actual:** Course title is "Acedra" on the card.

---

### ISSUE-008 — "Enroll Now" Button Has No Effect
**Severity:** Medium\
**Route:** `#/marketplace` (course detail view)\
**Description:** Clicking the "Enroll Now" button on the course detail page produces no visible effect — no navigation to checkout, no loading indicator, no error message, no modal.\
**Expected:** Clicking "Enroll Now" initiates the checkout/enrollment flow.\
**Actual:** Button click is silently ignored.

---

### ISSUE-009 — Course Detail Page Does Not Update the URL
**Severity:** Medium\
**Route:** `#/marketplace`\
**Description:** When clicking on a course card to view details, the page content changes to show the course detail (title, price, description, Enroll Now button), but the URL remains `#/marketplace` instead of navigating to a course-specific route (e.g., `#/courses/course-id`). This prevents direct linking and breaks browser history navigation.\
**Expected:** Course detail navigates to a dedicated URL like `#/courses/{id}`.\
**Actual:** URL stays at `#/marketplace`.

---

### ISSUE-010 — Back Arrow on Course Detail Doesn't Work
**Severity:** Medium\
**Route:** `#/marketplace` (course detail view)\
**Description:** The "←" back arrow displayed at the top of the course detail view does nothing when clicked. The page stays on the course detail, and no navigation to the marketplace listing occurs.\
**Expected:** Clicking ← returns to the marketplace course listing.\
**Actual:** Click is ignored; page does not change.

---

### ISSUE-011 — Courses Count Mismatch (14 vs 3)
**Severity:** Medium\
**Route:** `#/admin` vs `#/admin/courses`\
**Description:** The admin dashboard stat tile shows "14 Total Courses", but the Courses admin page only lists 3 courses (Flutter for Beginners, Advanced Dart Programming, Supabase & Backend Integration). No pagination is present.\
**Expected:** Both counts reflect the same data.\
**Actual:** 14 shown in stats, 3 shown in the list.

---

### ISSUE-012 — Students Count Mismatch (128 vs 4)
**Severity:** Medium\
**Route:** `#/admin` vs `#/admin/students`\
**Description:** The admin dashboard shows "128 Total Students" but the Students page shows "4 students" (alice, bob, carol, david — all with @example.com emails).\
**Expected:** Stats and list show the same count.\
**Actual:** 128 in stats, 4 in list.

---

### ISSUE-013 — Pending Payments Count Inconsistent Across Three Locations
**Severity:** Medium\
**Route:** `#/admin`, `#/admin/payments`\
**Description:** Three different counts for pending payments are shown:
1. Admin dashboard stat tile: "5 Pending Payments"\
2. Admin dashboard "Pending Payments" section badge: "3"\
3. Admin Payments page summary tile: "2 Pending"

None of these three agree.\
**Expected:** Consistent pending payment count across all displays.\
**Actual:** Three different numbers (5, 3, 2) shown simultaneously.

---

### ISSUE-014 — Payment Status Tiles Don't Sum to Total Record Count
**Severity:** Medium\
**Route:** `#/admin/payments`\
**Description:** The Payments page shows "6 records" but the summary tiles show: 2 Pending + 2 Approved + 1 Rejected = 5. One record is unaccounted for (presumably "Processing" status), but no "Processing" count tile is displayed.\
**Expected:** All status tiles sum to the total record count, or a "Processing" tile is shown.\
**Actual:** 2+2+1 = 5, but page claims 6 records.

---

### ISSUE-015 — Course Names in Payments Don't Match Courses in Admin Panel
**Severity:** Medium\
**Route:** `#/admin/payments` vs `#/admin/courses`\
**Description:** Payments reference courses such as "Flutter & Dart Masterclass", "Flutter Masterclass", "Advanced Dart", and "UI/UX Fundamentals". The admin Courses page lists "Flutter for Beginners", "Advanced Dart Programming", and "Supabase & Backend Integration". None of the payment course names match any admin course names exactly.\
**Expected:** Course names in payments reference the same courses visible in the admin panel.\
**Actual:** Courses referenced in payments appear to be from a different, possibly deleted or mock, dataset.

---

### ISSUE-016 — "View All Payments" Link Does Nothing
**Severity:** Medium\
**Route:** `#/admin` (dashboard)\
**Description:** The "View all payments" link at the bottom of the Pending Payments section does not navigate to the Payments admin page. Clicking it produces no effect.\
**Expected:** "View all payments" navigates to `#/admin/payments`.\
**Actual:** Click is silently ignored.

---

### ISSUE-017 — Cancel Button on Course Edit Page Doesn't Navigate Back
**Severity:** Medium\
**Route:** `#/admin/courses/course-1/edit`\
**Description:** Clicking "Cancel" on the Edit Course page does not navigate back to the courses list. The page stays on the edit form.\
**Expected:** Cancel returns to `#/admin/courses`.\
**Actual:** Click is ignored; page stays on edit form.

---

### ISSUE-018 — Finance Review Inaccessible to Admin (Requires MFA / Finance Role)
**Severity:** Medium\
**Route:** `#/admin/finance-review`\
**Description:** Clicking "Finance Review" from Quick Actions shows: "Finance review is unavailable. Sign in with an authorized finance account and MFA, or try again later." The admin user cannot access Finance Review.\
**Expected:** Admin users can access Finance Review, or the Quick Action button is hidden/disabled for users without the finance role.\
**Actual:** Clicking Finance Review shows a blocking error screen with only a "Retry" button.

---

### ISSUE-019 — "Courses" Nav Link Non-Functional on Course Detail View
**Severity:** Low\
**Route:** `#/marketplace` (course detail view)\
**Description:** While viewing a course detail, clicking "Courses" in the marketplace navigation header does not navigate. The page stays on the current course detail view.\
**Expected:** "Courses" in the nav returns to the marketplace listing.\
**Actual:** Click has no effect.

---

### ISSUE-020 — Course Thumbnails Missing in Marketplace
**Severity:** Low\
**Route:** `#/marketplace`\
**Description:** Course cards in the marketplace show a generic play-button placeholder instead of a thumbnail image. In the admin Edit Course page, the "Thumbnail URL" field is empty for all courses.\
**Expected:** Course cards display a thumbnail image.\
**Actual:** All course cards show the same blank placeholder icon.

---

### ISSUE-021 — Course Thumbnails Not Loading in Admin Courses List
**Severity:** Low\
**Route:** `#/admin/courses`\
**Description:** All courses in the admin Courses list show a broken/placeholder image icon. Confirmed to be caused by missing Thumbnail URLs (see ISSUE-020).\
**Expected:** Course thumbnails display in admin list.\
**Actual:** Broken image placeholder for all 3 courses.

---

### ISSUE-022 — Sandbox Course in Marketplace Not Visible in Admin Courses List
**Severity:** Low\
**Route:** `#/marketplace` vs `#/admin/courses`\
**Description:** The "SANDBOX TEST ONLY - Checkout Verification" course visible in the marketplace at LKR 100.00 does not appear anywhere in the admin Courses list. Either it is hidden from the admin panel, or the admin panel is showing a filtered/incomplete dataset.\
**Expected:** All courses visible to users are manageable in the admin panel.\
**Actual:** The sandbox course appears in the marketplace but is absent from admin.

---

### ISSUE-023 — All Student and Payment Data Uses Placeholder Emails
**Severity:** Low\
**Route:** `#/admin/students`, `#/admin/payments`\
**Description:** All student accounts use @example.com email addresses (alice@example.com, bob@example.com, carol@example.com, david@example.com) and payment records reference student1/2/3@example.com. These appear to be seed/fixture data not replaced with real data.\
**Expected:** A production environment should have real user data, or the seed data should be clearly labeled as such.\
**Actual:** Only placeholder seed accounts exist.

---

### ISSUE-024 — Profile Avatar Click Does Nothing
**Severity:** Low\
**Route:** `#/dashboard`\
**Description:** Clicking the user avatar ("S") in the top-right of the authenticated navigation bar produces no response — no dropdown menu, no navigation to profile/settings, no logout option.\
**Expected:** Avatar click opens a dropdown with Profile, Settings, Logout options.\
**Actual:** Click is silently ignored.

---

### ISSUE-025 — No Admin Panel Link in Authenticated Navigation
**Severity:** Low\
**Route:** `#/dashboard`\
**Description:** The authenticated navigation only shows "My Courses | Explore | 🌙 | S". There is no "Admin" link visible even though the user is an admin. The admin panel at `#/admin` is only reachable by directly entering the URL.\
**Expected:** Admin users see an "Admin" or "Admin Panel" option in their navigation.\
**Actual:** No admin link in nav; users must know the URL.

---

## Pages Visited

| URL | Status |
|-----|--------|
| `#/login` | ✅ Working |
| `#/dashboard` | ⚠️ Empty content |
| `#/marketplace` | ⚠️ Auth state lost, limited function |
| `#/admin` | ✅ Functional but data inconsistencies |
| `#/admin/courses` | ⚠️ Works, thumbnails missing |
| `#/admin/courses/course-1/edit` | ⚠️ Cancel broken |
| `#/admin/students` | ✅ Works |
| `#/admin/payments` | ⚠️ Data inconsistencies |
| `#/admin/finance-review` | ❌ Blocked for admin user |

---

## Observations

- The app appears to be in early/MVP development. Core flows (enroll, checkout, view owned courses) are not yet functional.
- Admin dashboard statistics appear to be hardcoded demo values rather than real aggregates from the database.
- The Marketplace and the authenticated app shell behave as two disconnected applications (different nav, different auth state).
- Seed/fixture data from development has not been cleaned up (placeholder emails, sandbox course, mock payment records).
- Predictable course IDs alone do not establish an authorization vulnerability; backend authorization must be verified independently.
