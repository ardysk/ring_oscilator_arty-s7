# Historia commitow — wklej bloki po kolei w PowerShell
# (uruchom z katalogu repo, git config user.name/email ustaw wczesniej sam)

$repo = "C:\Users\HP\Downloads\csd_lab6\ring_oscilator_spartan7"
Set-Location $repo

# --- commit 1 ---
git add rtl/common/ring_inverter_tunable.sv rtl/common/ring_inverter_chain.sv rtl/common/ring_prog_toggle_div.sv rtl/common/ro_ring_prescale.sv rtl/common/ro_async_to_ref_sync.sv rtl/common/ro_freq_measure.sv rtl/common/ro_freq_hz_calc.sv rtl/common/ro_freq_measure_scaled.sv rtl/common/ro_freq_gate_100m.sv
git add ring_oscilator_prj.srcs/sources_1/new/ring_inverter_tunable.sv ring_oscilator_prj.srcs/sources_1/new/ring_inverter_chain.sv ring_oscilator_prj.srcs/sources_1/new/ring_prog_toggle_div.sv ring_oscilator_prj.srcs/sources_1/new/ro_ring_prescale.sv ring_oscilator_prj.srcs/sources_1/new/ro_async_to_ref_sync.sv ring_oscilator_prj.srcs/sources_1/new/ro_freq_measure.sv ring_oscilator_prj.srcs/sources_1/new/ro_freq_hz_calc.sv ring_oscilator_prj.srcs/sources_1/new/ro_freq_measure_scaled.sv ring_oscilator_prj.srcs/sources_1/new/ro_freq_gate_100m.sv
git commit -m "RTL pierscieni i pomiaru czestotliwosci"

# --- commit 2 ---
git add rtl/common/ro_top.sv rtl/common/csr_ro_axi_lite.sv rtl/common/ro_multi_div_mux.sv rtl/common/ro_target_map.sv rtl/common/ro_bank_prescale_mux.sv rtl/common/ro_bank_tune_pack.sv rtl/common/ro_div32.sv
git add ring_oscilator_prj.srcs/sources_1/new/ro_top.sv ring_oscilator_prj.srcs/sources_1/new/csr_ro_axi_lite.sv ring_oscilator_prj.srcs/sources_1/new/ro_multi_div_mux.sv ring_oscilator_prj.srcs/sources_1/new/ro_target_map.sv ring_oscilator_prj.srcs/sources_1/new/ro_bank_prescale_mux.sv ring_oscilator_prj.srcs/sources_1/new/ro_bank_tune_pack.sv ring_oscilator_prj.srcs/sources_1/new/ro_div32.sv
git add constraints/v1_uart/
git commit -m "Top 16 bankow, CSR AXI i dzielnik"

# --- commit 3 ---
git add rtl/common/ro_top_arty_axi.sv rtl/common/ro_top_arty.sv rtl/common/ro_top_arty_uart.sv rtl/common/ro_top_arty_axi_bd_wrap.v rtl/common/ro_top_zed.sv rtl/common/ro_sig_buf.sv rtl/common/ro_output_buffer.sv rtl/common/ro_ring_bank_buf.sv rtl/common/ro_bank_mux.sv
git add ring_oscilator_prj.srcs/sources_1/new/ro_top_arty_axi.sv ring_oscilator_prj.srcs/sources_1/new/ro_top_arty.sv ring_oscilator_prj.srcs/sources_1/new/ro_top_arty_uart.sv ring_oscilator_prj.srcs/sources_1/new/ro_top_arty_axi_bd_wrap.v ring_oscilator_prj.srcs/sources_1/new/ro_top_zed.sv ring_oscilator_prj.srcs/sources_1/new/ro_sig_buf.sv ring_oscilator_prj.srcs/sources_1/new/ro_output_buffer.sv ring_oscilator_prj.srcs/sources_1/new/ro_ring_bank_buf.sv ring_oscilator_prj.srcs/sources_1/new/ro_bank_mux.sv
git add rtl/common/uart_rx_8n1.sv rtl/common/tune_cmd_uart.sv rtl/common/btn_debouncer.sv rtl/common/clk_ref_100mhz.sv rtl/common/arty_tune_preset.sv rtl/common/arty_scope_freq_mux.sv rtl/common/ring_ro_edge_div.sv
git add ring_oscilator_prj.srcs/sources_1/new/uart_rx_8n1.sv ring_oscilator_prj.srcs/sources_1/new/tune_cmd_uart.sv ring_oscilator_prj.srcs/sources_1/new/btn_debouncer.sv ring_oscilator_prj.srcs/sources_1/new/clk_ref_100mhz.sv ring_oscilator_prj.srcs/sources_1/new/arty_tune_preset.sv ring_oscilator_prj.srcs/sources_1/new/arty_scope_freq_mux.sv ring_oscilator_prj.srcs/sources_1/new/ring_ro_edge_div.sv
git commit -m "Pozostaly RTL wspolny i wrappery Arty"

# --- commit 4 ---
git add rtl/v2_dds_btn/ rtl/v3_tft/ rtl/v2_uart_tft/ sim/ versions/ sw/v2_dds_btn/ sw/v3_tft/ software/
git add constraints/v2_dds_btn/ constraints/v2_uart_tft/ constraints/v3_tft/
git commit -m "Wersje V2 DDS i V3 TFT oraz symulacje"

# --- commit 5 ---
git add scripts/build_v1.tcl scripts/build_v1_sw.tcl scripts/build_v1_quick.tcl scripts/build_v1_impl_only.tcl scripts/gen_ro_presets.py scripts/gen_lut_mapping.tcl scripts/assign_pblocks_impl.tcl scripts/auto_tune.py scripts/create_mb_ro_axi_bd.tcl scripts/program_v1.tcl scripts/program_v2.tcl scripts/program_device.tcl
git add scripts/build_bitstream.ps1 scripts/flash_board.ps1
git add constraints/common/
git commit -m "Skrypty budowania, constraints i wgrywania"

# --- commit 6 ---
git add ring_oscilator_prj.xpr ring_oscilator_prj.srcs/sources_1/bd/ ring_oscilator_prj.srcs/constrs_1/ ring_oscilator_prj.srcs/sim_1/
git commit -m "Projekt Vivado i block design MicroBlaze"

# --- commit 7 ---
git add sw/v1_uart/ sdk_workspace/ro_ring_app/ firmware/
git commit -m "Firmware UART V1 i prebuilt ELF"

# --- commit 8 ---
git add README.md WGRANIE.md COMMITS.ps1 docs/
git commit -m "README i instrukcja uruchomienia"

# --- commit 9 ---
git add .gitignore bitstreams/
git commit -m "Gitignore, bitstream V1 i raport timing"

# --- opcjonalnie push ---
# git remote add origin https://github.com/ardysk/ring_oscilator_spartan7.git
# git branch -M master
# git push -u origin master

Write-Host "Historia commitow gotowa." -ForegroundColor Green
