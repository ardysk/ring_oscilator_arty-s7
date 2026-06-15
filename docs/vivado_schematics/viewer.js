(function () {
  const DB = window.VIVADO_SCHEM || {};
  const blocks = DB.blocks || {};
  const hierarchy = DB.hierarchy || {};
  const instanceMap = DB.instanceMap || {};
  const ROOT = DB.root || "ro_top_arty_axi";

  // Vivado: niebieskie prostokaty = moduly RTL, zolte = komorki LUT po syntezie
  const MODULE_FILL = "#dfebf8";

  const el = {
    back: document.getElementById("back"),
    sel: document.getElementById("sel"),
    crumbs: document.getElementById("crumbs"),
    children: document.getElementById("children"),
    viewport: document.getElementById("viewport"),
    canvas: document.getElementById("canvas"),
    svgHost: document.getElementById("svgHost"),
    tip: document.getElementById("tip"),
    zoomIn: document.getElementById("zoomIn"),
    zoomOut: document.getElementById("zoomOut"),
    fit: document.getElementById("fit"),
    reset: document.getElementById("reset"),
    zoomLbl: document.getElementById("zoomLbl"),
  };

  let current = ROOT;
  let history = [ROOT];
  let view = { x: 0, y: 0, scale: 1 };
  let panCandidate = null;
  let panning = false;

  function esc(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  function normalizeModule(name) {
    return String(name || "")
      .trim()
      .replace(/__\d+$/, "");
  }

  function resolveBlock(label) {
    const t = String(label || "").trim();
    if (!t || t.length < 3) return null;

    for (const [inst, id] of Object.entries(instanceMap)) {
      if (
        t === inst ||
        t.startsWith(inst + "_") ||
        t.endsWith("." + inst) ||
        t.includes("." + inst + ".") ||
        t.includes("." + inst)
      ) {
        if (blocks[id]) return id;
      }
    }

    const mod = normalizeModule(t);
    if (blocks[mod]) return mod;

    // najdluzsze dopasowanie modulu (unikaj mylenia ro_top / ro_top_arty_axi)
    let best = null;
    for (const key of Object.keys(blocks)) {
      if (t === key || t.includes(key)) {
        if (!best || key.length > best.length) best = key;
      }
    }
    return best;
  }

  function childrenOf(parentId) {
    return hierarchy[parentId] || [];
  }

  function isChildOf(parentId, childId) {
    return childrenOf(parentId).includes(childId);
  }

  function applyTransform() {
    el.canvas.style.transform = `translate(${view.x}px, ${view.y}px) scale(${view.scale})`;
    el.zoomLbl.textContent = `${Math.round(view.scale * 100)}%`;
  }

  function getSvgSize() {
    const svg = el.svgHost.querySelector("svg");
    if (!svg) return { w: 1, h: 1 };
    const vb = svg.viewBox && svg.viewBox.baseVal;
    if (vb && vb.width > 0 && vb.height > 0) {
      return { w: vb.width, h: vb.height };
    }
    const r = svg.getBoundingClientRect();
    return { w: r.width || 1, h: r.height || 1 };
  }

  function fitToView() {
    const { w, h } = getSvgSize();
    const vw = el.viewport.clientWidth;
    const vh = el.viewport.clientHeight;
    const pad = 24;
    const scale = Math.min((vw - pad) / w, (vh - pad) / h, 4);
    view.scale = Math.max(0.05, scale);
    view.x = (vw - w * view.scale) / 2;
    view.y = (vh - h * view.scale) / 2;
    applyTransform();
  }

  function resetZoom() {
    view.scale = 1;
    view.x = 20;
    view.y = 20;
    applyTransform();
  }

  function zoomAt(factor, cx, cy) {
    const rect = el.viewport.getBoundingClientRect();
    const px = (cx ?? rect.left + rect.width / 2) - rect.left;
    const py = (cy ?? rect.top + rect.height / 2) - rect.top;
    const wx = (px - view.x) / view.scale;
    const wy = (py - view.y) / view.scale;
    view.scale = Math.min(8, Math.max(0.05, view.scale * factor));
    view.x = px - wx * view.scale;
    view.y = py - wy * view.scale;
    applyTransform();
  }

  function showTip(x, y, title, desc, hint) {
    el.tip.hidden = false;
    el.tip.style.left = `${x + 14}px`;
    el.tip.style.top = `${y + 14}px`;
    const clickHint = hint ? `\n${hint}` : "";
    el.tip.innerHTML =
      `<strong>${esc(title)}</strong>${esc(desc || "")}${esc(clickHint)}`;
  }

  function hideTip() {
    el.tip.hidden = true;
  }

  function updateBack() {
    el.back.disabled = history.length <= 1;
  }

  function renderChildrenBar() {
    const kids = childrenOf(current);
    if (!kids.length) {
      el.children.hidden = true;
      el.children.innerHTML = "";
      return;
    }
    el.children.hidden = false;
    el.children.innerHTML =
      `<span class="label">Podmoduly:</span>` +
      kids
        .map(
          (id) =>
            `<button type="button" data-child="${esc(id)}">${esc(id)}</button>`
        )
        .join("");
    el.children.querySelectorAll("button").forEach((btn) => {
      btn.addEventListener("click", () => drillDown(btn.dataset.child));
    });
  }

  function bindDrillable(node, targetId) {
    if (!targetId || !blocks[targetId] || !isChildOf(current, targetId)) return;

    const b = blocks[targetId];
    node.setAttribute("data-drill", targetId);
    node.style.cursor = "pointer";

    const onEnter = (e) => {
      showTip(
        e.clientX,
        e.clientY,
        targetId,
        b.desc,
        "Kliknij, aby otworzyc schemat podmodulu"
      );
    };

    node.addEventListener("mouseenter", onEnter);
    node.addEventListener("mousemove", onEnter);
    node.addEventListener("mouseleave", hideTip);
    node.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      drillDown(targetId);
    });
  }

  function findModuleTargetNear(pathEl, svg) {
    const groups = [];
    let g = pathEl.parentElement;
    if (g) {
      groups.push(g);
      let s = g;
      for (let i = 0; i < 6; i++) {
        s = s.nextElementSibling;
        if (!s) break;
        groups.push(s);
      }
      let p = g.parentElement;
      if (p && p !== svg) groups.push(p);
    }

    for (const group of groups) {
      if (!group.querySelectorAll) continue;
      for (const tx of group.querySelectorAll("text")) {
        const t = resolveBlock(tx.textContent);
        if (t && isChildOf(current, t)) return t;
      }
    }

    try {
      const bb = pathEl.getBBox();
      const pad = 12;
      for (const tx of svg.querySelectorAll("text")) {
        const tb = tx.getBBox();
        const cx = tb.x + tb.width / 2;
        const cy = tb.y + tb.height / 2;
        if (
          cx >= bb.x - pad &&
          cx <= bb.x + bb.width + pad &&
          cy >= bb.y - pad &&
          cy <= bb.y + bb.height + pad
        ) {
          const t = resolveBlock(tx.textContent);
          if (t && isChildOf(current, t)) return t;
        }
      }
    } catch (_) {
      /* ignore */
    }
    return null;
  }

  function addHitRect(svg, bb, targetId) {
    const NS = "http://www.w3.org/2000/svg";
    let layer = svg.querySelector("#drill-hotspots");
    if (!layer) {
      layer = document.createElementNS(NS, "g");
      layer.setAttribute("id", "drill-hotspots");
      svg.appendChild(layer);
    }
    const r = document.createElementNS(NS, "rect");
    r.setAttribute("x", bb.x - 4);
    r.setAttribute("y", bb.y - 4);
    r.setAttribute("width", bb.width + 8);
    r.setAttribute("height", bb.height + 8);
    r.setAttribute("fill", "transparent");
    r.setAttribute("stroke", "none");
    r.setAttribute("pointer-events", "all");
    bindDrillable(r, targetId);
    layer.appendChild(r);
  }

  function wireSvg(svg) {
    const hooked = new Set();

    function hookNode(node, targetId) {
      if (!node || hooked.has(node)) return;
      hooked.add(node);
      bindDrillable(node, targetId);
    }

    // 1) Niebieskie bloki modulow RTL (#dfebf8) — glowna nawigacja hierarchii
    svg.querySelectorAll("path").forEach((path) => {
      const fill = (path.getAttribute("fill") || "").toLowerCase();
      if (fill !== MODULE_FILL) return;

      const target = findModuleTargetNear(path, svg);
      if (!target) return;

      hookNode(path, target);
      try {
        addHitRect(svg, path.getBBox(), target);
      } catch (_) {
        /* ignore */
      }
    });

    // 2) Etykiety modulow (druga linia: dy="7.7")
    svg.querySelectorAll('text[dy="7.7"]').forEach((modTx) => {
      const target = resolveBlock(modTx.textContent);
      if (!target || !isChildOf(current, target)) return;
      hookNode(modTx, target);
      const prev = modTx.previousElementSibling;
      if (prev && prev.tagName === "text") hookNode(prev, target);
    });

    // 3) Nazwy instancji (u_core, u_map, ...)
    svg.querySelectorAll("text").forEach((tx) => {
      const target = resolveBlock(tx.textContent);
      if (!target || !isChildOf(current, target)) return;
      hookNode(tx, target);
    });
  }

  async function loadSvg(blockId, url) {
    let text = window.SVG_BUNDLE && window.SVG_BUNDLE[blockId];
    if (!text) {
      if (location.protocol === "file:") {
        throw new Error(
          "Brak svg-bundle.js — uruchom: python scripts/embed_vivado_svgs.py"
        );
      }
      const res = await fetch(url);
      if (!res.ok) throw new Error("Brak pliku: " + url);
      text = await res.text();
    }
    el.svgHost.innerHTML = text;
    const svg = el.svgHost.querySelector("svg");
    if (!svg) throw new Error("Brak <svg>");
    wireSvg(svg);
    requestAnimationFrame(fitToView);
  }

  function renderCrumbs() {
    el.crumbs.innerHTML = history
      .map((id, i) => {
        const sep = i > 0 ? " / " : "";
        if (i === history.length - 1) return sep + esc(id);
        return `${sep}<a href="#" data-i="${i}">${esc(id)}</a>`;
      })
      .join("");
    el.crumbs.querySelectorAll("a").forEach((a) => {
      a.addEventListener("click", (e) => {
        e.preventDefault();
        const i = Number(a.dataset.i);
        history = history.slice(0, i + 1);
        openBlock(history[i], false);
      });
    });
  }

  function buildSelect() {
    const ids = Object.keys(blocks).sort();
    el.sel.innerHTML = ids
      .map((id) => `<option value="${esc(id)}">${esc(id)}</option>`)
      .join("");
    el.sel.value = current;
  }

  async function openBlock(id, pushHistory) {
    const b = blocks[id];
    if (!b) return;
    current = id;
    if (pushHistory !== false && history[history.length - 1] !== id) {
      history.push(id);
    }
    el.sel.value = id;
    renderCrumbs();
    renderChildrenBar();
    updateBack();
    hideTip();
    await loadSvg(id, b.svg);
  }

  function drillDown(id) {
    if (!blocks[id] || !isChildOf(current, id)) return;
    history.push(id);
    openBlock(id, false);
  }

  function goBack() {
    if (history.length <= 1) return;
    history.pop();
    openBlock(history[history.length - 1], false);
  }

  el.back.addEventListener("click", goBack);
  el.zoomIn.addEventListener("click", () => zoomAt(1.25));
  el.zoomOut.addEventListener("click", () => zoomAt(1 / 1.25));
  el.fit.addEventListener("click", fitToView);
  el.reset.addEventListener("click", resetZoom);

  el.viewport.addEventListener(
    "wheel",
    (e) => {
      e.preventDefault();
      zoomAt(e.deltaY < 0 ? 1.12 : 1 / 1.12, e.clientX, e.clientY);
    },
    { passive: false }
  );

  // Pan tylko gdy nie klikamy w modul i gdy faktycznie przeciagniemy
  el.viewport.addEventListener("mousedown", (e) => {
    if (e.button !== 0) return;
    if (e.target.closest("[data-drill]")) return;
    panCandidate = { x: e.clientX, y: e.clientY, vx: view.x, vy: view.y };
    panning = false;
  });

  window.addEventListener("mousemove", (e) => {
    if (!panCandidate) return;
    const dx = e.clientX - panCandidate.x;
    const dy = e.clientY - panCandidate.y;
    if (!panning) {
      if (Math.hypot(dx, dy) < 5) return;
      panning = true;
      el.viewport.classList.add("panning");
    }
    view.x = panCandidate.vx + dx;
    view.y = panCandidate.vy + dy;
    applyTransform();
  });

  window.addEventListener("mouseup", () => {
    panCandidate = null;
    panning = false;
    el.viewport.classList.remove("panning");
  });

  el.sel.addEventListener("change", () => {
    history = [el.sel.value];
    openBlock(el.sel.value, false);
  });

  window.addEventListener("resize", fitToView);

  buildSelect();
  openBlock(ROOT, false);
})();
