import type { Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import {
  listNotifications,
  markAllRead,
} from '../services/notificationService.js';

export const getNotificationsHandler = asyncHandler(
  async (req: AuthRequest, res: Response) => {
    const userId = req.userId!;
    const role = req.role ?? 'stockholder';
    const notifications = await listNotifications(userId, role);
    res.json({ success: true, data: notifications });
  },
);

export const markReadHandler = asyncHandler(
  async (req: AuthRequest, res: Response) => {
    const userId = req.userId!;
    const role = req.role ?? 'stockholder';
    const result = await markAllRead(userId, role);
    res.json({ success: true, data: result });
  },
);