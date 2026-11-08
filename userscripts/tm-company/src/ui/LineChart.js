import { Dom } from "@shared/core/Dom.js";
import { day } from "../core/Format.js";

const SVG_NS = "http://www.w3.org/2000/svg";
const WIDTH = 600;
const HEIGHT = 170;
const PAD = { top: 10, right: 10, bottom: 22, left: 52 };
const COLORS = ["#34d399", "#9a9aa2", "#e8b93d", "#60a5fa"];

export class LineChart {
  constructor({ title, dates, series, format }) {
    this.title = title;
    this.dates = dates;
    this.series = series.map((item, index) => ({ ...item, color: item.color || COLORS[index % COLORS.length] }));
    this.format = format;
  }

  render() {
    const card = Dom.el("div", "tc-card tc-chart");
    const head = Dom.el("div", "tc-chart-head");
    head.appendChild(Dom.el("div", "tc-label", this.title));
    this.readout = Dom.el("div", "tc-chart-readout tc-dim");
    head.appendChild(this.readout);
    card.appendChild(head);

    const values = this.series.flatMap((item) => item.values).filter((value) => value != null);
    if (!values.length) {
      card.appendChild(Dom.el("div", "tc-chart-empty tc-dim", "No data yet. It fills up day by day."));
      return card;
    }

    this.min = Math.min(...values, 0);
    this.max = Math.max(...values);
    if (this.max === this.min) this.max = this.min + 1;

    const svg = svgEl("svg", { viewBox: `0 0 ${WIDTH} ${HEIGHT}`, class: "tc-chart-svg", role: "img", "aria-label": this.title });
    this.drawGrid(svg);
    for (const item of this.series) svg.appendChild(this.line(item));
    this.drawHover(svg);
    card.appendChild(svg);
    card.appendChild(this.legend());
    this.showReadout(this.lastIndex());
    return card;
  }

  x(index) {
    const span = Math.max(this.dates.length - 1, 1);
    return PAD.left + (index / span) * (WIDTH - PAD.left - PAD.right);
  }

  y(value) {
    return PAD.top + (1 - (value - this.min) / (this.max - this.min)) * (HEIGHT - PAD.top - PAD.bottom);
  }

  drawGrid(svg) {
    for (const fraction of [0, 0.5, 1]) {
      const value = this.min + (this.max - this.min) * fraction;
      const y = this.y(value);
      svg.appendChild(svgEl("line", { x1: PAD.left, x2: WIDTH - PAD.right, y1: y, y2: y, class: "tc-chart-grid" }));
      const label = svgEl("text", { x: PAD.left - 6, y: y + 3, "text-anchor": "end", class: "tc-chart-axis" });
      label.textContent = this.format(value);
      svg.appendChild(label);
    }
    const last = this.dates.length - 1;
    for (const index of [0, Math.round(last / 2), last]) {
      const label = svgEl("text", { x: this.x(index), y: HEIGHT - 6, "text-anchor": index === 0 ? "start" : index === last ? "end" : "middle", class: "tc-chart-axis" });
      label.textContent = day(this.dates[index]);
      svg.appendChild(label);
    }
  }

  line(item) {
    let path = "";
    let open = false;
    item.values.forEach((value, index) => {
      if (value == null) {
        open = false;
        return;
      }
      path += `${open ? "L" : "M"}${this.x(index).toFixed(1)},${this.y(value).toFixed(1)}`;
      open = true;
    });
    const group = svgEl("g");
    group.appendChild(svgEl("path", { d: path, stroke: item.color, class: `tc-chart-line${item.dashed ? " tc-chart-line--dashed" : ""}` }));
    item.values.forEach((value, index) => {
      const prev = item.values[index - 1];
      const next = item.values[index + 1];
      if (value != null && prev == null && next == null) {
        group.appendChild(svgEl("circle", { cx: this.x(index), cy: this.y(value), r: 2.5, fill: item.color }));
      }
    });
    return group;
  }

  drawHover(svg) {
    const cursor = svgEl("line", { y1: PAD.top, y2: HEIGHT - PAD.bottom, class: "tc-chart-cursor" });
    cursor.style.display = "none";
    const area = svgEl("rect", { x: PAD.left, y: PAD.top, width: WIDTH - PAD.left - PAD.right, height: HEIGHT - PAD.top - PAD.bottom, fill: "transparent" });
    area.addEventListener("mousemove", (event) => {
      const box = svg.getBoundingClientRect();
      const svgX = ((event.clientX - box.left) / box.width) * WIDTH;
      const span = Math.max(this.dates.length - 1, 1);
      const index = Math.max(0, Math.min(this.dates.length - 1, Math.round(((svgX - PAD.left) / (WIDTH - PAD.left - PAD.right)) * span)));
      cursor.setAttribute("x1", this.x(index));
      cursor.setAttribute("x2", this.x(index));
      cursor.style.display = "";
      this.showReadout(index);
    });
    area.addEventListener("mouseleave", () => {
      cursor.style.display = "none";
      this.showReadout(this.lastIndex());
    });
    svg.append(cursor, area);
  }

  legend() {
    const legend = Dom.el("div", "tc-chart-legend");
    for (const item of this.series) {
      const entry = Dom.el("span", "tc-chart-key");
      const swatch = Dom.el("span", "tc-chart-swatch");
      swatch.style.background = item.color;
      entry.append(swatch, item.label);
      legend.appendChild(entry);
    }
    return legend;
  }

  lastIndex() {
    for (let index = this.dates.length - 1; index >= 0; index -= 1) {
      if (this.series.some((item) => item.values[index] != null)) return index;
    }
    return this.dates.length - 1;
  }

  showReadout(index) {
    const parts = this.series
      .filter((item) => item.values[index] != null)
      .map((item) => `${item.label} ${this.format(item.values[index])}`);
    this.readout.textContent = parts.length ? `${day(this.dates[index])} · ${parts.join(" · ")}` : day(this.dates[index]);
  }
}

function svgEl(tag, attributes = {}) {
  const node = document.createElementNS(SVG_NS, tag);
  for (const [name, value] of Object.entries(attributes)) node.setAttribute(name, value);
  return node;
}
