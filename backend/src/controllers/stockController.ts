import type { Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { createStockSchema } from '../middleware/validation.js';
import { createStock, listStock, updateStock, deleteStock } from '../services/stockService.js';

export const publishStock = asyncHandler(async (req: AuthRequest, res: Response) => {
  const payload = createStockSchema.parse(req.body);
  const stockholderId = req.userId!;

  const stock = await createStock(stockholderId, payload);
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

  const payload: {
    customProductName?: string;
    category?: string;
    pricePerUnit?: number;
    quantity?: number;
    unit?: string;
  } = {};

  if (body.customProductName !== undefined) payload.customProductName = String(body.customProductName);
  if (body.category !== undefined) payload.category = String(body.category);
  if (body.pricePerUnit !== undefined) payload.pricePerUnit = Number(body.pricePerUnit);
  if (body.quantity !== undefined) payload.quantity = Number(body.quantity);
  if (body.unit !== undefined) payload.unit = String(body.unit);

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
