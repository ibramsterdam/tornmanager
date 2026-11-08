const SUFFIXES = [
  [1e12, "t"],
  [1e9, "b"],
  [1e6, "m"],
  [1e3, "k"],
];

export function money(value) {
  if (value == null) return "–";
  const sign = value < 0 ? "-" : "";
  return `${sign}$${short(Math.abs(value))}`;
}

export function short(value) {
  if (value == null) return "–";
  for (const [size, suffix] of SUFFIXES) {
    if (Math.abs(value) >= size) return `${trim(value / size)}${suffix}`;
  }
  return trim(value);
}

export function number(value) {
  if (value == null) return "–";
  return Math.round(value).toLocaleString("en-US");
}

export function percent(value) {
  if (value == null) return "–";
  return `${trim(value)}%`;
}

export function day(value) {
  return new Date(`${value}T00:00:00Z`).toLocaleDateString("en-GB", { day: "numeric", month: "short", timeZone: "UTC" });
}

export function ago(value) {
  if (!value) return "never";
  const minutes = Math.round((Date.now() - new Date(value).getTime()) / 60_000);
  if (minutes < 1) return "just now";
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.round(minutes / 60);
  if (hours < 48) return `${hours} h ago`;
  return `${Math.round(hours / 24)} days ago`;
}

function trim(value) {
  const rounded = Math.abs(value) >= 100 ? Math.round(value) : Math.round(value * 10) / 10;
  return String(rounded);
}
