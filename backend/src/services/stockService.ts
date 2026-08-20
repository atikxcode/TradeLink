import { db } from '../db/pool.js';
import type { CreateStockPayload, StockItem } from '../types/index.js';

export interface StockRow {
  id: string;
  user_id: string;
  product_id: string | null;
  category: string;
  product_name: string;
  quantity: number;
  unit: string;
  price_per_unit: number;
  is_available: boolean;
  created_at: Date;
  updated_at: Date;
}

export function mapStockRow(row: StockRow): StockItem {
  return {
    id: row.id,
    userId: row.user_id,
    productId: row.product_id,
    category: row.category,
    productName: row.product_name,
    quantity: row.quantity,
    unit: row.unit,
    pricePerUnit: row.price_per_unit,
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
    `INSERT INTO stocks
       (user_id, product_name, category, quantity, unit, price_per_unit, is_available)
     VALUES ($1, $2, $3, $4, $5, $6, true)
     RETURNING *`,
    [
      userId,
      payload.productName,
      payload.category,
      payload.quantity,
      payload.unit,
      payload.pricePerUnit,
    ],
  );
  return mapStockRow(rows[0]);
}

export async function countActiveStock(userId: string): Promise<number> {
  const { rows } = await db.query<{ count: string }>(
    `SELECT count(*)::text AS count
     FROM stocks
     WHERE user_id = $1 AND is_available = true`,
    [userId],
  );
  return Number(rows[0]?.count ?? 0);
}