# CSA-108/109 private receipt upload contract

Status IN_REVIEW. Owner CODEX checkout_initialization. Date 2026-10-11.
Coordination issue82, integration issue81. Approved baseline CSA-005 BANK POLICY.

POST /functions/v1/upload-bank-receipt with raw file body, Authorization Bearer,
Idempotency-Key 1–128 ASCII letters/digits/._:-, X-Order-Id UUID,
X-Receipt-Name safe ASCII basename with jpg/jpeg/png/pdf extension. Content-Type
must exactly be image/jpeg, image/png or application/pdf matching the extension
and actual signature. Raw and retrieved bodies are independently streamed with
maximum 5,242,880 bytes; empty bytes, arbitrary paths and MIME spoofing denied.
Name is never stored as an object path; it only supplies the validated extension.

This is a coordinated disabled implementation extension to docs/API_CONTRACTS.MD
signed-capability proposal. Server upload avoids relying on browser capability
expiry/overwrite behavior, exposes no capability/private path, and returns safe
submission fields compatible with the approved status boundary. Legacy proposal
is unchanged. No production storage/inspection approval is inferred.

Deployment index supplies no inspector/enable flag. Default hard-disabled 503
RECEIPT_UPLOAD_UNAVAILABLE; environment flags cannot enable it. A future reviewed
change requires approved parsing/scanning/safe rendering technology, resource
limits, retention/abandoned upload handling and release acceptance.

Underlying tests inject trusted inspector {policyReference,timeoutMs,inspect}.
Policy reference and function are captured at handler construction. Timeout must
be integer1..30000ms. Inspector receives cloned bytes plus exact SHA256/size/MIME;
attestation must bind them and trusted policy reference, safe=true,
parseable=true, encrypted=false, withinResourceLimits=true. A signature filter is
not a parser or malware scanner. No default inspector or invented production
resource limits are supplied. Synthetic fixture signatures are not real safe
parsed documents. Inspection occurs before reservation and again on stored bytes.

Auth verifies exact token before sub/session/aal provenance is read. Backend-only
service RPC rechecks live account/session/order ownership and pending bank order.
No student raw table/storage grant, client actor/path, overwrite/upsert or list.
RPC contracts agreed with exclusive SQL owner:

    csa108_prepare_receipt(p_actor,p_session_id,p_aal,p_key,p_order,
      p_digest,p_size,p_mime,p_extension)
    -> {upload_id,submission_id,receipt_asset_id,bucket:"bank-receipts",
        object_path,replayed,finalized}

    csa109_finalize_receipt(p_actor,p_session_id,p_aal,p_upload_id,
      p_digest,p_size,p_mime,p_inspection_reference)
    -> {order_id,submission_id,status:"submitted",replayed}

Prepared digest/metadata are immutable. Path must exactly equal
actor/order/submission/uploadUUID.extension, asset==uploadUUID and fixed private
bank-receipts bucket. First upload uses server service request x-upsert:false.
Modern409 and legacy400 bounded documented Duplicate/ResourceAlreadyExists or
statusCode409 permit only read+verification of reserved original bytes. Unrelated
or oversized error responses fail closed. GET verifies actual MIME/digest/size,
then trusted inspector and transactional finalization. Finalized retries never
POST; same original key/digest is mandatory. Different active keys conflict.
Storage exists check/private bucket and immutable finalized evidence are SQL guards.
All Auth/Storage/RPC calls redirect:error, bounded deadlines; no raw receipt/PII,
error bodies, storage paths, credentials or capabilities are logged/returned.

DB/Storage cannot be one transaction. Failed/uncertain upload/finalization retains
reservation/object for same-key retry. No racing blind deletion. Missing or
changed bytes never finalize; trusted lifecycle cleanup requires separately
approved abandoned-upload/retention policy. Earlier prepared uploads cannot
revive cancelled/paid/refunded orders. Only one active submission per order.

201 first valid submission or200 identical finalization replay:

    {data:{order_id,submission_id,status:"submitted",
      order_status:"pending_verification"},meta:{contract_version:"v1",request_id}}

Submission is receipt evidence only, never paid/approved/access. SQL transitions
awaiting_receipt->submitted and pending_payment->pending_verification atomically.
Finance independent verification is CSA112/113; no grant from upload.

Safe errors400 INVALID_REQUEST/INVALID_RECEIPT;401 AUTH_REQUIRED;403 origin/
preflight/FORBIDDEN;404 ORDER_NOT_FOUND;405 METHOD_NOT_ALLOWED;409 RECEIPT_CONFLICT/
ORDER_NOT_PAYABLE;413 RECEIPT_TOO_LARGE;422 INSPECTION_FAILED;503 SERVICE_UNAVAILABLE/
RECEIPT_UPLOAD_UNAVAILABLE. All responses no-store; existing configured origin
allowlist and explicit receipt preflight headers. SQL detail never exposed.

Storage collision documentation checked by root2026-10-11:
https://supabase.com/docs/guides/storage/uploads/standard-uploads
https://supabase.com/docs/guides/storage/debugging/error-codes
Real pinned storage API integration remains a separate verification gate.
