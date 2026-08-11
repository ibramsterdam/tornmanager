export class MuggingSection {
  constructor(api) {
    this.api = api;
  }

  render() {
    const section = document.createElement("div");
    section.className = "tm-mugging";

    const title = document.createElement("h2");
    title.className = "tm-mugging-title";
    title.textContent = "Mugging";

    const note = document.createElement("p");
    note.className = "tm-mugging-note";
    note.textContent = "Work in progress — this tab is still under development.";

    section.appendChild(title);
    section.appendChild(note);

    return section;
  }

  destroy() {}
}
