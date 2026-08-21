import type { Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { createStockSchema } from '../middleware/validation.js';
import { createStock, listStock } from '../services/stockService.js';

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