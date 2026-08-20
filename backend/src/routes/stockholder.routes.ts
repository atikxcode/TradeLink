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
import { requireSupplier } from '../middleware/auth.js';

const router = Router();

// Publish Stock (supplier only)
router.post('/suppliers/stock', requireSupplier, publishStock);

// Home Feed & Stats (supplier only)
router.get('/suppliers/home-stats', requireSupplier, getHomeStatsHandler);

// Accept / Decline demand (supplier only)
router.post('/demands/:id/accept', requireSupplier, acceptDemandHandler);
router.post('/demands/:id/decline', requireSupplier, declineDemandHandler);

// Notifications (any authenticated user)
router.get('/notifications', getNotificationsHandler);
router.patch('/notifications/mark-read', markReadHandler);

export default router;