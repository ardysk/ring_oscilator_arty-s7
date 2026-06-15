const DB = window.VIVADO_SCHEM;
const blocks = DB?.blocks || {};
const clickMap = DB?.clickMap || {};

const el = {
  list: document.getElementById("list"),
  q: document.getElementById("q"),
  svgWrap: document.getElementById("svgWrap"),
  tooltip: document.getElementById("tooltip"),
  mTitle: document.getElementById("mTitle"),
  mFile: document.getElementById("mFile"),
  mDesc: document.getElementById("mDesc"),
  btnTop: document.getElementById("btnTop"),
  btnReset: document.getElementById("btnReset"),
};

let current = "ro_top_arty_axi";
let pan = { x: 0, y: 0, scale: 1 };

function escapeHtml(s) {
  return String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("\"", "&quot;");
}

function setActive(id) {
  [...el.list.querySelectorAll(".item")].forEach(n => {
    n.classList.toggle("active", n.dataset.id === id);
  });
}

function buildList() {
  const entries = Object.entries(blocks).sort((a, b) => a[0].localeCompare(b[0]));
  el.list.innerHTML = "";
  for (const [id, b] of entries) {
    const item = document.createElement("div");
    item.className = "item";
    item.dataset.id = id;
    item.innerHTML = `
      <div class="name">${escapeHtml(id)}</div>
      <div class="sub">${escapeHtml(b.subtitle || "")}</div>
    `;
    item.onclick = () => loadBlock(id);
    el.list.appendChild(item);
  }
}

function applyFilter() {
  const q = (el.q.value || "").toLowerCase().trim();
  for (const node of el.list.querySelectorAll(".item")) {
    const id = node.dataset.id.toLowerCase();
    node.style.display = !q || id.includes(q) ? "" : "none";
  }
}

function tooltipShow(x, y, title, desc) {
  el.tooltip.style.left = `${x + 12}px`;
  el.tooltip.style.top = `${y + 12}px`;
  el.tooltip.innerHTML = `<div class="t">${escapeHtml(title)}</div><div class="d">${escapeHtml(desc || "")}</div>`;
  el.tooltip.style.display = "block";
}

function tooltipHide() {
  el.tooltip.style.display = "none";
}

function findBlockFromText(text) {
  const t = (text || "").trim();
  if (!t) return null;

  // Normalize: Vivado often shows module names verbatim in labels.
  // Try direct match and also substring match over clickMap keys.
  if (clickMap[t]) return clickMap[t];

  for (const k of Object.keys(clickMap)) {
    if (t.includes(k)) return clickMap[k];
  }
  return null;
}

function wireSvgInteractions(svgRoot) {
  // Best-effort: attach events to text nodes.
  // Vivado schematic SVG contains lots of <text> elements; we use their textContent.
  const texts = svgRoot.querySelectorAll("text");
  texts.forEach(tx => {
    const label = (tx.textContent || "").trim();
    const target = findBlockFromText(label);
    if (!target) return;

    tx.style.cursor = "pointer";
    tx.style.fill = "#bcd0ff";

    tx.addEventListener("mousemove", (e) => {
      const b = blocks[target];
      tooltipShow(e.clientX, e.clientY, target, b?.desc || "");
    });
    tx.addEventListener("mouseleave", () => tooltipHide());
    tx.addEventListener("click", () => loadBlock(target));
  });

  // Also show tooltip for any text (even if not clickable) on hover,
  // but only if it's a known block id or key token.
  texts.forEach(tx => {
    const label = (tx.textContent || "").trim();
    const target = findBlockFromText(label);
    if (target) return;
    if (!blocks[label]) return;
    tx.addEventListener("mousemove", (e) => {
      tooltipShow(e.clientX, e.clientY, label, blocks[label]?.desc || "");
    });
    tx.addEventListener("mouseleave", () => tooltipHide());
  });
}

async function loadSvg(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Nie mogę wczytać SVG: ${url}`);
  const text = await res.text();
  // Inline SVG so we can attach events
  el.svgWrap.innerHTML = text;
  const svg = el.svgWrap.querySelector("svg");
  if (!svg) throw new Error("Brak <svg> w pliku.");
  wireSvgInteractions(svg);
}

async function loadBlock(id) {
  const b = blocks[id];
  if (!b) return;
  current = id;

  el.mTitle.textContent = id + (b.subtitle ? ` — ${b.subtitle}` : "");
  el.mFile.textContent = b.file ? `Źródło: ${b.file}` : "";
  el.mDesc.textContent = b.desc || "";
  setActive(id);
  tooltipHide();

  await loadSvg(b.svg);
}

el.q.addEventListener("input", applyFilter);
el.btnTop.addEventListener("click", () => loadBlock("ro_top_arty_axi"));
el.btnReset.addEventListener("click", () => {
  // viewer is scroll-based; reset scroll
  const st = document.querySelector(".stage");
  st.scrollLeft = 0;
  st.scrollTop = 0;
});

buildList();
applyFilter();
loadBlock(current);

