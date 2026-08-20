import { randomInt } from 'node:crypto';
import { db, type DbClient } from '../db/pool.js';
import type {
  AcceptDemandResponse,
  NotificationItem,
  OrderItem,
} from '../types/index.js';

export interface OrderRow {
  id: string;
  demand_id: string;
  stockholder_id: string;
  shop_owner_id: string;
  delivery_otp: string;
  status: string;
  created_at: Date;
}

export interface NotificationRow {
  id: string;
  recipient_id: string;
  recipient_role: string;
  title: string;
  message: string;
  type: string;
  is_read: boolean;
  created_at: Date;
}

export function mapOrderRow(row: OrderRow): OrderItem {
  return {
    id: row.id,
    demandId: row.demand_id,
    stockholderId: row.stockholder_id,
    shopOwnerId: row.shop_owner_id,
    deliveryOtp: row.delivery_otp,
    status: row.status as OrderItem['status'],
    createdAt: row.created_at.toISOString(),
  };
}

export function mapNotificationRow(row: NotificationRow): NotificationItem {
  return {
    id: row.id,
    recipientId: row.recipient_id,
    recipientRole: row.recipient_role as NotificationItem['recipientRole'],
    title: row.title,
    message: row.message,
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
 *   1. update demand.status -> 'accepted'
 *   2. create orders row with a generated 6-digit OTP
 *   3. insert a notification for the shop owner
 */
export async function acceptDemand(
  demandId: string,
  stockholderId: string,
  businessName: string,
): Promise<AcceptDemandResponse> {
  const client: DbClient = await db.connect();
  try {
    await client.query('BEGIN');

    const demand = await client.query<{
      id: string;
      shop_owner_id: string;
      product_name: string;
      status: string;
    }>(
      `SELECT id, shop_owner_id, product_name, status
       FROM demands WHERE id = $1 FOR UPDATE`,
      [demandId],
    );

    const demandRow = demand.rows[0];
    if (!demandRow) throw httpError('Demand not found', 404);
    if (demandRow.status !== 'pending') {
      throw httpError(`Demand already ${demandRow.status}`, 409);
    }

    await client.query(`UPDATE demands SET status = 'accepted' WHERE id = $1`, [
      demandId,
    ]);

    const otp = generateDeliveryOtp();
    const order = await client.query<OrderRow>(
      `INSERT INTO orders (demand_id, stockholder_id, shop_owner_id, delivery_otp, status)
       VALUES ($1, $2, $3, $4, 'accepted')
       RETURNING *`,
      [demandId, stockholderId, demandRow.shop_owner_id, otp],
    );

    await client.query(
      `INSERT INTO notifications (recipient_id, recipient_role, title, message, type)
       VALUES ($1, 'shop_owner', $2, $3, 'ORDER_ACCEPTED')`,
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

/** Decline a demand and remove it from the stockholder's feed. */
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

  await db.query(`UPDATE demands SET status = 'declined' WHERE id = $1`, [
    demandId,
  ]);

  return { demandId, message: 'Demand declined' };
}