import { db } from '../db/pool.js';
import type { CreateStockPayload, StockItem } from '../types/index.js';

export interface StockRow {
  id: string;
  stockholder_id: string;
  category: string;
  product_name: string;
  quantity_available: number;
  unit: string;
  price_per_unit: number;
  service_radius_km: number;
  is_active: boolean;
  created_at: Date;
  updated_at: Date;
}

export function mapStockRow(row: StockRow): StockItem {
  return {
    id: row.id,
    stockholderId: row.stockholder_id,
    category: row.category,
    productName: row.product_name,
    quantityAvailable: row.quantity_available,
    unit: row.unit,
    pricePerUnit: row.price_per_unit,
    serviceRadiusKm: row.service_radius_km,
    isActive: row.is_active,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString(),
  };
}

export async function createStock(
  stockholderId: string,
  payload: CreateStockPayload,
): Promise<StockItem> {
  const { rows } = await db.query<StockRow>(
    `INSERT INTO stock_items
       (stockholder_id, category, product_name, quantity_available, unit, price_per_unit, service_radius_km)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [
      stockholderId,
      payload.category,
      payload.productName,
      payload.quantity,
      payload.unit,
      payload.pricePerUnit,
      payload.serviceRadiusKm ?? 10,
    ],
  );
  return mapStockRow(rows[0]);
}

export async function countActiveStock(stockholderId: string): Promise<number> {
  const { rows } = await db.query<{ count: string }>(
    `SELECT count(*)::text AS count
     FROM stock_items
     WHERE stockholder_id = $1 AND is_active = true`,
    [stockholderId],
  );
  return Number(rows[0]?.count ?? 0);
}