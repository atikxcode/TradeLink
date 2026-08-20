import { db } from '../db/pool.js';
import type {
  HomeStatsResponse,
  NearbyDemand,
} from '../types/index.js';

export interface DemandRow {
  id: string;
  shop_owner_id: string;
  product_name: string;
  quantity: number;
  unit: string;
  delivery_location: string | null;
  notes: string | null;
  status: string;
  distance_km: number | null;
  created_at: Date;
}

export function mapDemandRow(row: DemandRow): NearbyDemand {
  return {
    id: row.id,
    shopOwnerId: row.shop_owner_id,
    productName: row.product_name,
    quantity: row.quantity,
    unit: row.unit,
    deliveryLocation: row.delivery_location,
    notes: row.notes,
    status: row.status as NearbyDemand['status'],
    distanceKm: row.distance_km,
    createdAt: row.created_at.toISOString(),
  };
}

/**
 * Aggregates the Stockholder home dashboard.
 *
 * Uses a GIST spatial query (PostGIS) on `demands.location_geo` to rank nearby
 * pending demands by distance from the stockholder's warehouse, scoped by the
 * stockholder's maximum service radius.
 */
export async function getHomeStats(stockholderId: string): Promise<HomeStatsResponse> {
  const stockholder = await db.query<{
    location_geo?: { coordinates?: [number, number] };
    radius_km: number;
  }>(
    `SELECT
       s.location_geo,
       COALESCE(MAX(i.service_radius_km), 10)::int AS radius_km
     FROM stockholders s
     LEFT JOIN stock_items i ON i.stockholder_id = s.stockholder_id AND i.is_active = true
     WHERE s.stockholder_id = $1
     GROUP BY s.location_geo`,
    [stockholderId],
  );

  const geo = stockholder.rows[0]?.location_geo;
  const radiusKm = stockholder.rows[0]?.radius_km ?? 10;

  const { rows: demandRows } = await db.query<DemandRow>(
    `SELECT
       d.id, d.shop_owner_id, d.product_name, d.quantity, d.unit,
       d.delivery_location, d.notes, d.status, d.created_at,
       CASE
         WHEN $2::geography IS NOT NULL AND d.location_geo IS NOT NULL
           THEN ST_Distance(d.location_geo, $2::geography) / 1000.0
         ELSE NULL
       END AS distance_km
     FROM demands d
     WHERE d.status = 'pending'
       AND (
         $2::geography IS NULL
         OR d.location_geo IS NULL
         OR ST_DWithin(d.location_geo, $2::geography, $3 * 1000)
       )
     ORDER BY distance_km ASC NULLS LAST
     LIMIT 50`,
    [stockholderId, geo ? geo : null, radiusKm],
  );

  const { rows: pendingRows } = await db.query<{ count: string }>(
    `SELECT count(*)::text AS count
     FROM orders
     WHERE stockholder_id = $1 AND status = 'accepted'`,
    [stockholderId],
  );

  const stockItemsCount = await countActiveStockFor(stockholderId);

  return {
    newDemandsCount: demandRows.length,
    pendingOrdersCount: Number(pendingRows[0]?.count ?? 0),
    stockItemsCount,
    nearbyDemands: demandRows.map(mapDemandRow),
  };
}

async function countActiveStockFor(stockholderId: string): Promise<number> {
  const { rows } = await db.query<{ count: string }>(
    `SELECT count(*)::text AS count
     FROM stock_items
     WHERE stockholder_id = $1 AND is_active = true`,
    [stockholderId],
  );
  return Number(rows[0]?.count ?? 0);
}