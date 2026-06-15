// Mapowania klików dla PDF exportów z Vivado.
//
// Współrzędne są w pikselach canvas po renderze (czyli zależą od skali).
// Viewer trzyma stałą skalę (na start 1.5), więc wpisy będą stabilne.
//
// Format:
// window.VIVADO_PDF_MAP = {
//   "mb_ro_system.pdf": {
//      page: 1,
//      links: [
//        { id: "ro_axi_0", x: 120, y: 220, w: 160, h: 70, title: "ro_axi_0", desc: "Custom IP: RO + CSR", goto: { pdf: "ro_axi_0.pdf", page: 1 } },
//      ]
//   }
// }

window.VIVADO_PDF_FILES = [
  // Dodaj tu pliki (muszą istnieć w docs/vivado_diagrams/)
  "mb_ro_system.pdf",
];

window.VIVADO_PDF_MAP = {
  // Wypełnij po eksporcie PDF z Vivado:
  // "mb_ro_system.pdf": { page: 1, links: [ ... ] }
};

