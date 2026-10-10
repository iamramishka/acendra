# CourseFlow — Course Selling App UI/UX Design Package

This package contains a **responsive UI/UX prototype** and a **Flutter-ready UX layout specification**.

## Files

- `course_app_layout_prototype.html` — browser-viewable clickable layout demonstration.
- `course_selling_app_uiux_spec_v1.md` — screen inventory, responsive shells, design tokens, journeys, four priority layouts, and QA checklist.

## Open the layout prototype

1. Download the package and extract it.
2. Open `course_app_layout_prototype.html` in a modern desktop or mobile browser.
3. Use the top design tabs to switch between Explore, Course Details, Checkout, Learning, PDF Reader, and Admin Payments.
4. Toggle Dark Mode to inspect both themes.
5. In the admin review demo, mark that the bank deposit has been verified to try the approval confirmation flow.

## Scope and limitations

All course names, prices, students, bank account details, and receipts are sample content. The prototype is **front-end only**: it does not connect to authentication, storage, payments, or a database. It uses a simulated PDF page, not a real PDF engine. No actual files are uploaded, bank records are checked, or course enrollments are granted.

A browser app cannot completely block screenshots or external screen recording. Use secure private storage, backend authorization, per-user watermarks, and audited access in production.

## Next engineering step

Translate the design system, shells, screens, and state transitions into Flutter widgets. Implement the backend and payment verification as a separate secure workstream before accepting real users or payments.
