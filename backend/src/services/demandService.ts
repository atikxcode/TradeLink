import { randomInt } from 'node:crypto';
import { db, type DbClient } from '../db/pool.js';
import type {
  AcceptDemandResponse,
  ConfirmDeliveryResponse,
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
    deliveryOtp: (row as any).delivery_otp ?? null,
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
 *   3. insert a notification for the shop owner
 *
 * No OTP is issued here — the delivery OTP is generated later, when the
 * supplier confirms the order for delivery (see confirmDelivery).
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
       FROM stockholder_inventory
       WHERE stockholder_id = $1 AND is_available = true
         AND custom_product_name ILIKE '%' || $2 || '%'
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

/**
 * Supplier (deliveryman) confirms the order for delivery:
 *   1. lock + validate the order belongs to this supplier and is 'accepted'
 *   2. generate a fresh 6-digit OTP and store it on the order
 *      (replaces any previous OTP via ON CONFLICT)
 *   3. move the order to 'in_transit'
 *   4. notify the SHOP OWNER with the OTP — they read it out to the
 *      deliveryman at handover to verify receipt
 *
 * The OTP is never returned to the supplier.
 */
export async function confirmDelivery(
  orderId: string,
  supplierId: string,
): Promise<ConfirmDeliveryResponse> {
  const client: DbClient = await db.connect();
  try {
    await client.query('BEGIN');

    const order = await client.query<OrderRow>(
      `SELECT id, demand_id, shop_owner_id, supplier_id, product_name,
              quantity, unit, total_amount, status, delivery_address, created_at
       FROM orders WHERE id = $1 FOR UPDATE`,
      [orderId],
    );

    const orderRow = order.rows[0];
    if (!orderRow) throw httpError('Order not found', 404);
    if (orderRow.supplier_id !== supplierId) {
      throw httpError('You are not the supplier of this order', 403);
    }
    if (orderRow.status === 'in_transit') {
      throw httpError('Delivery already confirmed for this order', 409);
    }
    if (orderRow.status !== 'accepted') {
      throw httpError(`Order is ${orderRow.status}, cannot confirm delivery`, 409);
    }

    const otp = generateDeliveryOtp();
    await client.query(
      `INSERT INTO otps (order_id, otp_code)
       VALUES ($1, $2)
       ON CONFLICT (order_id)
       DO UPDATE SET otp_code = EXCLUDED.otp_code,
                     is_verified = false,
                     expires_at = now() + interval '24 hours'`,
      [orderId, otp],
    );

    await client.query(
      `UPDATE orders SET status = 'in_transit' WHERE id = $1`,
      [orderId],
    );

    await client.query(
      `INSERT INTO notifications (user_id, title, subtitle, type)
       VALUES ($1, $2, $3, 'delivery_otp')`,
      [
        orderRow.shop_owner_id,
        'Your delivery OTP',
        `Share this OTP with the deliveryman to receive ${orderRow.product_name}: ${otp}`,
      ],
    );

    await client.query('COMMIT');

    return {
      orderId,
      status: 'in_transit',
      message: 'Delivery confirmed. OTP sent to the shop owner.',
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}