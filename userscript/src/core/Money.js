export function parseMoney(str) {
  const s = String(str || "")
    .trim()
    .toLowerCase()
    .replace(/[$,\s]/g, "");
  const match = /^([0-9]*\.?[0-9]+)([kmb])?$/.exec(s);
  if (!match) return NaN;

  let n = parseFloat(match[1]);
  if (match[2] === "k") n *= 1e3;
  else if (match[2] === "m") n *= 1e6;
  else if (match[2] === "b") n *= 1e9;
  return n;
}

export function formatMoney(n) {
  if (!Number.isFinite(n) || n === 0) return "$0";
  const sign = n < 0 ? "-" : "";
  const abs = Math.abs(n);
  if (abs >= 1e9) return `${sign}$${trim(abs / 1e9)}b`;
  if (abs >= 1e6) return `${sign}$${trim(abs / 1e6)}m`;
  if (abs >= 1e3) return `${sign}$${trim(abs / 1e3)}k`;
  return `${sign}$${Math.round(abs).toLocaleString("en-US")}`;
}

function trim(x) {
  return x.toFixed(2).replace(/\.?0+$/, "");
}
