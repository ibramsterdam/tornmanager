const PRIVACY_URL = "https://tornmanager.com/legal#userscript-privacy-policy";
const TOS_URL = "https://tornmanager.com/legal#userscript-terms-of-service";

const LINKS =
  `<a href="${PRIVACY_URL}" target="_blank" rel="noopener">Privacy Policy</a> and ` +
  `<a href="${TOS_URL}" target="_blank" rel="noopener">Terms of Service</a>`;

export const MAIN_KEY_DISCLOSURE = {
  storage: "Persistent until you remove your key",
  sharing: "Nobody (your data is private)",
  purpose: "Signing in and running chat, faction and war features",
  keyStorage: "Stored in the TornManager database, used only for automation",
  access: "Public access (minimum)",
  agreeHtml: `I agree to the ${LINKS}, including use of essential cookies and anonymous analytics.`,
};

export const MUG_KEY_DISCLOSURE = {
  storage: "Read live from Torn, nothing is stored on a server",
  sharing: "Nobody. The key never leaves your device",
  purpose:
    "Reading your attack mug logs, and checking the public status of sellers on Bazaar and Item Market pages " +
    "to find mug targets (competitive advantage)",
  keyStorage: "Stored only in this browser; never sent to TornManager",
  access: "Full Access (required)",
  agreeHtml: `I agree to the ${LINKS}.`,
};

const ITEMS = [
  ["Data Storage", "storage"],
  ["Data Sharing", "sharing"],
  ["Purpose of Use", "purpose"],
  ["Key Storage & Sharing", "keyStorage"],
  ["Key Access Level", "access"],
];

export class ApiDisclosure {
  constructor(info, onAgreeChange) {
    this.info = info;
    this.onAgreeChange = onAgreeChange;
  }

  render() {
    const wrap = document.createElement("div");
    wrap.className = "tm-tos";

    const heading = document.createElement("p");
    heading.className = "tm-tos-heading";
    heading.textContent = "How your key and data are handled";
    wrap.appendChild(heading);

    const grid = document.createElement("div");
    grid.className = "tm-tos-grid";
    for (const [label, field] of ITEMS) {
      const item = document.createElement("div");
      item.className = "tm-tos-item";

      const labelEl = document.createElement("span");
      labelEl.className = "tm-tos-label";
      labelEl.textContent = label;

      const valueEl = document.createElement("span");
      valueEl.className = "tm-tos-value";
      valueEl.textContent = this.info[field];

      item.appendChild(labelEl);
      item.appendChild(valueEl);
      grid.appendChild(item);
    }
    wrap.appendChild(grid);

    const agree = document.createElement("label");
    agree.className = "tm-tos-agree";

    this.checkbox = document.createElement("input");
    this.checkbox.type = "checkbox";
    this.checkbox.className = "tm-tos-checkbox";
    this.checkbox.addEventListener("change", () => this.onAgreeChange?.(this.checkbox.checked));

    const text = document.createElement("span");
    text.innerHTML = this.info.agreeHtml;

    agree.appendChild(this.checkbox);
    agree.appendChild(text);
    wrap.appendChild(agree);

    return wrap;
  }

  isAgreed() {
    return !!this.checkbox?.checked;
  }
}
