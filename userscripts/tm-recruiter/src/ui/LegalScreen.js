import { Dom } from "@shared/core/Dom.js";

const PRIVACY_HTML = `
<h2 id="rc-privacy">Privacy Policy</h2>
<p class="rc-legal-sub">Last updated: 19 August 2026</p>

<h3>Introduction</h3>
<p>Hi, I'm Bram, the creator of Recruiter and TornManager. This Privacy Policy covers the <strong>Recruiter userscript</strong>, the script you install in a userscript manager (such as Tampermonkey) or in Torn PDA. It runs on Torn.com pages and helps you find recruitable players in Torn companies.</p>

<h3>Information I collect</h3>
<p>When you sign in you provide your <strong>Torn API key</strong> (Public access only). The key is sent to the TornManager server to check who you are with the official Torn API and to verify your subscription. On the server, your account consists of your Torn ID, player name, level, your API key as the sign-in credential, and Xanax payments with subscription expiration dates. Recruiter shares this account with the TornManager userscript: one subscription covers both.</p>

<h3>What stays in your browser</h3>
<p>Everything Recruiter collects to do its job stays on your device: additional API keys you add to the key pool, company rosters, player working stats, online status data, and your settings. None of it is uploaded anywhere. Additional pool keys are <strong>never sent to the TornManager server</strong>; they are used only for direct calls to the official Torn API.</p>

<h3>Calls to the Torn API</h3>
<p>Recruiter fetches public data (company listings, employee lists, Hall of Fame working stats) directly from api.torn.com using the keys in your pool. Every call carries the comment "Recruiter" so any key owner can see in their own Torn log what the key was used for. Only add keys that their owners gave you willingly.</p>

<h3>Data sharing</h3>
<p>Nobody. I do not sell, rent, or share any of this data. The recruiting data on your device is yours.</p>

<h3>Data removal</h3>
<p>Use "Remove API key" to sign out and delete your local session, or remove individual pool keys on the Keys screen. To remove your account and key from the TornManager server, contact me in Torn: <strong>Bram [2728237]</strong>.</p>
`;

const TOS_HTML = `
<h2 id="rc-terms">Terms of Service</h2>
<p class="rc-legal-sub">Last updated: 19 August 2026</p>

<h3>The service</h3>
<p>Recruiter is a Torn userscript that surfaces publicly available game data (company rosters, working stats from the Hall of Fame, online status) to help with company recruiting. It is provided as is, without warranty of any kind. It is a hobby project, not a company.</p>

<h3>Subscription</h3>
<p>Recruiter requires an active <strong>TornManager subscription</strong>. Send Xanax to Bram [2728237] in Torn to extend it; each Xanax adds one week. The same subscription unlocks the TornManager userscript extras. Payments are voluntary, non-refundable, and are not purchases of goods or services outside of Torn.</p>

<h3>Your responsibilities</h3>
<p>You are responsible for complying with Torn's own rules while using Recruiter. Only Public access keys are accepted, and you may only add pool keys that their owners handed you voluntarily. Do not use Recruiter to harass players. What you do with the information it shows you is your responsibility.</p>

<h3>Fair use</h3>
<p>Recruiter paces its Torn API usage to stay well inside Torn's rate limits per key owner. Do not attempt to modify the script to exceed those limits.</p>

<h3>Changes and termination</h3>
<p>I may update, change, or discontinue Recruiter at any time. I may suspend accounts that abuse the service. If a suspension or discontinuation happens with time left on your subscription, contact me and we will sort it out.</p>

<h3>Contact</h3>
<p>Questions about these terms: message <strong>Bram [2728237]</strong> in Torn.</p>
`;

export class LegalScreen {
  constructor(overlay) {
    this.overlay = overlay;
    this.anchor = null;
  }

  subtitle() {
    return "privacy & terms";
  }

  render(container) {
    const wrap = Dom.el("div", "rc-legal");

    const back = Dom.el("button", "rc-btn rc-btn--ghost", "← Back");
    back.addEventListener("click", () => this.overlay.open());
    wrap.appendChild(back);

    const docs = Dom.el("div", "rc-legal-docs");
    docs.innerHTML = PRIVACY_HTML + '<hr class="rc-legal-divider">' + TOS_HTML;
    wrap.appendChild(docs);
    container.appendChild(wrap);

    if (this.anchor) {
      const target = docs.querySelector(`#${this.anchor}`);
      if (target) requestAnimationFrame(() => target.scrollIntoView({ block: "start" }));
      this.anchor = null;
    }
  }
}
