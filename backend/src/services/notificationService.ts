import { db } from '../db/pool.js';
import type { NotificationItem } from '../types/index.js';
import { mapNotificationRow, type NotificationRow } from './demandService.js';

/** Fetch a user's notifications, newest first. */
export async function listNotifications(
  recipientId: string,
  role: 'stockholder' | 'shop_owner',
): Promise<NotificationItem[]> {
  const { rows } = await db.query<NotificationRow>(
    `SELECT id, recipient_id, recipient_role, title, message, type, is_read, created_at
     FROM notifications
     WHERE recipient_id = $1 AND recipient_role = $2
     ORDER BY created_at DESC
     LIMIT 100`,
    [recipientId, role],
  );
  return rows.map(mapNotificationRow);
}

/** Mark all of a user's notifications as read. Returns number updated. */
export async function markAllRead(
  recipientId: string,
  role: 'stockholder' | 'shop_owner',
): Promise<{ updated: number }> {
  const { rowCount } = await db.query(
    `UPDATE notifications
     SET is_read = true
     WHERE recipient_id = $1 AND recipient_role = $2 AND is_read = false`,
    [recipientId, role],
  );
  return { updated: rowCount ?? 0 };
}