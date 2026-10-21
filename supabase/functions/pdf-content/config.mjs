// Deployment opt-in only after the CSA-010 worker/storage/retention gates pass.
// An absent or malformed value remains disabled; never infer readiness.
export const deliveryEnabled = env => env('PDF_DELIVERY_ENABLED') === 'true';
