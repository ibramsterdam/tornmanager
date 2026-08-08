const STORAGE_KEY = "tm_errors";
const MAX_ENTRIES = 50;

export class Logger {
  log(error, context = "unknown") {
    const errors = this.getAll();
    const entry = {
      message: error?.message || String(error),
      stack: error?.stack || null,
      context,
      timestamp: new Date().toISOString(),
    };

    errors.push(entry);
    if (errors.length > MAX_ENTRIES) errors.splice(0, errors.length - MAX_ENTRIES);

    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(errors));
    } catch {
      // localStorage full or unavailable
    }
  }

  getAll() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return raw ? JSON.parse(raw) : [];
    } catch {
      return [];
    }
  }

  clear() {
    localStorage.removeItem(STORAGE_KEY);
  }

  format() {
    const errors = this.getAll();
    if (!errors.length) return "No errors logged.";

    return errors
      .map(
        (e, i) =>
          `[${i + 1}] ${e.timestamp}\nContext: ${e.context}\nMessage: ${e.message}${e.stack ? `\nStack: ${e.stack}` : ""}`
      )
      .join("\n\n");
  }
}
