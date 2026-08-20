import { db } from '../db/pool.js';
import type { NotificationItem } from '../types/index.js';
import { mapNotificationRow, type NotificationRow } from './demandService.js';

/** Fetch a user's notifications, newest first. */
export async function listNotifications(userId: string): Promise<NotificationItem[]> {
  const { rows } = await db.query<NotificationRow>(
    `SELECT id, user_id, title, subtitle, type, is_read, created_at
     FROM notifications
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT 100`,
    [userId],
  );
  return rows.map(mapNotificationRow);
}

/** Mark all of a user's notifications as read. Returns number updated. */
export async function markAllRead(userId: string): Promise<{ updated: number }> {
  const { rowCount } = await db.query(
    `UPDATE notifications
     SET is_read = true
     WHERE user_id = $1 AND is_read = false`,
    [userId],
  );
  return { updated: rowCount ?? 0 };
}