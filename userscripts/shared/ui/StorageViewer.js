export class StorageViewer {
  constructor({ storagePrefix, classPrefix }) {
    this.storagePrefix = storagePrefix;
    this.prefix = classPrefix;
  }

  render() {
    this.element = document.createElement("div");
    this.element.className = `${this.prefix}-storage`;
    this.renderList();
    return this.element;
  }

  keys() {
    const keys = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith(this.storagePrefix)) keys.push(key);
    }
    return keys.sort();
  }

  renderList() {
    const p = this.prefix;
    this.element.innerHTML = "";

    const keys = this.keys();
    let total = 0;

    const head = document.createElement("div");
    head.className = `${p}-storage-head`;
    this.element.appendChild(head);

    if (!keys.length) {
      const empty = document.createElement("p");
      empty.className = `${p}-storage-empty`;
      empty.textContent = "No stored data.";
      this.element.appendChild(empty);
      head.textContent = "0 keys";
      return;
    }

    for (const key of keys) {
      const value = localStorage.getItem(key) || "";
      total += key.length + value.length;

      const item = document.createElement("details");
      item.className = `${p}-storage-item`;

      const summary = document.createElement("summary");
      summary.className = `${p}-storage-summary`;

      const name = document.createElement("code");
      name.className = `${p}-storage-key`;
      name.textContent = key;

      const size = document.createElement("span");
      size.className = `${p}-storage-size`;
      size.textContent = formatSize(value.length);

      const del = document.createElement("button");
      del.type = "button";
      del.className = `${p}-storage-delete`;
      del.textContent = "Delete";
      del.onclick = (e) => {
        e.preventDefault();
        e.stopPropagation();
        if (del.textContent !== "Sure?") {
          del.textContent = "Sure?";
          return;
        }
        localStorage.removeItem(key);
        this.renderList();
      };

      summary.append(name, size, del);
      item.appendChild(summary);

      const pre = document.createElement("pre");
      pre.className = `${p}-storage-value`;
      pre.textContent = prettify(value);
      item.appendChild(pre);

      this.element.appendChild(item);
    }

    head.textContent = `${keys.length} keys · ${formatSize(total)} total`;
  }
}

function prettify(value) {
  try {
    return JSON.stringify(JSON.parse(value), null, 2);
  } catch {
    return value;
  }
}

function formatSize(chars) {
  if (chars < 1024) return `${chars} B`;
  return `${(chars / 1024).toFixed(1)} KB`;
}
