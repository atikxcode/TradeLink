import { db } from '../db/pool.js';
import type {
  HomeStatsResponse,
  NearbyDemand,
} from '../types/index.js';
import { countActiveStock } from './stockService.js';

export interface DemandRow {
  id: string;
  shop_owner_id: string;
  product_name: string;
  category: string;
  quantity: number;
  unit: string;
  notes: string | null;
  status: string;
  created_at: Date;
}

export function mapDemandRow(row: DemandRow): NearbyDemand {
  return {
    id: row.id,
    shopOwnerId: row.shop_owner_id,
    productName: row.product_name,
    category: row.category,
    quantity: row.quantity,
    unit: row.unit,
    notes: row.notes,
    status: row.status as NearbyDemand['status'],
    createdAt: row.created_at.toISOString(),
  };
}

/**
 * Aggregates the Supplier (stockholder) home dashboard.
 *
 * Atik's schema stores supplier location on `users` and demands carry no
 * location/geo columns, so the demand feed is simply the newest pending
 * demands (not spatially ranked).
 */
export async function getHomeStats(userId: string): Promise<HomeStatsResponse> {
  const { rows: demandRows } = await db.query<DemandRow>(
    `SELECT id, shop_owner_id, product_name, category, quantity, unit, notes, status, created_at
     FROM demands
     WHERE status = 'pending'
     ORDER BY created_at DESC
     LIMIT 50`,
  );

  const { rows: pendingRows } = await db.query<{ count: string }>(
    `SELECT count(*)::text AS count
     FROM orders
     WHERE supplier_id = $1 AND status IN ('accepted', 'in_transit')`,
    [userId],
  );

  const stockItemsCount = await countActiveStock(userId);

  return {
    newDemandsCount: demandRows.length,
    pendingOrdersCount: Number(pendingRows[0]?.count ?? 0),
    stockItemsCount,
    nearbyDemands: demandRows.map(mapDemandRow),
  };
}