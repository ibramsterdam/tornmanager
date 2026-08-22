const API_BASE = __API_BASE__;

// POST JSON to the tornmanager API, adding the bearer token when given.
// Rejects with an Error carrying .status, .rateLimited and .suspended.
export function post(path, body = {}, { token = null } = {}) {
  const headers = {
    "Content-Type": "application/json",
    Accept: "application/json",
  };
  if (token) headers.Authorization = `Bearer ${token}`;

  return new Promise((resolve, reject) => {
    GM.xmlHttpRequest({
      method: "POST",
      url: `${API_BASE}${path}`,
      headers,
      data: JSON.stringify(body),
      onload(response) {
        let data = null;
        try {
          data = JSON.parse(response.responseText);
        } catch {
          data = null;
        }
        if (response.status >= 200 && response.status < 300 && data) {
          resolve(data);
        } else {
          const error = new Error(data?.error || "Request failed");
          error.status = response.status;
          if (response.status === 429) error.rateLimited = true;
          if (data?.suspended) error.suspended = true;
          reject(error);
        }
      },
      onerror() {
        reject(new Error("Network error. Could not reach Tornmanager."));
      },
    });
  });
}
