import { randomInt } from 'node:crypto';
import { db, type DbClient } from '../db/pool.js';
import type {
  AcceptDemandResponse,
  NotificationItem,
  OrderItem,
} from '../types/index.js';

export interface OrderRow {
  id: string;
  demand_id: string | null;
  shop_owner_id: string;
  supplier_id: string;
  product_name: string;
  quantity: number;
  unit: string;
  total_amount: number;
  status: string;
  delivery_address: string | null;
  created_at: Date;
}

export interface OTPRow {
  id: string;
  order_id: string;
  otp_code: string;
  is_verified: boolean;
  expires_at: Date;
}

export interface NotificationRow {
  id: string;
  user_id: string;
  title: string;
  subtitle: string;
  type: string;
  is_read: boolean;
  created_at: Date;
}

export function mapOrderRow(row: OrderRow): OrderItem {
  return {
    id: row.id,
    demandId: row.demand_id,
    shopOwnerId: row.shop_owner_id,
    supplierId: row.supplier_id,
    productName: row.product_name,
    quantity: row.quantity,
    unit: row.unit,
    totalAmount: row.total_amount,
    status: row.status as OrderItem['status'],
    deliveryAddress: row.delivery_address,
    createdAt: row.created_at.toISOString(),
  };
}

export function mapNotificationRow(row: NotificationRow): NotificationItem {
  return {
    id: row.id,
    userId: row.user_id,
    title: row.title,
    subtitle: row.subtitle,
    type: row.type,
    isRead: row.is_read,
    createdAt: row.created_at.toISOString(),
  };
}

export function generateDeliveryOtp(): string {
  return String(randomInt(100000, 1_000_000));
}

function httpError(message: string, status: number): Error & { status: number } {
  const error = new Error(message) as Error & { status: number };
  error.status = status;
  return error;
}

/**
 * Accept a demand inside a DB transaction:
 *   1. update demand.status -> 'accepted' + accepted_supplier_id
 *   2. create orders row (status 'accepted')
 *   3. create otps row with a generated 6-digit code
 *   4. insert a notification for the shop owner
 */
export async function acceptDemand(
  demandId: string,
  supplierId: string,
  businessName: string,
): Promise<AcceptDemandResponse> {
  const client: DbClient = await db.connect();
  try {
    await client.query('BEGIN');

    const demand = await client.query<{
      id: string;
      shop_owner_id: string;
      product_name: string;
      quantity: number;
      unit: string;
      status: string;
    }>(
      `SELECT id, shop_owner_id, product_name, quantity, unit, status
       FROM demands WHERE id = $1 FOR UPDATE`,
      [demandId],
    );

    const demandRow = demand.rows[0];
    if (!demandRow) throw httpError('Demand not found', 404);
    if (demandRow.status !== 'pending') {
      throw httpError(`Demand already ${demandRow.status}`, 409);
    }

    await client.query(
      `UPDATE demands
       SET status = 'accepted', accepted_supplier_id = $1, accepted_at = now()
       WHERE id = $2`,
      [supplierId, demandId],
    );

    const { rows: stockRows } = await client.query<{ price_per_unit: number }>(
      `SELECT price_per_unit
       FROM stocks
       WHERE user_id = $1 AND is_available = true AND product_name = $2
       ORDER BY created_at DESC
       LIMIT 1`,
      [supplierId, demandRow.product_name],
    );
    const pricePerUnit = stockRows[0]?.price_per_unit ?? 0;
    const totalAmount = demandRow.quantity * pricePerUnit;

    const order = await client.query<OrderRow>(
      `INSERT INTO orders
         (demand_id, shop_owner_id, supplier_id, product_name, quantity, unit, total_amount, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'accepted')
       RETURNING *`,
      [
        demandId,
        demandRow.shop_owner_id,
        supplierId,
        demandRow.product_name,
        demandRow.quantity,
        demandRow.unit,
        totalAmount,
      ],
    );

    const otp = generateDeliveryOtp();
    const otpRow = await client.query<OTPRow>(
      `INSERT INTO otps (order_id, otp_code)
       VALUES ($1, $2)
       RETURNING *`,
      [order.rows[0].id, otp],
    );

    await client.query(
      `INSERT INTO notifications (user_id, title, subtitle, type)
       VALUES ($1, $2, $3, 'order_accepted')`,
      [
        demandRow.shop_owner_id,
        'Order accepted by ' + businessName,
        `Your demand for ${demandRow.product_name} is now pending delivery.`,
      ],
    );

    await client.query('COMMIT');

    return {
      order: mapOrderRow(order.rows[0]),
      deliveryOtp: otpRow.rows[0].otp_code,
      demandId,
      message: 'Demand accepted',
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/** Decline a demand and remove it from the supplier's feed. */
export async function declineDemand(
  demandId: string,
): Promise<{ demandId: string; message: string }> {
  const demand = await db.query<{ id: string; status: string }>(
    `SELECT id, status FROM demands WHERE id = $1`,
    [demandId],
  );

  const row = demand.rows[0];
  if (!row) throw httpError('Demand not found', 404);
  if (row.status !== 'pending') {
    throw httpError(`Demand already ${row.status}`, 409);
  }

  await db.query(`UPDATE demands SET status = 'cancelled' WHERE id = $1`, [
    demandId,
  ]);

  return { demandId, message: 'Demand declined' };
}