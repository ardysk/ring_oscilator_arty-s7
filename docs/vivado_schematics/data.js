// Data for Vivado schematic viewer (RTL V1)

window.VIVADO_SCHEM = {
  // Domyslny start
  root: "ro_top_arty_axi",

  blocks: {
    ro_top_arty_axi: {
      file: "rtl/common/ro_top_arty_axi.sv",
      svg: "./svg/ro_top_arty_axi.svg",
      subtitle: "Top PL V1",
      desc: "Top logiki PL V1: CSR AXI, 16 bankow RO, mux banku + dzielnik, preskaler, pomiary ring/out oraz wyjscia scope."
    },
    csr_ro_axi_lite: {
      file: "rtl/common/csr_ro_axi_lite.sv",
      svg: "./svg/csr_ro_axi_lite.svg",
      subtitle: "AXI4-Lite CSR",
      desc: "Dekoder rejestrow i most miedzy MicroBlaze (AXI) a sygnalami sterujacymi/pomiarowymi RO."
    },
    ro_multi_div_mux: {
      file: "rtl/common/ro_multi_div_mux.sv",
      svg: "./svg/ro_multi_div_mux.svg",
      subtitle: "bank + divider router",
      desc: "Buforuje banki (BUFG), mapuje TARGET->bank/div oraz generuje wyjscie po dzielniku i tapy do scope/pomiaru."
    },
    ro_target_map: {
      file: "rtl/common/ro_target_map.sv",
      svg: "./svg/ro_target_map.svg",
      subtitle: "TARGET->bank/div",
      desc: "Wyznacza bank_auto, half_edges i predykcje f_pred_khz na podstawie target_khz (z trybem manualnym)."
    },
    ro_ring_bank_buf: {
      file: "rtl/common/ro_ring_bank_buf.sv",
      svg: "./svg/ro_ring_bank_buf.svg",
      subtitle: "BUFG x16",
      desc: "BUFG na kazdym wyjsciu banku pierscienia przed multipleksacja."
    },
    ring_prog_toggle_div: {
      file: "rtl/common/ring_prog_toggle_div.sv",
      svg: "./svg/ring_prog_toggle_div.svg",
      subtitle: "programmable divider",
      desc: "Programowalny dzielnik przez zliczanie zboczy (half_edges), z opcja bypass."
    },
    ro_sig_buf: {
      file: "rtl/common/ro_sig_buf.sv",
      svg: "./svg/ro_sig_buf.svg",
      subtitle: "BUFG output",
      desc: "Bufor BUFG na sygnale po dzielniku (czyste wyjscie do pomiaru i scope)."
    },
    ro_bank_prescale_mux: {
      file: "rtl/common/ro_bank_prescale_mux.sv",
      svg: "./svg/ro_bank_prescale_mux.svg",
      subtitle: "prescaler mux",
      desc: "Dobiera preskaler zaleznie od banku, zeby umozliwic pomiar szybkich ringow w oknie GATE @ 12 MHz."
    },
    ro_ring_prescale: {
      file: "rtl/common/ro_ring_prescale.sv",
      svg: "./svg/ro_ring_prescale.svg",
      subtitle: "async prescaler",
      desc: "Asynchroniczny preskaler (toggle chain) uzywany w torze pomiaru i dla wolnych bankow lancuchowych."
    },
    ro_freq_measure: {
      file: "rtl/common/ro_freq_measure.sv",
      svg: "./svg/ro_freq_measure.svg",
      subtitle: "gate counter",
      desc: "Pomiar f w oknie GATE: synchronizacja sygnalu async, zliczanie zboczy i obliczenie freq_hz."
    },
    ro_freq_hz_calc: {
      file: "rtl/common/ro_freq_hz_calc.sv",
      svg: "./svg/ro_freq_hz_calc.svg",
      subtitle: "Hz math",
      desc: "Oblicza freq_hz = edges * F_REF / gate_cycles."
    },
    ro_top: {
      file: "rtl/common/ro_top.sv",
      svg: "./svg/ro_top.svg",
      subtitle: "16 bankow RO",
      desc: "Generator 16 bankow: tunable (ring_inverter_tunable) oraz chain (ring_inverter_chain + /64)."
    },
    ring_inverter_tunable: {
      file: "rtl/common/ring_inverter_tunable.sv",
      svg: "./svg/ring_inverter_tunable.svg",
      subtitle: "tunable ring",
      desc: "Pierscien LUT z muxami strojenia (tune_sel) i parametrycznym ogonem inwerterow."
    },
    ring_inverter_chain: {
      file: "rtl/common/ring_inverter_chain.sv",
      svg: "./svg/ring_inverter_chain.svg",
      subtitle: "fixed chain ring",
      desc: "Dlugi lancuch LUT-inwerterow o stalej liczbie etapow (401..801), dla wolnych bankow."
    },
    arty_scope_freq_mux: {
      file: "rtl/common/arty_scope_freq_mux.sv",
      svg: "./svg/arty_scope_freq_mux.svg",
      subtitle: "scope mux",
      desc: "MMCM x50 + resync do pinu scope (ro_scope / ro_scope_ring)."
    }
  },

  // Hierarchia RTL (rodzic -> bezposrednie dzieci)
  hierarchy: {
    ro_top_arty_axi: [
      "csr_ro_axi_lite",
      "ro_multi_div_mux",
      "ro_sig_buf",
      "ro_bank_prescale_mux",
      "ro_top",
      "ro_freq_measure",
      "arty_scope_freq_mux"
    ],
    ro_multi_div_mux: ["ro_ring_bank_buf", "ro_target_map", "ring_prog_toggle_div"],
    ro_freq_measure: ["ro_freq_hz_calc"],
    ro_top: ["ring_inverter_tunable", "ring_inverter_chain", "ro_ring_prescale"]
  },

  // Etykiety instancji z Vivado schematic -> id bloku
  instanceMap: {
    u_csr: "csr_ro_axi_lite",
    u_div_mux: "ro_multi_div_mux",
    u_out_buf: "ro_sig_buf",
    u_ring_ps: "ro_bank_prescale_mux",
    u_core: "ro_top",
    u_meas_ring: "ro_freq_measure",
    u_meas_out: "ro_freq_measure",
    u_scope: "arty_scope_freq_mux",
    u_scope_ring: "arty_scope_freq_mux",
    u_ring_buf: "ro_ring_bank_buf",
    u_map: "ro_target_map",
    u_div: "ring_prog_toggle_div",
    u_hz: "ro_freq_hz_calc",
    u_ring_slow: "ring_inverter_chain",
    u_chain_out_div: "ro_ring_prescale",
    u_ring: "ring_inverter_tunable"
  }
};
