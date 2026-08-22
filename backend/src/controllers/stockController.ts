import type { Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { createStockSchema } from '../middleware/validation.js';
import { createStock, listStock, updateStock, deleteStock } from '../services/stockService.js';

export const publishStock = asyncHandler(async (req: AuthRequest, res: Response) => {
  const stockholderId = req.userId!;
  
  // Handle multipart form data with optional image
  const body = req.body as Record<string, unknown>;
  const file = req.file;
  
  // Build payload from form fields
  const payload: {
    masterProductId?: string;
    customProductName: string;
    category: string;
    quantity: number;
    unit: string;
    pricePerUnit: number;
    imageUrl?: string;
    deliveryRadiusKm?: number;
  } = {
    customProductName: String(body.customProductName || ''),
    category: String(body.category || ''),
    quantity: Number(body.quantity || 0),
    unit: String(body.unit || 'kg'),
    pricePerUnit: Number(body.pricePerUnit || 0),
  };

  if (body.masterProductId) {
    payload.masterProductId = String(body.masterProductId);
  }

  if (body.deliveryRadiusKm) {
    payload.deliveryRadiusKm = Number(body.deliveryRadiusKm);
  }

  // If image was uploaded, generate public URL
  if (file) {
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    payload.imageUrl = `${baseUrl}/uploads/${file.filename}`;
  } else if (body.imageUrl) {
    payload.imageUrl = String(body.imageUrl);
  } else {
    payload.imageUrl = undefined;
  }

  // Validate with zod
  const validatedPayload = createStockSchema.parse(payload);
  
  const stock = await createStock(stockholderId, validatedPayload);
  res.status(201).json({ success: true, data: stock });
});

export const listStockHandler = asyncHandler(async (req: AuthRequest, res: Response) => {
  const stockholderId = req.userId!;
  const stock = await listStock(stockholderId);
  res.json({ success: true, data: stock });
});

export const updateStockHandler = asyncHandler(async (req: AuthRequest, res: Response) => {
  const stockholderId = req.userId!;
  const stockId = String(req.params.id);
  const body = req.body as Record<string, unknown>;
  const file = req.file;

  const payload: {
    customProductName?: string;
    category?: string;
    pricePerUnit?: number;
    quantity?: number;
    unit?: string;
    imageUrl?: string;
    deliveryRadiusKm?: number;
  } = {};

  if (body.customProductName !== undefined) payload.customProductName = String(body.customProductName);
  if (body.category !== undefined) payload.category = String(body.category);
  if (body.pricePerUnit !== undefined) payload.pricePerUnit = Number(body.pricePerUnit);
  if (body.quantity !== undefined) payload.quantity = Number(body.quantity);
  if (body.unit !== undefined) payload.unit = String(body.unit);
  if (body.deliveryRadiusKm !== undefined) payload.deliveryRadiusKm = Number(body.deliveryRadiusKm);

  // Handle image upload
  if (file) {
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    payload.imageUrl = `${baseUrl}/uploads/${file.filename}`;
  } else if (body.imageUrl !== undefined) {
    payload.imageUrl = String(body.imageUrl);
  }

  const stock = await updateStock(stockholderId, stockId, payload);
  if (!stock) {
    res.status(404).json({ success: false, error: 'Stock item not found' });
    return;
  }
  res.json({ success: true, data: stock });
});

export const deleteStockHandler = asyncHandler(async (req: AuthRequest, res: Response) => {
  const stockholderId = req.userId!;
  const stockId = String(req.params.id);

  const deleted = await deleteStock(stockholderId, stockId);
  if (!deleted) {
    res.status(404).json({ success: false, error: 'Stock item not found' });
    return;
  }
  res.json({ success: true, data: { message: 'Stock item deleted successfully' } });
});
