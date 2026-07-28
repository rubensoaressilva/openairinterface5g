/*
 * SPDX-License-Identifier: LicenseRef-CSSL-1.0
 */

#include "NR_MAC_gNB/nr_mac_gNB.h"
#include "NR_MAC_gNB/mac_proto.h"

nr_cell_sched_t *nr_mac_get_cell_by_pci(gNB_MAC_INST *mac, uint16_t pci)
{
  for (int i = 0; i < NR_MAX_CELLS; i++) {
    nr_cell_sched_t *cell = &mac->cells[i];
    if (cell->common_channels.ServingCellConfigCommon == NULL)
      continue;
    if (cell->nr_pci == pci)
      return cell;
  }
  return NULL;
}

//TS 38.473 §9.3.1.12 NR CGI defined by PLMN Identity and NR Cell Identity
nr_cell_sched_t *nr_mac_get_cell_by_cgi(gNB_MAC_INST *mac, plmn_id_t plmn, uint64_t nr_cellid)
{
  for (int i = 0; i < NR_MAX_CELLS; i++) {
    nr_cell_sched_t *cell = &mac->cells[i];
    if (cell->common_channels.ServingCellConfigCommon == NULL)
      continue;
    if (cell->nr_cellid == nr_cellid && cell->plmn.mcc == plmn.mcc && cell->plmn.mnc == plmn.mnc
        && cell->plmn.mnc_digit_length == plmn.mnc_digit_length)
      return cell;
  }
  return NULL;
}

nr_cell_sched_t *nr_mac_get_first_active_cell(gNB_MAC_INST *mac)
{
  for (int i = 0; i < NR_MAX_CELLS; i++) {
    nr_cell_sched_t *cell = &mac->cells[i];
    if (cell->common_channels.ServingCellConfigCommon != NULL)
      return cell;
  }
  return NULL;
}
