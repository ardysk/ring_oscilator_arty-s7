/* Hierarchia bloków V1 — źródło diagramów dla docs/blocks/index.html */
window.BLOCKS = {
  system: {
    title: "mb_ro_system",
    subtitle: "Vivado Block Design — top FPGA",
    file: "ring_oscilator_prj.srcs/sources_1/bd/mb_ro_system/mb_ro_system.bd",
    description:
      "Główny układ Vivado IP Integrator na płytce Digilent Arty S7-50 (XC7S50). " +
      "Łączy procesor MicroBlaze, pamięć, UART, debug JTAG i customowy IP pierścieni RO (ro_axi_0). " +
      "Całość pracuje w jednej domenie zegara 12 MHz.",
    ports: {
      in: ["clk_12mhz", "btn[3:0]", "sw[3:0]", "uart_usb_rxd"],
      out: ["led[3:0]", "ro_scope", "ro_scope_ring", "uart_usb_txd"]
    },
    diagram: `flowchart TB
      CLK["clk_12mhz<br/>12 MHz"]
      MB["microblaze_0<br/>CPU + LMB BRAM"]
      MDM["mdm_1<br/>JTAG debug"]
      XBAR["microblaze_0_axi_periph<br/>AXI crossbar"]
      UART["axi_uartlite_0<br/>USB-UART 9600"]
      RO["ro_axi_0<br/>ro_top_arty_axi"]
      HOST["PC terminal"]
      BOARD["Przyciski / SW / LED / JA scope"]
      CLK --> MB
      CLK --> XBAR
      CLK --> UART
      CLK --> RO
      MB --> XBAR
      MB --- MDM
      XBAR --> RO
      XBAR --> UART
      HOST <--> UART
      RO --> BOARD
      MB -.->|"firmware V1"| RO`,
    children: ["microblaze", "axi_periph", "uart", "ro_axi"],
    registers: null
  },

  microblaze: {
    title: "microblaze_0",
    subtitle: "Soft-processor + pamięć lokalna",
    file: "IP Vivado: microblaze_0, dlmb/ilmb, lmb_bram",
    description:
      "Rdzeń MicroBlaze wykonuje firmware z katalogu sw/v1_uart (komendy CAL, SET, MEAS, BANK). " +
      "Program i dane w lokalnej pamięci LMB BRAM (64 KB). Dostęp do RO i UART przez magistralę AXI.",
    ports: {
      in: ["Clk 12 MHz", "Reset", "M_AXI_DP od CPU"],
      out: ["Instrukcje/dane do BRAM", "Transakcje AXI do xbar"]
    },
    diagram: `flowchart LR
      CPU["microblaze_0<br/>rdzeń RISC"]
      ILMB["ilmb_v10"]
      DLMB["dlmb_v10"]
      IBRAM["lmb_bram<br/>kod + dane"]
      CPU --> ILMB --> IBRAM
      CPU --> DLMB --> IBRAM
      CPU --> AXI["M_AXI_DP<br/>peripherals"]`,
    children: [],
    registers: null
  },

  axi_periph: {
    title: "microblaze_0_axi_periph",
    subtitle: "AXI4 crossbar",
    file: "IP Vivado: axi_crossbar w BD",
    description:
      "Rozdziela transakcje AXI z MicroBlaze na slave'y: M00 → rejestry RO (ro_axi_0), M01 → UART.",
    ports: {
      in: ["S00_AXI od MicroBlaze"],
      out: ["M00_AXI → ro_axi_0", "M01_AXI → axi_uartlite_0"]
    },
    diagram: `flowchart LR
      S00["S00<br/>MicroBlaze"]
      XBAR["xbar"]
      M00["M00 → ro_axi_0<br/>0x44A00000"]
      M01["M01 → uart<br/>0x40600000"]
      S00 --> XBAR
      XBAR --> M00
      XBAR --> M01`,
    children: [],
    registers: null
  },

  uart: {
    title: "axi_uartlite_0",
    subtitle: "Most UART do USB na Arty S7",
    file: "IP Vivado AXI UART Lite",
    description:
      "Konwerter AXI4-Lite ↔ UART. Firmware i użytkownik komunikują się przez terminal (typ. COM13, 9600 8N1).",
    ports: {
      in: ["S_AXI", "uart_usb_rxd"],
      out: ["uart_usb_txd", "przerwania RX/TX"]
    },
    diagram: `flowchart LR
      AXI["S_AXI<br/>rejestry TX/RX"]
      CORE["UART Lite core"]
      USB["USB-UART<br/>na płytce"]
      PC["Terminal PC"]
      AXI --> CORE <--> USB <--> PC`,
    children: [],
    registers: null
  },

  ro_axi: {
    title: "ro_axi_0",
    subtitle: "Wrapper BD → ro_top_arty_axi",
    file: "rtl/common/ro_top_arty_axi_bd_wrap.v",
    description:
      "Otoczka module_ref dla Vivado BD. Eksponuje interfejs AXI4-Lite i piny Arty (btn, sw, led, scope).",
    ports: {
      in: ["s_axi_*", "clk_12mhz", "btn", "sw"],
      out: ["led", "ro_scope", "ro_scope_ring", "s_axi_rdata"]
    },
    diagram: `flowchart TB
      AXI["S_AXI slave"]
      WRAP["ro_top_arty_axi_bd_wrap"]
      CORE["ro_top_arty_axi<br/>logika RO V1"]
      PIN["btn / sw / led / scope"]
      AXI --> WRAP --> CORE
      PIN <--> CORE`,
    children: ["ro_top_arty_axi"],
    registers: null
  },

  ro_top_arty_axi: {
    title: "ro_top_arty_axi",
    subtitle: "Top logiki programowalnej V1",
    file: "rtl/common/ro_top_arty_axi.sv",
    description:
      "Serce projektu w PL: 16 banków pierścieni, rejestry CSR, multipleksery, dzielniki, podwójny pomiar częstotliwości " +
      "i wyjścia scope. Firmware przez AXI ustawia strojenie, bank, dzielnik i odczytuje wyniki pomiaru.",
    ports: {
      in: ["clk_12mhz", "s_axi_*", "btn[3]", "sw[3:0]"],
      out: ["led[3:0]", "ro_scope", "ro_scope_ring", "mon_* status"]
    },
    diagram: `flowchart TB
      CSR["csr_ro_axi_lite<br/>rejestry AXI"]
      TUNE["ro_bank_tune_pack<br/>domyślne tune"]
      CORE["ro_top<br/>16 banków RO"]
      MUX["ro_multi_div_mux<br/>bank + dzielnik"]
      BUF["ro_sig_buf<br/>BUFG wyjścia"]
      PS["ro_bank_prescale_mux<br/>preskaler pomiaru"]
      MR["ro_freq_measure<br/>pierścień"]
      MO["ro_freq_measure<br/>wyjście /DIV"]
      SC["arty_scope_freq_mux<br/>scope OUT"]
      SR["arty_scope_freq_mux<br/>scope RING"]
      SW["SW0 gate ro_en"]
      CSR --> CORE
      CSR --> MUX
      TUNE --> CORE
      SW --> CORE
      CORE -->|"ring_out_bank_bus[15:0]"| MUX
      MUX --> BUF
      MUX --> PS
      MUX --> SR
      BUF --> MO
      BUF --> SC
      PS --> MR
      MR --> CSR
      MO --> CSR
      MUX --> CSR`,
    children: [
      "csr",
      "tune_pack",
      "ro_top",
      "multi_div_mux",
      "sig_buf",
      "prescale_mux",
      "freq_measure",
      "scope_mux"
    ],
    registers: null
  },

  csr: {
    title: "csr_ro_axi_lite",
    subtitle: "Rejestry sterowania RO (AXI4-Lite)",
    file: "rtl/common/csr_ro_axi_lite.sv",
    description:
      "Mapuje transakcje AXI na sygnały sterujące: RO_EN, TUNE, TARGET kHz, BANK, HALF_EDGES, GATE, impuls pomiaru. " +
      "Odczytuje STATUS, FREQ_HZ, FREQ_RING, EDGES, PRED_KHZ, PLL locked.",
    ports: {
      in: ["s_axi_*", "meas_done/busy", "freq_hz ring/out", "bank_auto", "pll_locked"],
      out: ["csr_ro_en", "csr_tune_bits", "csr_target_khz", "csr_ro_bank_sel", "csr_meas_arm", "meas_gate_cycles"]
    },
    diagram: `flowchart LR
      AXI["AXI4-Lite<br/>MicroBlaze"]
      DEC["Dekoder adresów<br/>0x00…0x3C"]
      REG["Rejestry CSR"]
      PL["Sterowanie PL"]
      STA["Status z pomiaru"]
      AXI <--> DEC <--> REG
      REG --> PL
      STA --> REG`,
    children: [],
    registers: [
      "0x00 CTRL — ro_en, start pomiaru",
      "0x08 TUNE — 12-bit strojenie aktywnego banku",
      "0x0C GATE — okno pomiaru (domyślnie 60000 cykli)",
      "0x1C BANK — wybór banku HW 0…15",
      "0x20 FREQ_HZ — zmierzone f na wyjściu",
      "0x24 TARGET — docelowe f [kHz] dla SET",
      "0x28 FREQ_RING — zmierzone f pierścienia",
      "0x34 HALF_EDGES — dzielnik programowalny"
    ]
  },

  tune_pack: {
    title: "ro_bank_tune_pack",
    subtitle: "LUT domyślnych słów tune",
    file: "rtl/common/ro_bank_tune_pack.sv",
    description:
      "Tylko do odczytu — pakiet 16×12-bitowych wartości tune wygenerowanych przez scripts/gen_ro_presets.py. " +
      "Nieaktywne banki dostają tune z LUT; aktywny bank może być nadpisany z rejestru TUNE.",
    ports: {
      in: ["bank index implicit"],
      out: ["ro_tune_base[16×12]"]
    },
    diagram: `flowchart LR
      LUT["LUT[0..15]<br/>12-bit tune"]
      MUX["Mux per-bank<br/>w ro_top_arty_axi"]
      CSR["CSR TUNE<br/>aktywny bank"]
      CORE["ro_top<br/>ro_tune_bus"]
      LUT --> MUX
      CSR --> MUX --> CORE`,
    children: [],
    registers: null
  },

  ro_top: {
    title: "ro_top",
    subtitle: "16 równoległych banków pierścieni",
    file: "rtl/common/ro_top.sv",
    description:
      "Generate 16 instancji: banki 0–5,7–11 używają ring_inverter_tunable (różna długość ogona LUT), " +
      "banki 6,12–15 — długi łańcuch ring_inverter_chain + preskaler ÷64. Wyjścia na szynę ring_out_bank_bus.",
    ports: {
      in: ["clk", "rst_n", "ro_en", "ro_tune_sel[16×12]", "ro_bank_sel"],
      out: ["ring_out_bank_bus[15:0]"]
    },
    diagram: `flowchart TB
      EN["ro_en"]
      subgraph FAST["Banki tunable 0–5, 7–11"]
        T0["ring_inverter_tunable"]
        T1["… ×11"]
      end
      subgraph SLOW["Banki łańcuchowe 6, 12–15"]
        C0["ring_inverter_chain<br/>401…801 inv"]
        D0["ro_ring_prescale /64"]
        C0 --> D0
      end
      BUS["ring_out_bank_bus[15:0]"]
      EN --> FAST
      EN --> SLOW
      FAST --> BUS
      SLOW --> BUS`,
    children: ["ring_tunable", "ring_chain", "ring_prescale"],
    registers: null
  },

  ring_tunable: {
    title: "ring_inverter_tunable",
    subtitle: "Pierścień LUT ze strojeniem MUX",
    file: "rtl/common/ring_inverter_tunable.sv",
    description:
      "Pętla inwerterów LUT: sygnał krąży inv→inv→…→z powrotem. Każdy bit tune_sel wybiera krótszą lub dłuższą ścieżkę (para inv), " +
      "zmieniając opóźnienie pętli i częstotliwość. Para inwerterów na końcu (tail) stabilizuje oscylację.",
    ports: {
      in: ["en", "tune_sel[11:0]"],
      out: ["ro_out"]
    },
    diagram: `flowchart TB
      FB["feedback fb"]
      MID["mid = ~(fb & en)"]
      subgraph TUNE["12× MUX strojenia"]
        direction LR
        N0["inv"] --> M0["MUX<br/>tune_sel[i]"]
        M0 --> N1["inv / bypass"]
      end
      TAIL["tail: para inv<br/>parzysta liczba"]
      OUT["ro_out"]
      FB --> MID --> TUNE --> TAIL --> OUT
      OUT --> FB`,
    children: [],
    registers: null
  },

  ring_chain: {
    title: "ring_inverter_chain",
    subtitle: "Długi łańcuch inwerterów LUT",
    file: "rtl/common/ring_inverter_chain.sv",
    description:
      "Stała liczba inwerterów LUT (401, 501, 601 lub 801) zamknięta w pętlę — wolniejsze banki B12–B16 i B6. " +
      "Brak strojenia MUX; częstotliwość wynika wyłącznie z długości łańcucha.",
    ports: {
      in: ["en"],
      out: ["ro_out"]
    },
    diagram: `flowchart LR
      EN["en"]
      I1["LUT inv"] --> I2["inv"] --> I3["inv"] --> DOTS["… N etapów …"] --> IN["inv"] --> I1
      EN -.-> I1
      IN --> OUT["ro_out"]`,
    children: [],
    registers: null
  },

  ring_prescale: {
    title: "ro_ring_prescale",
    subtitle: "Asynchroniczny preskaler ÷2^(n+1)",
    file: "rtl/common/ro_ring_prescale.sv",
    description:
      "Dzieli sygnał pierścienia przed pomiarem lub na wyjściu banku łańcuchowego. " +
      "W ro_top: ÷64 (DIV_BITS=5) na bankach chain. W prescale_mux: ÷8, ÷32, ÷128 lub ÷512 zależnie od banku.",
    ports: {
      in: ["ro_in", "rst_n"],
      out: ["ro_div"]
    },
    diagram: `flowchart LR
      IN["ro_in<br/>async"]
      T0["toggle ÷2"]
      T1["toggle ÷2"]
      TN["… DIV_BITS"]
      OUT["ro_div"]
      IN --> T0 --> T1 --> TN --> OUT`,
    children: [],
    registers: null
  },

  multi_div_mux: {
    title: "ro_multi_div_mux",
    subtitle: "Bufor banków + mapowanie + dzielnik",
    file: "rtl/common/ro_multi_div_mux.sv",
    description:
      "Centralny router sygnału: BUFG na każdy bank, automatyczny wybór banku i dzielnika z TARGET kHz (ro_target_map), " +
      "programowalny dzielnik zboczy (ring_prog_toggle_div), wyjścia na scope i pomiar.",
    ports: {
      in: ["ring_bank_raw[15:0]", "target_khz", "bank_sel", "csr_half_edges"],
      out: ["div_mux_out", "ring_scope_sig", "ring_meas_sig", "f_pred_khz", "bank_auto"]
    },
    diagram: `flowchart TB
      RAW["ring_bank_raw[15:0]"]
      BUF["ro_ring_bank_buf<br/>BUFG ×16"]
      MAP["ro_target_map<br/>TARGET → bank + div"]
      SEL["MUX banku"]
      DIV["ring_prog_toggle_div<br/>dzielnik zboczy"]
      SCOPE["ring_scope_sig"]
      MEAS["ring_meas_sig"]
      OUT["div_mux_out"]
      RAW --> BUF --> SEL
      MAP --> SEL
      SEL --> DIV
      DIV --> OUT
      SEL --> SCOPE
      SEL --> MEAS`,
    children: ["ring_bank_buf", "target_map", "prog_toggle_div"],
    registers: null
  },

  ring_bank_buf: {
    title: "ro_ring_bank_buf",
    subtitle: "BUFG na każdy bank",
    file: "rtl/common/ro_ring_bank_buf.sv",
    description: "Globalny bufor zegarowy Xilinx BUFG na każdym z 16 wyjść pierścienia przed multipleksacją.",
    ports: {
      in: ["ring_in[15:0]"],
      out: ["ring_buf[15:0]"]
    },
    diagram: `flowchart LR
      R0["ring_in[0]"] --> B0["BUFG"]
      R1["ring_in[1]"] --> B1["BUFG"]
      RD["…"] --> BD["…"]
      R15["ring_in[15]"] --> B15["BUFG"]
      B0 --> OUT["ring_buf[15:0]"]`,
    children: [],
    registers: null
  },

  target_map: {
    title: "ro_target_map",
    subtitle: "TARGET kHz → bank + half_edges",
    file: "rtl/common/ro_target_map.sv",
    description:
      "Na podstawie docelowej częstotliwości (kHz) z CSR wybiera bank HW i współczynnik dzielnika (half_edges). " +
      "Firmware po CAL używa tabeli charakterystyk; tryb manualny pomija auto-mapowanie.",
    ports: {
      in: ["target_khz", "bank_manual", "bank_override"],
      out: ["bank_auto", "half_edges", "div_bypass", "f_pred_khz"]
    },
    diagram: `flowchart TB
      TGT["target_khz<br/>z SET"]
      TBL["Logika mapowania<br/>bank + dzielnik"]
      MAN["bank_manual /<br/>bank_override"]
      BA["bank_auto"]
      HE["half_edges"]
      FK["f_pred_khz"]
      TGT --> TBL
      MAN --> TBL
      TBL --> BA
      TBL --> HE
      TBL --> FK`,
    children: [],
    registers: null
  },

  prog_toggle_div: {
    title: "ring_prog_toggle_div",
    subtitle: "Programowalny dzielnik zboczy",
    file: "rtl/common/ring_prog_toggle_div.sv",
    description:
      "Liczy zbocza wybranego pierścienia i generuje wyjście z podzieloną częstotliwością. " +
      "half_edges określa ile zboczy narastających na półokres — minimum efektywne ÷2 na wyjściu.",
    ports: {
      in: ["ro_clk", "half_edges", "div_bypass", "rst_n"],
      out: ["div_out"]
    },
    diagram: `flowchart LR
      CLK["ro_clk<br/>z MUX banku"]
      CNT["Licznik zboczy<br/>half_edges"]
      TGL["Przerzutnik<br/>wyjście ÷2n"]
      OUT["div_out"]
      CLK --> CNT --> TGL --> OUT`,
    children: [],
    registers: null
  },

  sig_buf: {
    title: "ro_sig_buf",
    subtitle: "BUFG na wyjściu po dzielniku",
    file: "rtl/common/ro_sig_buf.sv",
    description: "Bufor globalny na sygnale po dzielniku — czyste wyjście do pomiaru OUT i scope.",
    ports: {
      in: ["div_mux_raw"],
      out: ["out_buf_sig"]
    },
    diagram: `flowchart LR
      IN["div_mux_raw"] --> BUFG["BUFG"] --> OUT["out_buf_sig"]`,
    children: [],
    registers: null
  },

  prescale_mux: {
    title: "ro_bank_prescale_mux",
    subtitle: "Preskaler zależny od banku",
    file: "rtl/common/ro_bank_prescale_mux.sv",
    description:
      "Wybiera jeden z czterech preskalerów (÷8, ÷32, ÷128, ÷512) zależnie od aktywnego banku, " +
      "aby zmierzyć bardzo szybkie pierścienie w oknie GATE @ 12 MHz bez przepełnienia licznika.",
    ports: {
      in: ["ring_meas_raw", "ro_bank_eff"],
      out: ["ring_meas_prescaled", "ring_meas_scale"]
    },
    diagram: `flowchart TB
      IN["ring_meas_raw"]
      PS3["prescale ÷8<br/>DIV_BITS=3"]
      PS5["prescale ÷32"]
      PS7["prescale ÷128"]
      PS9["prescale ÷512"]
      MUX["MUX wg banku"]
      OUT["ring_meas_prescaled"]
      SCL["ring_meas_scale<br/>mnożnik w firmware"]
      IN --> PS3 & PS5 & PS7 & PS9 --> MUX --> OUT
      MUX --> SCL`,
    children: ["ring_prescale"],
    registers: null
  },

  freq_measure: {
    title: "ro_freq_measure",
    subtitle: "Pomiar częstotliwości w oknie GATE",
    file: "rtl/common/ro_freq_measure.sv",
    description:
      "W domenie 12 MHz: synchronizuje async ro_async, otwiera okno GATE cykli, liczy zbocza, " +
      "po zamknięciu oblicza freq_hz. W V1 są dwa egzemplarze: na pierścieniu (po preskalerze) i na wyjściu po dzielniku.",
    ports: {
      in: ["clk 12 MHz", "ro_async", "meas_start", "meas_gate_cycles"],
      out: ["meas_busy", "meas_done", "meas_edge_count", "meas_freq_hz"]
    },
    diagram: `flowchart TB
      ASYNC["ro_async"]
      SYNC["Synchronizator<br/>do clk 12M"]
      GATE["Okno GATE<br/>N cykli"]
      EDGE["Detekcja zboczy"]
      CNT["edge_count"]
      HZ["ro_freq_hz_calc<br/>f = edges×Fref/GATE"]
      ASYNC --> SYNC --> EDGE
      GATE --> CNT
      EDGE --> CNT --> HZ`,
    children: ["freq_hz_calc"],
    registers: null
  },

  freq_hz_calc: {
    title: "ro_freq_hz_calc",
    subtitle: "Przelicznik Hz z liczby zboczy",
    file: "rtl/common/ro_freq_hz_calc.sv",
    description: "freq_hz = edge_count × F_REF_HZ / gate_cycles (F_REF = 12 MHz).",
    ports: {
      in: ["edge_count", "gate_cycles", "F_REF_HZ"],
      out: ["freq_hz"]
    },
    diagram: `flowchart LR
      EC["edge_count"] --> MUL["× F_REF_HZ"]
      GC["gate_cycles"] --> DIV["÷"]
      MUL --> DIV --> HZ["freq_hz"]`,
    children: [],
    registers: null
  },

  scope_mux: {
    title: "arty_scope_freq_mux",
    subtitle: "MMCM ×50 + bufor na pin scope",
    file: "rtl/common/arty_scope_freq_mux.sv",
    description:
      "Dla szybkich sygnałów RO: MMCME2 generuje ~600 MHz z 12 MHz, resynchronizuje async ring do czystego wyjścia na nagłówek JA. " +
      "Dwa egzemplarze: ro_scope (po dzielniku) i ro_scope_ring (surowy pierścień).",
    ports: {
      in: ["clk_12mhz", "raw_ring_sig"],
      out: ["ro_scope", "pll_locked"]
    },
    diagram: `flowchart TB
      CLK12["clk 12 MHz"]
      MMCM["MMCME2_BASE<br/>×50 → ~600 MHz"]
      BUFG["BUFG"]
      RESYNC["Próbkowanie /<br/>resync async ring"]
      PIN["ro_scope → JA"]
      CLK12 --> MMCM --> BUFG --> RESYNC
      RING["raw_ring_sig"] --> RESYNC --> PIN`,
    children: [],
    registers: null
  }
};

/* Klikalne węzły w diagramach Mermaid → id bloku */
window.BLOCK_CLICKS = {
  ro_top_arty_axi: {
    csr: "csr",
    tune_pack: "tune_pack",
    core: "ro_top",
    mux: "multi_div_mux",
    buf: "sig_buf",
    ps: "prescale_mux",
    mr: "freq_measure",
    mo: "freq_measure",
    sc: "scope_mux",
    sr: "scope_mux"
  },
  system: {
    mb: "microblaze",
    xbar: "axi_periph",
    uart: "uart",
    ro: "ro_axi"
  },
  ro_axi: {
    core: "ro_top_arty_axi"
  },
  ro_top: {
    t0: "ring_tunable",
    t1: "ring_tunable",
    c0: "ring_chain",
    d0: "ring_prescale"
  },
  multi_div_mux: {
    buf: "ring_bank_buf",
    map: "target_map",
    div: "prog_toggle_div"
  },
  prescale_mux: {
    ps3: "ring_prescale",
    ps5: "ring_prescale",
    ps7: "ring_prescale",
    ps9: "ring_prescale"
  },
  freq_measure: {
    hz: "freq_hz_calc"
  }
};
