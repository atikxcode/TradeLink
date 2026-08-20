import type { Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { createStockSchema } from '../middleware/validation.js';
import { createStock } from '../services/stockService.js';

export const publishStock = asyncHandler(async (req: AuthRequest, res: Response) => {
  const payload = createStockSchema.parse(req.body);
  const stockholderId = req.userId!;

  const stock = await createStock(stockholderId, payload);
  res.status(201).json({ success: true, data: stock });
});