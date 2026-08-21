import { Router } from 'express';
import { publishStock, listStockHandler } from '../controllers/stockController.js';
import { getHomeStatsHandler } from '../controllers/homeStatsController.js';
import {
  acceptDemandHandler,
  confirmDeliveryHandler,
  declineDemandHandler,
} from '../controllers/demandController.js';
import {
  getNotificationsHandler,
  markReadHandler,
} from '../controllers/notificationController.js';
import {
  listMasterProductsHandler,
  searchInventoryHandler,
  getCheapestSuppliersHandler,
} from '../controllers/masterProductController.js';
import { requireSupplier } from '../middleware/auth.js';

const router = Router();

// ---- Master Product Catalog ----
router.get('/master-products', listMasterProductsHandler);

// ---- Inventory Search (AI chatbot sourcing) ----
router.get('/inventory/search', searchInventoryHandler);
router.get('/inventory/cheapest', getCheapestSuppliersHandler);

// ---- Supplier (Stockholder) endpoints ----
router.post('/suppliers/stock', requireSupplier, publishStock);
router.get('/suppliers/stock', requireSupplier, listStockHandler);
router.get('/suppliers/home-stats', requireSupplier, getHomeStatsHandler);

// ---- Demand endpoints ----
router.post('/demands/:id/accept', requireSupplier, acceptDemandHandler);
router.post('/demands/:id/decline', requireSupplier, declineDemandHandler);

// ---- Order / delivery endpoints ----
router.post('/orders/:id/confirm-delivery', requireSupplier, confirmDeliveryHandler);

// ---- Notifications ----
router.get('/notifications', getNotificationsHandler);
router.patch('/notifications/mark-read', markReadHandler);

export default router;