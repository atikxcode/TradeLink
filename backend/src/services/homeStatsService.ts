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
  target_price: number | null;
  status: string;
  created_at: Date;
  delivery_address: string;
  latitude: number | null;
  longitude: number | null;
  shop_owner_name: string;
  shop_owner_phone: string;
}

export function mapDemandRow(row: DemandRow): NearbyDemand {
  return {
    id: row.id,
    shopOwnerId: row.shop_owner_id,
    productName: row.product_name,
    category: row.category,
    quantity: Number(row.quantity),
    unit: row.unit,
    notes: row.notes,
    targetPrice: row.target_price != null ? Number(row.target_price) : null,
    status: row.status as NearbyDemand['status'],
    createdAt: row.created_at.toISOString(),
    deliveryAddress: row.delivery_address || null,
    latitude: row.latitude != null ? Number(row.latitude) : null,
    longitude: row.longitude != null ? Number(row.longitude) : null,
    shopOwnerName: row.shop_owner_name,
    shopOwnerPhone: row.shop_owner_phone,
  };
}

/**
 * Aggregates the Supplier (stockholder) home dashboard.
 */
export async function getHomeStats(userId: string): Promise<HomeStatsResponse> {
  const { rows: demandRows } = await db.query<DemandRow>(
    `SELECT d.id, d.shop_owner_id, d.product_name, d.category, d.quantity,
            d.unit, d.notes, d.target_price, d.status, d.created_at,
            COALESCE(d.delivery_address, u.address, '') AS delivery_address,
            d.latitude, d.longitude,
            COALESCE(u.business_name, u.full_name, 'Shop Owner') AS shop_owner_name,
            COALESCE(u.phone_number, '') AS shop_owner_phone
     FROM demands d
     LEFT JOIN users u ON u.id = d.shop_owner_id
     WHERE d.status IN ('open', 'pending')
     ORDER BY d.created_at DESC
     LIMIT 50`,
  );

  const { rows: pendingRows } = await db.query<{ count: string }>(
    `SELECT count(*)::text AS count
     FROM orders
     WHERE supplier_id = $1
       AND status IN ('pending', 'accepted', 'out_for_delivery', 'in_transit')`,
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