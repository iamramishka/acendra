export function pdfxCompatibleTask(task) {
  // pdfx 2.11 closes a PDFDocumentProxy, while PDF.js 6 owns cleanup on the
  // loading task. Keep the original task alive and share one cleanup promise
  // between outline cancellation, late opening and renderer disposal.
  let closing;
  const destroy = () => closing ??= Promise.resolve().then(() => task.destroy());
  return {
    promise: task.promise.then(document => {
      if (typeof document.destroy !== 'function') {
        Object.defineProperty(document, 'destroy', { value: destroy });
      }
      return document;
    }),
    destroy,
  };
}
