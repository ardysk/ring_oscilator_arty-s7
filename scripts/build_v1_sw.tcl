# Build ro_ring_app (V1 UART) in sdk_workspace
set proj_dir [file normalize [file dirname [info script]]/..]
set ws [file join $proj_dir sdk_workspace]

if {![file isdirectory $ws]} {
  error "Brak sdk_workspace: $ws"
}

setws $ws
if {[catch {projects -build -type app -name ro_ring_app} err]} {
  puts "ERROR build: $err"
  exit 1
}
puts "OK: sdk_workspace/ro_ring_app/Debug/ro_ring_app.elf"
