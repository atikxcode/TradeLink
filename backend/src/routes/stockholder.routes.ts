import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import { publishStock, listStockHandler, updateStockHandler, deleteStockHandler } from '../controllers/stockController.js';
import { getHomeStatsHandler } from '../controllers/homeStatsController.js';
import {
  acceptDemandHandler,
  confirmDeliveryHandler,
  declineDemandHandler,
} from '../controllers/demandController.js';
import {
  getNotificationsHandler,
  getUnreadCountHandler,
  markOneReadHandler,
  markReadHandler,
} from '../controllers/notificationController.js';
import {
  submitReviewHandler,
  getSupplierRatingHandler,
  getInventoryRatingHandler,
  listInventoryReviewsHandler,
  resolveOrderHandler,
} from '../controllers/reviewController.js';
import {
  listMasterProductsHandler,
  searchInventoryHandler,
  getCheapestSuppliersHandler,
} from '../controllers/masterProductController.js';
import { listOrdersHandler } from '../controllers/orderController.js';
import { getPendingOrdersHandler, getCompletedOrdersHandler } from '../controllers/pendingOrderController.js';
import { createDirectOrderHandler } from '../controllers/directOrderController.js';
import {
  acceptOrderHandler,
  declineOrderHandler,
  markOutOfDeliveryHandler,
  verifyDeliveryHandler,
} from '../controllers/orderLifecycleController.js';
import { getShopOwnerOrdersHandler } from '../controllers/shopOwnerOrderController.js';
import { getProfileHandler, updateProfileHandler } from '../controllers/profileController.js';
import {
  searchMarketplaceHandler,
  getProductDetailHandler,
  getProductsByCategoryHandler,
} from '../controllers/marketplaceController.js';
import { assistantChatHandler, placeChatbotOrderHandler } from '../controllers/assistantController.js';
import {
  startChatHandler,
  getUserChatsHandler,
  getChatMessagesHandler,
  sendChatMessageHandler,
} from '../controllers/chatController.js';
import {
  initiateNegotiationHandler,
  getShopOwnerNegotiationsHandler,
  getSupplierNegotiationsHandler,
  counterNegotiationHandler,
  respondToNegotiationHandler,
  sendNegotiationMessageHandler,
  getNegotiationMessagesHandler,
  getSupplierNegotiationsByIdHandler,
  finalizeNegotiationHandler,
} from '../controllers/negotiationController.js';
import { forecastHandler } from '../controllers/forecastController.js';
import { requireSupplier } from '../middleware/auth.js';
import debugRoutes from './debug.routes.js';

// Configure multer for image uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(process.cwd(), 'uploads'));
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1E9)}`;
    cb(null, `${uniqueSuffix}${path.extname(file.originalname)}`);
  },
});

const fileFilter = (
  req: Express.Request,
  file: Express.Multer.File,
  cb: multer.FileFilterCallback,
) => {
  const allowedMimes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  if (allowedMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only image files (JPEG, PNG, WebP, GIF) are allowed'));
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
});

const router = Router();

// ---- Profile ----
router.get('/profile', getProfileHandler);
router.patch('/profile', updateProfileHandler);

// ---- Master Product Catalog ----
router.get('/master-products', listMasterProductsHandler);

// ---- Inventory Search (AI chatbot sourcing) ----
router.get('/inventory/search', searchInventoryHandler);
router.get('/inventory/cheapest', getCheapestSuppliersHandler);

// ---- Marketplace Search (Shop Owner sourcing) ----
router.post('/marketplace/search', searchMarketplaceHandler);
router.post('/marketplace/products/:id', getProductDetailHandler);
router.post('/marketplace/category/:category', getProductsByCategoryHandler);

// ---- AI Assistant ----
router.post('/assistant/chat', assistantChatHandler);
router.post('/assistant/order', placeChatbotOrderHandler);
router.post('/assistant/forecast', forecastHandler);

// ---- Supplier (Stockholder) endpoints ----
router.post('/suppliers/stock', requireSupplier, upload.single('image'), publishStock);
router.get('/suppliers/stock', requireSupplier, listStockHandler);
router.patch('/suppliers/stock/:id', requireSupplier, updateStockHandler);
router.delete('/suppliers/stock/:id', requireSupplier, deleteStockHandler);
router.get('/suppliers/home-stats', requireSupplier, getHomeStatsHandler);

// ---- Demand endpoints ----
router.post('/demands/:id/accept', requireSupplier, acceptDemandHandler);
router.post('/demands/:id/decline', requireSupplier, declineDemandHandler);

// ---- Order / delivery endpoints ----
router.post('/orders/direct', createDirectOrderHandler);
router.get('/orders', requireSupplier, listOrdersHandler);
router.get('/orders/pending', requireSupplier, getPendingOrdersHandler);
router.get('/orders/completed', requireSupplier, getCompletedOrdersHandler);
router.get('/orders/shop-owner', getShopOwnerOrdersHandler);

// ---- Order lifecycle (supplier actions) ----
router.post('/orders/:id/accept', requireSupplier, acceptOrderHandler);
router.post('/orders/:id/decline', requireSupplier, declineOrderHandler);
router.post('/orders/:id/out-for-delivery', requireSupplier, markOutOfDeliveryHandler);
router.post('/orders/:id/verify-delivery', requireSupplier, verifyDeliveryHandler);

// ---- Notifications ----
router.get('/notifications', getNotificationsHandler);
router.get('/notifications/unread-count', getUnreadCountHandler);
router.patch('/notifications/mark-read', markReadHandler);
router.patch('/notifications/:id/read', markOneReadHandler);

// ---- Direct messaging (buyer-seller chat) ----
router.post('/chats/start', startChatHandler);
router.get('/chats/user', getUserChatsHandler);
router.post('/chats/:chatId/messages', sendChatMessageHandler);
router.get('/chats/:chatId/messages', getChatMessagesHandler);

// ---- Reviews ----
router.post('/reviews', submitReviewHandler);

// ---- Negotiations (price bargaining) ----
router.post('/negotiations/initiate', initiateNegotiationHandler);
router.get('/negotiations/shop-owner', getShopOwnerNegotiationsHandler);
router.get('/negotiations/supplier', getSupplierNegotiationsHandler);
router.get('/negotiations/supplier/:stockholderId', getSupplierNegotiationsByIdHandler);
router.post('/negotiations/message', sendNegotiationMessageHandler);
router.post('/negotiations/counter', counterNegotiationHandler);
router.post('/negotiations/respond', respondToNegotiationHandler);
router.get('/negotiations/:id/messages', getNegotiationMessagesHandler);
router.post('/negotiations/:id/finalize', finalizeNegotiationHandler);
router.get('/reviews/resolve-order', resolveOrderHandler);
router.get('/reviews/supplier/:supplierId', getSupplierRatingHandler);
router.get('/reviews/inventory/:inventoryId/reviews', listInventoryReviewsHandler);
router.get('/reviews/inventory/:inventoryId', getInventoryRatingHandler);

router.use(debugRoutes);

export default router;
