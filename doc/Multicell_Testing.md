# Multi-cell Testing with RFsimulator

This document describes how to configure and run a multi-cell gNB using the RFsimulator.
The setup runs one monolithic `nr-softmodem` instance serving two cells, but only one
cell can be active on the air at a time; switching cells requires a code change and
recompile (see [Current limitation](#current-limitation--one-cell-broadcasts-at-a-time)).

## Configuration

The sample config is at:

```
targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.106prb.rfsim.2cells.yaml
```

### Config file structure

> **Note — this structure is provisional.** Two reworks are planned before the
> multi-cell config format is considered stable (see comments in the config file):
>
> 1. **`gNBs[]` vs `cells[]`:** The current approach nests cells under a single
>    `gNBs[]` entry via a `cells[]` sub-list. The planned rework is to instead
>    express each cell as a separate `gNBs[]` entry (keeping the same `gNB_ID` and
>    `gNB_name`), with transport/AMF parameters only in the first entry. This avoids
>    introducing a new config key and preserves backwards compatibility with existing
>    single-cell config files.
>
> 2. **Scheduler parameters:** Per-cell scheduler knobs (`pusch_TargetSNRx10`,
>    `pucch_TargetSNRx10`, etc.) currently live under `cells[]`. The planned rework
>    is to keep them in `MACRLCs[]` by adding one `MACRLCs` entry per cell, with the
>    parser enforcing that the count matches the number of configured cells.

Per-cell parameters live under `gNBs[n].cells[c]` instead of at the `gNBs` level.
Each entry in the `cells` list defines one independent carrier:

```yaml
gNBs:
  - gNB_ID: 0xe00
    gNB_name: gnb-rfsim
    cells:
      - tracking_area_code: 1       # Cell 0
        nr_cellid: 12345678
        plmn_list: [...]
        servingCellConfigCommon:
          - physCellId: 0
            absoluteFrequencySSB: 630048   # 3450.72 MHz
            dl_absoluteFrequencyPointA: 628776
            ...

      - tracking_area_code: 1       # Cell 1
        nr_cellid: 11111111
        plmn_list: [...]
        servingCellConfigCommon:
          - physCellId: 1
            absoluteFrequencySSB: 643296   # 3649.44 MHz
            dl_absoluteFrequencyPointA: 642024
            ...
```

Fields that are per-gNB (transport, AMF address, SCTP) remain at the `gNBs` level and
are not repeated per cell.

### Cell summary

|             | Cell 0 | Cell 1 |
|-------------|---|---|
| PCI         | 0 | 1 |
| NR Cell ID  | 12345678 | 11111111 |
| SSB ARFCN   | 630048 | 643296 |
| SSB frequency | 3450.72 MHz | 3649.44 MHz |
| Point A     | 3432 MHz (ARFCN 628776) | 3630 MHz (ARFCN 642024) |
| Bandwidth   | 106 PRBs, 30 kHz SCS | 106 PRBs, 30 kHz SCS |
| Band        | n78 | n78 |

## Current limitation — one cell broadcasts at a time

With the current implementation, only one cell can drive the PHY (i.e. have its carrier frequency and bandwidth applied to the RFsimulator) at a time. The active cell is selected by a hardcoded guard in `openair2/LAYER2/NR_MAC_gNB/config.c` around line 971:

```c
if (NFAPI_MODE == NFAPI_MONOLITHIC && cell == &nrmac->cells[1]) {
```

Change the index (`cells[0]` for cell 0, `cells[1]` for cell 1) to select which cell
the L1 transmits on, then recompile:

```bash
#from cmake_targets
./build_oai -w USRP --ninja --gNB --nrUE -c -C
# alternatively from cmake_targets/ran_build/build/ if a previous build was already done
ninja nr-softmodem
```

Only start the UE that matches the active cell's frequency; the other cell's MAC
scheduling runs but its carrier is not visible on the air.

## Running

All commands are run from the build directory. Open three terminals.

### Terminal 1 — gNB (both cells)

```bash
cd <build_dir> && sudo ./nr-softmodem \
  -O /home/user/develop/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.106prb.rfsim.2cells.yaml \
  --rfsim
```

### Terminal 2 — UE on Cell 1 (3649.44 MHz)

```bash
cd <build_dir> && sudo LD_LIBRARY_PATH=.  ./nr-uesoftmodem \
 -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/ue.conf --uicc0.imsi 001010000000001 \
  --rfsim -C 3649440000 -r 106 --numerology 1 --ssb 516
```

### Terminal 3 — UE on Cell 0 (3450.72 MHz)

```bash
cd <build_dir> && sudo LD_LIBRARY_PATH=.  ./nr-uesoftmodem \
-O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/ue.conf --uicc0.imsi 001010000000001 \
--rfsim -C 3450720000 -r 106 --numerology 1 --ssb 516
```

## Adding a third cell

1. Add a new entry under `cells` in the YAML with a distinct `physCellId`, `nr_cellid`,
   and `absoluteFrequencySSB`/`dl_absoluteFrequencyPointA` pair.
2. Edit `openair2/LAYER2/NR_MAC_gNB/config.c` around line 971:
    ```c
    if (NFAPI_MODE == NFAPI_MONOLITHIC && cell == &nrmac->cells[2]) {
    ```
3. Start the `nr-softmodem`
   The gNB will then display the correct parameters to pass to the OAI UE:
   ```
   [PHY]    Cell <cell_idx> command line parameters for OAI UE: -C <center frequency> -r <bandwidth> --numerology <mu> --ssb <ssb_offset>
   ```
4. Start the `nr-uesoftmodem` instance with the appropriate parameters displayed by nr-softmodem

`NR_MAX_CELLS` in `openair2/LAYER2/NR_MAC_gNB/nr_mac_gNB.h` sets the compile-time
upper bound on cells per MAC instance (currently 4).
