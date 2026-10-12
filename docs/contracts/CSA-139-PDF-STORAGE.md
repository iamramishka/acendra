# CSA-139: Private PDF storage foundation

Approved delivery dependency: CSA-010 authenticated proxy strategy. This task
creates storage infrastructure only; CSA-140/141 perform entitlement checks and
controlled delivery. No student receives a Storage signed URL or original path.

`course-pdfs` is private, PDF MIME only, bounded to 50 MiB per object. This is a
conservative technical ceiling, not a product upload allowance or demonstrated
runtime capacity. Representative proxy/range/load validation remains required.
Existing unsafe bucket configuration or invalid stored paths abort migration.

Object identities use lowercase opaque UUIDs and immutable positive versions:

- `originals/<asset UUID>/v<1..999999999>.pdf`
- `derivatives/<asset UUID>/v<version>/<license UUID>/<watermark policy UUID>.pdf`

Paths contain no names, email addresses, or original filenames. Trusted producers
must resolve asset/license/policy identities server-side, validate actual PDF bytes
and scanning requirements, and never accept client-selected private paths. MIME
allowlisting alone is not content validation. Those producers are future scope.

Restrictive RLS denies all anonymous/authenticated object and bucket access even
if another permissive policy is introduced. Trusted backend service credentials
alone perform storage lifecycle operations. Objects cannot be updated or replaced;
publish a new version. Trusted deletion remains possible for reviewed lifecycle
cleanup; no retention policy or staff preview authority is invented here.
Bucket guards prevent public mode, MIME widening, unbounded size, rename/deletion.
Other storage buckets, including bank receipts, retain their own existing rules.

SQL acceptance tests cover safe configuration, opaque original/derivative paths,
invalid paths, client CRUD denial, and restrictive policy composition. The real
local Storage smoke checks upload/readback, immutability, public/private/sign/list
denial and exact synthetic-object cleanup against the pinned disposable stack.
No live environment configuration or deployment is authorized by this contract.
