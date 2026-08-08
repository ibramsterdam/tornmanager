export class WarSection {
  constructor(api) {
    this.api = api;
  }

  render() {
    const section = document.createElement("div");
    section.className = "tm-war";

    const title = document.createElement("h2");
    title.className = "tm-war-title";
    title.textContent = "Ranked War";
    section.appendChild(title);

    const content = document.createElement("div");
    content.className = "tm-war-content";
    section.appendChild(content);

    this.loadWarStatus(content);

    return section;
  }

  loadWarStatus(container) {
    container.innerHTML = "";

    const loading = document.createElement("p");
    loading.className = "tm-war-loading-text";
    loading.textContent = "Loading...";
    container.appendChild(loading);

    this.api
      .fetchCurrentWar()
      .then((response) => {
        container.innerHTML = "";

        if (!response.war) {
          const noWar = document.createElement("p");
          noWar.className = "tm-war-none";
          noWar.textContent = "No active war.";
          container.appendChild(noWar);
          return;
        }

        this.renderWarStatus(container, response.war);
      })
      .catch((err) => {
        container.innerHTML = "";

        const errorEl = document.createElement("p");
        errorEl.className = "tm-war-error";
        errorEl.textContent = err.message || "Could not load war data.";
        container.appendChild(errorEl);
      });
  }

  renderWarStatus(container, war) {
    const members = war.members || {};
    const memberList = Object.values(members);
    const totalMembers = memberList.length;

    const hospitalCount = memberList.filter(
      (m) => m.status?.state === "Hospital"
    ).length;
    const travelingCount = memberList.filter(
      (m) => m.status?.state === "Traveling" || m.status?.state === "Abroad"
    ).length;
    const jailCount = memberList.filter(
      (m) => m.status?.state === "Jail"
    ).length;
    const okayCount = totalMembers - hospitalCount - travelingCount - jailCount;

    const onlineCount = memberList.filter(
      (m) => m.last_action?.status === "Online"
    ).length;
    const idleCount = memberList.filter(
      (m) => m.last_action?.status === "Idle"
    ).length;

    if (war.enemy_faction_name) {
      const enemy = document.createElement("div");
      enemy.className = "tm-war-enemy";

      const label = document.createElement("span");
      label.className = "tm-war-enemy-label";
      label.textContent = "vs";

      const name = document.createElement("a");
      name.className = "tm-war-enemy-name";
      name.href = `https://www.torn.com/factions.php?step=profile&ID=${war.enemy_faction_id}`;
      name.target = "_blank";
      name.rel = "noopener";
      name.textContent = war.enemy_faction_name;

      enemy.appendChild(label);
      enemy.appendChild(name);
      container.appendChild(enemy);
    }

    if (war.our_score != null && war.their_score != null) {
      const score = document.createElement("div");
      score.className = "tm-war-score";

      const ourScore = document.createElement("span");
      ourScore.className = "tm-war-score-ours";
      ourScore.textContent = war.our_score;

      const separator = document.createElement("span");
      separator.className = "tm-war-score-sep";
      separator.textContent = " \u2013 ";

      const theirScore = document.createElement("span");
      theirScore.className = "tm-war-score-theirs";
      theirScore.textContent = war.their_score;

      score.appendChild(ourScore);
      score.appendChild(separator);
      score.appendChild(theirScore);

      if (war.target_score) {
        const target = document.createElement("span");
        target.className = "tm-war-score-target";
        target.textContent = ` / ${war.target_score}`;
        score.appendChild(target);
      }

      container.appendChild(score);
    }

    const breakdown = document.createElement("div");
    breakdown.className = "tm-war-breakdown";

    const statItems = [
      { label: "Okay", value: okayCount, cls: "okay" },
      { label: "Hospital", value: hospitalCount, cls: "hospital" },
      { label: "Traveling", value: travelingCount, cls: "traveling" },
      { label: "Jail", value: jailCount, cls: "jail" },
    ];

    for (const item of statItems) {
      if (item.value === 0) continue;

      const row = document.createElement("div");
      row.className = `tm-war-breakdown-item tm-war-breakdown--${item.cls}`;
      row.innerHTML = `<span class="tm-war-breakdown-value">${item.value}</span><span class="tm-war-breakdown-label">${item.label}</span>`;
      breakdown.appendChild(row);
    }

    container.appendChild(breakdown);

    const activity = document.createElement("div");
    activity.className = "tm-war-activity";

    const activityItems = [
      { label: "Online", value: onlineCount, cls: "online" },
      { label: "Idle", value: idleCount, cls: "idle" },
    ];

    for (const item of activityItems) {
      const row = document.createElement("div");
      row.className = `tm-war-activity-item tm-war-activity--${item.cls}`;
      row.innerHTML = `<span class="tm-war-activity-value">${item.value}</span><span class="tm-war-activity-label">${item.label}</span>`;
      activity.appendChild(row);
    }

    container.appendChild(activity);

    if (war.started_at) {
      const elapsed = Date.now() - new Date(war.started_at).getTime();
      if (elapsed > 0) {
        const duration = document.createElement("div");
        duration.className = "tm-war-duration";
        duration.textContent = `Started ${this.formatDuration(elapsed)} ago`;
        container.appendChild(duration);
      }
    }
  }

  formatDuration(ms) {
    const totalSeconds = Math.floor(ms / 1000);
    const days = Math.floor(totalSeconds / 86400);
    const hours = Math.floor((totalSeconds % 86400) / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);

    const parts = [];
    if (days > 0) parts.push(`${days}d`);
    if (hours > 0) parts.push(`${hours}h`);
    if (minutes > 0 || parts.length === 0) parts.push(`${minutes}m`);

    return parts.join(" ");
  }
}
