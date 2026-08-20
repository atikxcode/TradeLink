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
    const notifications = await listNotifications(userId);
    res.json({ success: true, data: notifications });
  },
);

export const markReadHandler = asyncHandler(
  async (req: AuthRequest, res: Response) => {
    const userId = req.userId!;
    const result = await markAllRead(userId);
    res.json({ success: true, data: result });
  },
);