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

    this.section.appendChild(this.createHeader());
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

  createHeader() {
    const header = document.createElement("div");
    header.className = "tm-war-head";

    const row = document.createElement("div");
    row.className = "tm-war-head-row";

    this.headLeft = document.createElement("div");
    this.headLeft.className = "tm-war-head-left";
    this.headLeft.textContent = "Loading war status...";

    this.headScore = document.createElement("div");
    this.headScore.className = "tm-war-head-score";

    row.appendChild(this.headLeft);
    row.appendChild(this.headScore);
    header.appendChild(row);

    this.bar = document.createElement("div");
    this.bar.className = "tm-war-bar";
    this.bar.style.display = "none";
    this.barFill = document.createElement("div");
    this.barFill.className = "tm-war-bar-fill";
    this.bar.appendChild(this.barFill);
    header.appendChild(this.bar);

    return header;
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
    button.textContent = "Add";

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
        this.updateHeader();
        this.refreshTable();
      })
      .catch((err) => {
        this.headLeft.className = "tm-war-head-left tm-war-head-left--error";
        this.headLeft.textContent = err.message || "Could not load war data.";
      });
  }

  updateHeader() {
    this.headLeft.className = "tm-war-head-left";
    this.headLeft.innerHTML = "";
    this.headScore.innerHTML = "";

    if (!this.war) {
      this.headLeft.classList.add("tm-war-head-left--muted");
      this.headLeft.textContent = "No active war.";
      this.bar.style.display = "none";
      return;
    }

    const vs = document.createElement("span");
    vs.className = "tm-war-head-vs";
    vs.textContent = "vs";

    const enemy = document.createElement("a");
    enemy.className = "tm-war-head-enemy";
    enemy.href = `https://www.torn.com/factions.php?step=profile&ID=${this.war.enemy_faction_id}`;
    enemy.target = "_blank";
    enemy.rel = "noopener";
    enemy.textContent = this.war.enemy_faction_name || "Unknown faction";

    this.headLeft.appendChild(vs);
    this.headLeft.appendChild(enemy);

    const ours = this.war.our_score || 0;
    const theirs = this.war.their_score || 0;
    const target = this.war.target_score || 0;
    const lead = ours - theirs;

    const ourScore = document.createElement("span");
    ourScore.className = ours >= theirs ? "tm-war-score--up" : "tm-war-score--down";
    ourScore.textContent = ours.toLocaleString();

    const separator = document.createElement("span");
    separator.className = "tm-war-head-sep";
    separator.textContent = " – ";

    const theirScore = document.createElement("span");
    theirScore.className = theirs >= ours ? "tm-war-score--up" : "tm-war-score--down";
    theirScore.textContent = theirs.toLocaleString();

    this.headScore.appendChild(ourScore);
    this.headScore.appendChild(separator);
    this.headScore.appendChild(theirScore);

    if (target > 0) {
      const targetEl = document.createElement("span");
      targetEl.className = "tm-war-head-target";
      targetEl.textContent = ` / ${target.toLocaleString()}`;
      this.headScore.appendChild(targetEl);

      const percentage = Math.min(Math.max((lead / target) * 100, 0), 100);
      this.bar.style.display = "";
      this.barFill.style.width = `${percentage}%`;
      this.barFill.classList.toggle("tm-war-bar-fill--losing", lead < 0);
    } else {
      this.bar.style.display = "none";
    }
  }
}
