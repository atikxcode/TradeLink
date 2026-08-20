import { Router } from 'express';
import { publishStock } from '../controllers/stockController.js';
import { getHomeStatsHandler } from '../controllers/homeStatsController.js';
import {
  acceptDemandHandler,
  declineDemandHandler,
} from '../controllers/demandController.js';
import {
  getNotificationsHandler,
  markReadHandler,
} from '../controllers/notificationController.js';
import { requireStockholder } from '../middleware/auth.js';

const router = Router();

// Screen 09 — Publish Stock (stockholder only)
router.post('/stockholders/stock', requireStockholder, publishStock);

// Screen 08 — Home Feed & Stats (stockholder only)
router.get('/stockholders/home-stats', requireStockholder, getHomeStatsHandler);

// Screen 10 — Accept / Decline demand (stockholder only)
router.post('/demands/:id/accept', requireStockholder, acceptDemandHandler);
router.post('/demands/:id/decline', requireStockholder, declineDemandHandler);

// Screen 12 — Notifications (any authenticated user)
router.get('/notifications', getNotificationsHandler);
router.patch('/notifications/mark-read', markReadHandler);

export default router;