import type { Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import {
  ChatIntent,
  classifyIntent,
  parseProductIntent,
  searchSuppliers,
  searchAllSuppliers,
  generateGreetingResponse,
  generateSearchResponse,
  generateUnknownResponse,
} from '../services/assistantService.js';
import { getDemandTrends, getSupplyTrends, generateForecastAnalysis } from '../services/forecastService.js';

/**
 * POST /assistant/chat
 *
 * Central intent router. Classifies the user's message, then dispatches
 * to the appropriate handler (greeting / product search / forecast / unknown).
 *
 * Body: { message: string, shopLat?: number, shopLng?: number }
 */
export const assistantChatHandler = asyncHandler(
  async (req: AuthRequest, res: Response) => {
    const { message, shopLat, shopLng } = req.body as {
      message?: string;
      shopLat?: number;
      shopLng?: number;
    };

    // ── Validate input ───────────────────────────────────────────
    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      res.status(400).json({ success: false, error: 'message is required' });
      return;
    }

    const lat = typeof shopLat === 'number' ? shopLat : 23.777176;
    const lng = typeof shopLng === 'number' ? shopLng : 90.399451;
    const trimmed = message.trim();

    // ── Classify intent ──────────────────────────────────────────
    const intent = classifyIntent(trimmed);

    console.log(`[assistant] intent=${intent} query="${trimmed}"`);

    // ── Route to handler ─────────────────────────────────────────
    try {
      switch (intent) {
        case ChatIntent.GREETING: {
          res.json({
            success: true,
            data: {
              reply: generateGreetingResponse(),
              suppliers: [],
              intentType: ChatIntent.GREETING,
            },
          });
          return;
        }

        case ChatIntent.PRODUCT_SEARCH: {
          const productIntent = parseProductIntent(trimmed);
          const suppliers = await searchSuppliers(productIntent, lat, lng);

          const reply = generateSearchResponse(productIntent, suppliers);

          const formatted = suppliers.map((s, idx) => ({
            rank: idx + 1,
            storeName: s.supplierName,
            location: s.warehouseAddress || 'Unknown',
            distance: `${s.distanceKm} km`,
            price: s.pricePerUnit,
            unit: s.unit,
            rating: s.rating,
            ratingCount: s.ratingCount,
            stockBadge: s.quantityAvailable > 0 ? 'In stock' : 'Out of stock',
            inStock: s.quantityAvailable > 0,
            isBestPrice: s.isBestPrice,
            imageUrl: s.imageUrl,
            stockId: s.stockId,
            stockholderId: s.stockholderId,
            productName: s.productName,
            quantityAvailable: s.quantityAvailable,
          }));

          res.json({
            success: true,
            data: {
              reply,
              suppliers: formatted,
              intentType: ChatIntent.PRODUCT_SEARCH,
              intent: {
                productName: productIntent.productName,
                sortBy: productIntent.sortBy,
                maxDistance: productIntent.maxDistance,
              },
            },
          });
          return;
        }

        case ChatIntent.FORECAST_DEMAND: {
          const [demandTrends, supplyTrends] = await Promise.all([
            getDemandTrends(30).catch(() => []),
            getSupplyTrends().catch(() => []),
          ]);

          const analysis = generateForecastAnalysis(demandTrends, supplyTrends, null);

          res.json({
            success: true,
            data: {
              reply: analysis,
              suppliers: [],
              intentType: ChatIntent.FORECAST_DEMAND,
              forecast: {
                demandTrends: demandTrends.map((d) => ({
                  productName: d.product_name,
                  category: d.category,
                  totalDemand: d.total_demand,
                  avgQuantity: d.avg_quantity,
                  uniqueBuyers: d.unique_buyers,
                  status: d.status,
                })),
                supplyTrends: supplyTrends.map((s) => ({
                  productName: s.product_name,
                  category: s.category,
                  totalStock: s.total_stock,
                  avgPrice: s.avg_price,
                  supplierCount: s.supplier_count,
                  totalQuantity: s.total_quantity,
                })),
              },
            },
          });
          return;
        }

        default: {
          // Unknown intent — try a broad product search as fallback
          const suppliers = await searchAllSuppliers(lat, lng, 3);
          let reply = generateUnknownResponse();

          if (suppliers.length > 0) {
            const names = suppliers.map((s) => s.productName).slice(0, 3).join(', ');
            reply += `\n\nHere are some products available near you: ${names}`;
          }

          res.json({
            success: true,
            data: {
              reply,
              suppliers: [],
              intentType: ChatIntent.UNKNOWN,
            },
          });
          return;
        }
      }
    } catch (err) {
      console.error('[assistant] error:', err);

      // Graceful fallback — don't crash the chat
      let fallbackReply = 'Something went wrong while searching. ';

      if (err instanceof Error) {
        if (err.message.includes('ECONNREFUSED') || err.message.includes('connect')) {
          fallbackReply += 'The database seems to be offline. Please try again in a moment.';
        } else if (err.message.includes('does not exist') || err.message.includes('relation')) {
          fallbackReply += 'Some data tables are still being set up. Basic search is available.';
        } else {
          fallbackReply += 'Please try rephrasing your query or try again shortly.';
        }
      } else {
        fallbackReply += 'Please try again.';
      }

      // Try a graceful greeting-level fallback
      res.json({
        success: true,
        data: {
          reply: fallbackReply,
          suppliers: [],
          intentType: 'ERROR',
        },
      });
    }
  },
);
