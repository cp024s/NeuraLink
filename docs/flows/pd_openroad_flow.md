# Physical Design Flow (OpenROAD + OpenRPDK28 Research Track)

NeuraLink is structured for an RTL-to-GDSII-compatible flow using open-source tools in research mode.

## Flow Entry

- Script: `scripts/pd/openroad_flow.sh`
- OpenROAD script: `scripts/pd/openroad_flow.tcl`
- RTL manifest: `scripts/pd/rtl_files.txt`

## Research Node Target

- Intended research node: OpenRPDK28-compatible collateral
- Node-agnostic architecture policy:
  - Keep algorithm/control logic free of node-specific assumptions
  - Inject node-specific data through LEF/Liberty and constraints only

## Two Run Modes

1. Placeholder checks mode
- No LEF/Liberty supplied
- Runs link + area/timing placeholder reports

2. Full implementation mode
- Set:
  - `TECH_LEF`
  - `STDCELL_LEF`
  - `STDCELL_LIB`
- Runs floorplan, placement, routing, timing reports, and DEF/ODB export

## Command

- `bash scripts/pd/openroad_flow.sh`

## Deliverables Produced

- Synth netlist: `<build>/pd/<top>_synth.v`
- Reports: `<build>/pd/reports/*.rpt`
- DEF/ODB/netlist exports (in full mode)

## PD-Readiness Notes

- This flow is intentionally reproducible and CI-friendly.
- For tapeout-level signoff you still need:
  - full DRC/LVS decks
  - extraction-calibrated timing corners
  - IR/EM closure
  - test insertion and signoff-quality constraints
