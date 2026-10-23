import './pdfjs_runtime.js';
// Initialize the renderer before Flutter registration.

const flutter = document.createElement('script');
flutter.src = new URL('./flutter_bootstrap.js', import.meta.url).href;
flutter.async = true;
document.body.append(flutter);
