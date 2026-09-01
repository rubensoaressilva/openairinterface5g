/*
 * SPDX-License-Identifier: LicenseRef-CSSL-1.0
 */

#ifndef __LAYER2_NR_MAC_CELL_H__
#define __LAYER2_NR_MAC_CELL_H__

#include <stdint.h>
#include "common/5g_platform_types.h"
#include "LAYER2/NR_MAC_gNB/nr_mac_gNB.h"

nr_cell_sched_t *nr_mac_get_cell_by_phy_id(gNB_MAC_INST *mac, uint16_t phy_id);
nr_cell_sched_t *nr_mac_get_cell_by_cgi(gNB_MAC_INST *mac, plmn_id_t plmn, uint64_t nr_cellid);

/// Append a zeroed cell slot and return a pointer to it.
nr_cell_sched_t *nr_mac_cell_alloc(gNB_MAC_INST *mac);

/// Free all heap-allocated members of a cell. Does not remove it from mac->cells.
void nr_mac_cell_free(nr_cell_sched_t *cell);

#endif /* __LAYER2_NR_MAC_CELL_H__ */
