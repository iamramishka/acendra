// Same-origin renderer and worker; no document bytes or identifiers go to a CDN.
import { pdfxCompatibleTask } from './pdfjs_compat.js';

try {
  const pdfjs = await import('./vendor/pdfjs/pdf.min.js');
  pdfjs.GlobalWorkerOptions.workerSrc = new URL('./vendor/pdfjs/pdf.worker.min.js', import.meta.url).href;
  const defaults = {
    cMapUrl: new URL('./vendor/pdfjs/cmaps/', import.meta.url).href,
    cMapPacked: true,
    standardFontDataUrl: new URL('./vendor/pdfjs/standard_fonts/', import.meta.url).href,
    wasmUrl: new URL('./vendor/pdfjs/wasm/', import.meta.url).href,
  };
  globalThis.pdfRenderOptions = defaults;
  globalThis.pdfjsLib = { ...pdfjs, getDocument: options => pdfxCompatibleTask(pdfjs.getDocument({
    ...defaults, ...options, isEvalSupported: false, useSystemFonts: false,
  })) };
} catch {
  // Other lessons remain usable; pdfx reports a safe retry error on PDF open.
  console.warn('PDF renderer could not be initialized.');
}
