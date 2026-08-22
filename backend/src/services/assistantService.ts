import { db } from '../db/pool.js';

// ── Intent Classification ──────────────────────────────────────────

export enum ChatIntent {
  GREETING = 'GREETING',
  PRODUCT_SEARCH = 'PRODUCT_SEARCH',
  FORECAST_DEMAND = 'FORECAST_DEMAND',
  UNKNOWN = 'UNKNOWN',
}

export function classifyIntent(message: string): ChatIntent {
  const lower = message.toLowerCase().trim();

  if (['hi', 'hello', 'hey', 'start', 'help', 'yo', 'sup', 'howdy'].includes(lower)) {
    return ChatIntent.GREETING;
  }

  if (
    /\b(demand|forecast|next week|next month|trend|popular|trending|what will sell|what should i stock|season|outlook|predict)\b/.test(lower)
  ) {
    return ChatIntent.FORECAST_DEMAND;
  }

  return ChatIntent.PRODUCT_SEARCH;
}

// ── NLU Parsed Intent ──────────────────────────────────────────────

export interface AssistantIntent {
  productName: string | null;
  sortBy: 'price' | 'distance' | 'rating';
  maxDistance: number;
  minRating: number;
  category: string | null;
  quantity: number | null;
}

// ── Supplier result row ────────────────────────────────────────────

export interface AssistantSupplierResult {
  stockId: string;
  stockholderId: string;
  supplierName: string;
  warehouseAddress: string;
  productName: string;
  category: string;
  pricePerUnit: number;
  quantityAvailable: number;
  unit: string;
  imageUrl: string | null;
  distanceKm: number;
  rating: number;
  ratingCount: number;
  isBestPrice: boolean;
}

// ── Keyword maps ───────────────────────────────────────────────────

const SORT_KEYWORDS: Record<string, AssistantIntent['sortBy']> = {
  cheapest: 'price',
  lowest: 'price',
  'best price': 'price',
  affordable: 'price',
  close: 'distance',
  nearest: 'distance',
  nearby: 'distance',
  closest: 'distance',
  rated: 'rating',
  'best rated': 'rating',
  top: 'rating',
};

const CATEGORY_KEYWORDS: Record<string, string> = {
  rice: 'Grocery',
  wheat: 'Grocery',
  sugar: 'Grocery',
  oil: 'Grocery',
  spice: 'Grocery',
  tea: 'Grocery',
  coffee: 'Grocery',
  flour: 'Grocery',
  salt: 'Grocery',
  milk: 'Grocery',
  medicine: 'Pharmacy',
  drug: 'Pharmacy',
  pill: 'Pharmacy',
  tablet: 'Pharmacy',
  pen: 'Stationery',
  pencil: 'Stationery',
  paper: 'Stationery',
  notebook: 'Stationery',
  hammer: 'Hardware',
  nail: 'Hardware',
  screw: 'Hardware',
  tool: 'Hardware',
  paint: 'Hardware',
};

const FILLER_WORDS =
  /\b(find|get|show|search|where|can|i|me|need|want|buy|look|looking for|sort|by|only|within|less than|under|max|and|up|the|a|an|some|any|please|plz)\b/gi;

const FILTER_PHRASES =
  /\b(cheapest|nearest|closest|best price|low price|nearby|near|close|top rated|best rated|4\.5|4 star|★|sort by|sorted by|order by|ordered by|within|less than|under|max|maximum)\b/gi;

// ── Parse product search intent from free text ─────────────────────

export function parseProductIntent(text: string): AssistantIntent {
  const lower = text.toLowerCase().trim();

  // Sort
  let sortBy: AssistantIntent['sortBy'] = 'price';
  for (const [keyword, sort] of Object.entries(SORT_KEYWORDS)) {
    if (lower.includes(keyword)) {
      sortBy = sort;
      break;
    }
  }

  // Max distance
  let maxDistance = 50;
  const distMatch = lower.match(/(\d+)\s*(?:km|kilometer)/);
  if (distMatch) maxDistance = parseInt(distMatch[1], 10);
  if (/\b(near|close|nearby)\b/.test(lower)) maxDistance = Math.min(maxDistance, 10);

  // Min rating
  let minRating = 0;
  const ratingMatch = lower.match(/(\d+(?:\.\d+)?)\s*(?:★|star|rating)/);
  if (ratingMatch) minRating = parseFloat(ratingMatch[1]);
  if (/4\.5/.test(lower)) minRating = Math.max(minRating, 4.5);

  // Quantity
  let quantity: number | null = null;
  const qtyMatch = lower.match(/(\d+(?:\.\d+)?)\s*(?:kg|ltr|litre|liter|pcs|piece)/);
  if (qtyMatch) quantity = parseFloat(qtyMatch[1]);

  // Category
  let category: string | null = null;
  for (const [kw, cat] of Object.entries(CATEGORY_KEYWORDS)) {
    if (lower.includes(kw)) {
      category = cat;
      break;
    }
  }

  // Product name — strip filler words, filter phrases, numbers, and units
  let raw = lower
    .replace(FILLER_WORDS, '')
    .replace(FILTER_PHRASES, '')
    .replace(/\b\d+\s*(?:km|kilometer|kg|ltr|pcs|star|★)?\b/gi, '')
    .replace(/\s+/g, ' ')
    .trim();

  const productName = raw.length >= 2 ? raw : null;

  return { productName, sortBy, maxDistance, minRating, category, quantity };
}

// ── Haversine distance SQL fragment ────────────────────────────────
// Clamps the ACOS input to [-1, 1] to prevent numeric domain errors
// caused by floating-point imprecision.

function haversineSql(): string {
  return `
    CASE
      WHEN u.latitude IS NOT NULL AND u.longitude IS NOT NULL THEN
        ROUND(CAST(
          6371 * ACOS(
            GREATEST(-1, LEAST(1,
              COS(RADIANS($1)) * COS(RADIANS(u.latitude))
              * COS(RADIANS(u.longitude) - RADIANS($2))
              + SIN(RADIANS($1)) * SIN(RADIANS(u.latitude))
            ))
          ) AS numeric
        ), 1)
      ELSE 999
    END
  `;
}

// ── Search suppliers in PostgreSQL ─────────────────────────────────

export async function searchSuppliers(
  intent: AssistantIntent,
  shopLat: number,
  shopLng: number,
): Promise<AssistantSupplierResult[]> {
  const haversine = haversineSql();

  let sql = `
    SELECT
      si.id AS stock_id,
      si.stockholder_id,
      COALESCE(u.full_name, 'Unknown Supplier') AS supplier_name,
      COALESCE(u.address, '') AS warehouse_address,
      si.custom_product_name AS product_name,
      si.category,
      si.price_per_unit,
      si.quantity_available,
      si.unit,
      si.image_url,
      COALESCE(u.rating, 5.0) AS rating,
      COALESCE(u.review_count, 0) AS rating_count,
      ${haversine} AS distance_km
    FROM public.stockholder_inventory si
    JOIN public.users u ON si.stockholder_id = u.id
    WHERE si.is_available = true
      AND si.quantity_available > 0
  `;

  const params: (string | number)[] = [shopLat, shopLng];
  let idx = 3;

  // Product name filter
  if (intent.productName) {
    sql += ` AND (
      LOWER(si.custom_product_name) ILIKE $${idx}
      OR LOWER(si.category) ILIKE $${idx}
    )`;
    params.push(`%${intent.productName}%`);
    idx++;
  }

  // Category filter
  if (intent.category) {
    sql += ` AND LOWER(si.category) = LOWER($${idx})`;
    params.push(intent.category);
    idx++;
  }

  // Distance filter — reuse the same Haversine expression
  sql += ` AND ${haversine} <= $${idx}`;
  params.push(intent.maxDistance);
  idx++;

  // Sort
  switch (intent.sortBy) {
    case 'price':
      sql += ` ORDER BY si.price_per_unit ASC, distance_km ASC`;
      break;
    case 'distance':
      sql += ` ORDER BY distance_km ASC, si.price_per_unit ASC`;
      break;
    case 'rating':
      sql += ` ORDER BY rating DESC, distance_km ASC`;
      break;
  }

  sql += ` LIMIT 10`;

  let rows: any[];
  try {
    const result = await db.query(sql, params);
    rows = result.rows;
  } catch (dbErr: any) {
    console.error('[assistant] searchSuppliers query error:', dbErr?.message ?? dbErr);
    // Return empty rather than crash — the controller handles empty results gracefully
    return [];
  }

  const bestPrice = rows.length > 0 ? rows[0].price_per_unit : 0;

  return rows.map((row) => ({
    stockId: row.stock_id,
    stockholderId: row.stockholder_id,
    supplierName: row.supplier_name,
    warehouseAddress: row.warehouse_address,
    productName: row.product_name,
    category: row.category,
    pricePerUnit: row.price_per_unit,
    quantityAvailable: row.quantity_available,
    unit: row.unit,
    imageUrl: row.image_url,
    distanceKm: row.distance_km,
    rating: Number(row.rating) || 5.0,
    ratingCount: Number(row.rating_count) || 0,
    isBestPrice: row.price_per_unit === bestPrice,
  }));
}

// ── Broad search fallback (no product filter) ─────────────────────

export async function searchAllSuppliers(
  shopLat: number,
  shopLng: number,
  limit = 5,
): Promise<AssistantSupplierResult[]> {
  const haversine = haversineSql();

  const sql = `
    SELECT
      si.id AS stock_id,
      si.stockholder_id,
      COALESCE(u.full_name, 'Unknown Supplier') AS supplier_name,
      COALESCE(u.address, '') AS warehouse_address,
      si.custom_product_name AS product_name,
      si.category,
      si.price_per_unit,
      si.quantity_available,
      si.unit,
      si.image_url,
      COALESCE(u.rating, 5.0) AS rating,
      COALESCE(u.review_count, 0) AS rating_count,
      ${haversine} AS distance_km
    FROM public.stockholder_inventory si
    JOIN public.users u ON si.stockholder_id = u.id
    WHERE si.is_available = true
      AND si.quantity_available > 0
    ORDER BY distance_km ASC, si.price_per_unit ASC
    LIMIT $3
  `;

  let rows: any[];
  try {
    const result = await db.query(sql, [shopLat, shopLng, limit]);
    rows = result.rows;
  } catch (dbErr: any) {
    console.error('[assistant] searchAllSuppliers query error:', dbErr?.message ?? dbErr);
    return [];
  }

  const bestPrice = rows.length > 0 ? rows[0].price_per_unit : 0;

  return rows.map((row) => ({
    stockId: row.stock_id,
    stockholderId: row.stockholder_id,
    supplierName: row.supplier_name,
    warehouseAddress: row.warehouse_address,
    productName: row.product_name,
    category: row.category,
    pricePerUnit: row.price_per_unit,
    quantityAvailable: row.quantity_available,
    unit: row.unit,
    imageUrl: row.image_url,
    distanceKm: row.distance_km,
    rating: Number(row.rating) || 5.0,
    ratingCount: Number(row.rating_count) || 0,
    isBestPrice: row.price_per_unit === bestPrice,
  }));
}

// ── Response generation ────────────────────────────────────────────

export function generateGreetingResponse(): string {
  return "Hi there! I'm TradeLink Assistant. Tell me what product you're looking for and I'll find the best suppliers near you.\n\nTry something like:\n• \"Rice\"\n• \"Cheapest oil near me\"\n• \"Medicine within 5 km\"";
}

export function generateSearchResponse(
  intent: AssistantIntent,
  results: AssistantSupplierResult[],
): string {
  if (results.length === 0) {
    if (intent.productName) {
      return `I couldn't find any suppliers for "${intent.productName}" within ${intent.maxDistance} km. Try broadening your search or check back later.`;
    }
    return "I couldn't find matching suppliers. Try specifying a product name like \"Rice\", \"Oil\", or \"Medicine\".";
  }

  const product = intent.productName || 'your product';
  const best = results[0];

  switch (intent.sortBy) {
    case 'distance':
      return `Found ${results.length} supplier${results.length > 1 ? 's' : ''} for "${product}" nearby. Closest is ${best.supplierName} at ${best.distanceKm} km, priced at ৳${best.pricePerUnit}/${best.unit}.`;
    case 'rating':
      return `Found ${results.length} supplier${results.length > 1 ? 's' : ''} for "${product}". Top rated is ${best.supplierName} (${best.rating}★), ৳${best.pricePerUnit}/${best.unit}.`;
    default:
      return `Found ${results.length} supplier${results.length > 1 ? 's' : ''} for "${product}". Best price is ৳${best.pricePerUnit}/${best.unit} at ${best.supplierName}, ${best.distanceKm} km away.`;
  }
}

export function generateUnknownResponse(): string {
  return "I'm not sure what you're looking for. Try asking about a product like \"Rice\" or \"Oil\", or say \"forecast\" to see demand trends.";
}
