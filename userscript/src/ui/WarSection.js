import { Targets } from "../core/Targets.js";
import { TargetTable } from "./TargetTable.js";

const POLL_INTERVAL_MS = 6000;

export class WarSection {
  constructor(api) {
    this.api = api;
    this.targets = new Targets();
    this.members = {};
    this.war = null;
    this.pollInterval = null;
    this.table = null;
  }

  render() {
    this.section = document.createElement("div");
    this.section.className = "tm-war";

    this.warLine = document.createElement("div");
    this.warLine.className = "tm-war-line tm-war-line--muted";
    this.warLine.textContent = "Loading war status...";
    this.section.appendChild(this.warLine);

    this.section.appendChild(this.createAddForm());

    this.table = new TargetTable({ onRemove: (id) => this.removeTarget(id) });
    this.tableWrap = this.table.render();
    this.section.appendChild(this.tableWrap);

    this.emptyEl = document.createElement("p");
    this.emptyEl.className = "tm-tt-empty";
    this.emptyEl.textContent = "No targets yet. Add a player by their Torn ID.";
    this.section.appendChild(this.emptyEl);

    this.refreshTable();
    this.poll();
    this.pollInterval = setInterval(() => this.poll(), POLL_INTERVAL_MS);

    return this.section;
  }

  destroy() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }
    if (this.table) {
      this.table.destroy();
      this.table = null;
    }
  }

  createAddForm() {
    const form = document.createElement("form");
    form.className = "tm-tt-add";

    this.input = document.createElement("input");
    this.input.type = "text";
    this.input.className = "tm-tt-add-input";
    this.input.placeholder = "Torn ID or profile link";
    this.input.autocomplete = "off";
    this.input.spellcheck = false;

    const button = document.createElement("button");
    button.type = "submit";
    button.className = "tm-tt-add-button";
    button.textContent = "Add target";

    this.addError = document.createElement("span");
    this.addError.className = "tm-tt-add-error";

    form.appendChild(this.input);
    form.appendChild(button);
    form.appendChild(this.addError);

    form.addEventListener("submit", (e) => {
      e.preventDefault();
      this.addTarget(this.input.value);
    });

    return form;
  }

  addTarget(value) {
    this.addError.textContent = "";

    const id = Targets.parseId(value);
    if (!id) {
      this.addError.textContent = "Enter a Torn ID or profile link.";
      return;
    }

    if (!this.targets.add(id)) {
      this.addError.textContent = "Already in your list.";
      return;
    }

    this.input.value = "";
    this.refreshTable();
  }

  removeTarget(id) {
    this.targets.remove(id);
    this.refreshTable();
  }

  refreshTable() {
    const ids = this.targets.getAll();

    this.emptyEl.style.display = ids.length ? "none" : "";
    this.tableWrap.style.display = ids.length ? "" : "none";

    this.table.update(ids.map((id) => ({ id, member: this.members[id] || null })));
  }

  poll() {
    this.api
      .fetchCurrentWar()
      .then((response) => {
        this.war = response.war || null;
        this.members = this.war?.members || {};
        this.updateWarLine();
        this.refreshTable();
      })
      .catch((err) => {
        this.warLine.className = "tm-war-line tm-war-line--error";
        this.warLine.textContent = err.message || "Could not load war data.";
      });
  }

  updateWarLine() {
    this.warLine.className = "tm-war-line";
    this.warLine.innerHTML = "";

    if (!this.war) {
      this.warLine.classList.add("tm-war-line--muted");
      this.warLine.textContent = "No active war.";
      return;
    }

    const vs = document.createElement("span");
    vs.className = "tm-war-line-vs";
    vs.textContent = "vs";

    const enemy = document.createElement("a");
    enemy.className = "tm-war-line-enemy";
    enemy.href = `https://www.torn.com/factions.php?step=profile&ID=${this.war.enemy_faction_id}`;
    enemy.target = "_blank";
    enemy.rel = "noopener";
    enemy.textContent = this.war.enemy_faction_name || "Unknown faction";

    const ours = this.war.our_score || 0;
    const theirs = this.war.their_score || 0;

    const score = document.createElement("span");
    score.className = "tm-war-line-score";

    const ourScore = document.createElement("span");
    ourScore.className = ours >= theirs ? "tm-war-line-score--up" : "tm-war-line-score--down";
    ourScore.textContent = ours.toLocaleString();

    const separator = document.createElement("span");
    separator.className = "tm-war-line-sep";
    separator.textContent = " – ";

    const theirScore = document.createElement("span");
    theirScore.className = theirs >= ours ? "tm-war-line-score--up" : "tm-war-line-score--down";
    theirScore.textContent = theirs.toLocaleString();

    score.appendChild(ourScore);
    score.appendChild(separator);
    score.appendChild(theirScore);

    this.warLine.appendChild(vs);
    this.warLine.appendChild(enemy);
    this.warLine.appendChild(score);
  }
}
