export class Dom {
  static ready(selector, callback) {
    const el = document.querySelector(selector);
    if (el) return callback(el);

    new MutationObserver((_, observer) => {
      const el = document.querySelector(selector);
      if (el) {
        observer.disconnect();
        callback(el);
      }
    }).observe(document.documentElement, { childList: true, subtree: true });
  }
}
