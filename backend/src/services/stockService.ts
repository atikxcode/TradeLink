import { db } from '../db/pool.js';
import type { CreateStockPayload, StockItem } from '../types/index.js';

export interface StockRow {
  id: string;
  stockholder_id: string;
  master_product_id: string | null;
  custom_product_name: string;
  category: string;
  price_per_unit: number;
  quantity_available: number;
  unit: string;
  is_available: boolean;
  created_at: Date;
  updated_at: Date;
}

export function mapStockRow(row: StockRow): StockItem {
  return {
    id: row.id,
    stockholderId: row.stockholder_id,
    masterProductId: row.master_product_id,
    customProductName: row.custom_product_name,
    category: row.category,
    pricePerUnit: row.price_per_unit,
    quantityAvailable: row.quantity_available,
    unit: row.unit,
    isAvailable: row.is_available,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString(),
  };
}

export async function createStock(
  userId: string,
  payload: CreateStockPayload,
): Promise<StockItem> {
  const { rows } = await db.query<StockRow>(
    `INSERT INTO stockholder_inventory
       (stockholder_id, master_product_id, custom_product_name, category,
        price_per_unit, quantity_available, unit, is_available)
     VALUES ($1, $2, $3, $4, $5, $6, $7, true)
     RETURNING *`,
    [
      userId,
      payload.masterProductId ?? null,
      payload.customProductName,
      payload.category,
      payload.pricePerUnit,
      payload.quantity,
      payload.unit,
    ],
  );
  return mapStockRow(rows[0]);
}

export async function countActiveStock(userId: string): Promise<number> {
  const { rows } = await db.query<{ count: string }>(
    `SELECT count(*)::text AS count
     FROM stockholder_inventory
     WHERE stockholder_id = $1 AND is_available = true`,
    [userId],
  );
  return Number(rows[0]?.count ?? 0);
}

export async function listStock(userId: string): Promise<StockItem[]> {
  const { rows } = await db.query<StockRow>(
    `SELECT * FROM stockholder_inventory
     WHERE stockholder_id = $1 AND is_available = true
     ORDER BY created_at DESC`,
    [userId],
  );
  return rows.map(mapStockRow);
}