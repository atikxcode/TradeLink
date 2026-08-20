import type { Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { parseId } from '../middleware/validation.js';
import { acceptDemand, declineDemand } from '../services/demandService.js';
import { db } from '../db/pool.js';

async function getStockholderBusinessName(stockholderId: string): Promise<string> {
  const { rows } = await db.query<{ business_name: string }>(
    `SELECT business_name FROM stockholders WHERE stockholder_id = $1`,
    [stockholderId],
  );
  return rows[0]?.business_name ?? 'Your supplier';
}

export const acceptDemandHandler = asyncHandler(
  async (req: AuthRequest, res: Response) => {
    const demandId = parseId(String(req.params.id), 'demand id');
    const stockholderId = req.userId!;
    const businessName = await getStockholderBusinessName(stockholderId);

    const result = await acceptDemand(demandId, stockholderId, businessName);
    res.json({ success: true, data: result });
  },
);

export const declineDemandHandler = asyncHandler(
  async (req: AuthRequest, res: Response) => {
    const demandId = parseId(String(req.params.id), 'demand id');
    const result = await declineDemand(demandId);
    res.json({ success: true, data: result });
  },
);