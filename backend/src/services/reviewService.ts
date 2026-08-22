import { db } from '../db/pool.js';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export interface SubmitReviewInput {
  orderId?: string | null;
  supplierId?: string | null;
  rating: number;
  comment?: string | null;
}

export interface ReviewItem {
  id: string;
  orderId: string | null;
  shopOwnerId: string;
  supplierId: string;
  rating: number;
  comment: string | null;
  createdAt: string;
}

function isValidUuid(v: string | null | undefined): boolean {
  return !!v && UUID_RE.test(v);
}

/**
 * Submit a review for a completed order.
 * - orderId is optional (old notifications may not have it).
 * - supplierId is required; if missing, looks it up from the order.
 * - Uses ON CONFLICT so a second submission updates the existing review.
 */
export async function submitReview(
  shopOwnerId: string,
  input: SubmitReviewInput,
): Promise<ReviewItem> {
  const { rating, comment } = input;
  let orderId = input.orderId && isValidUuid(input.orderId) ? input.orderId : null;
  let supplierId = input.supplierId && isValidUuid(input.supplierId) ? input.supplierId : null;

  const client = await db.connect();
  try {
    await client.query('BEGIN');

    // If supplierId is missing, try to look it up from the order
    if (!supplierId && orderId) {
      const { rows } = await client.query(
        'SELECT supplier_id FROM public.orders WHERE id = $1',
        [orderId],
      );
      if (rows.length > 0 && rows[0].supplier_id) {
        supplierId = rows[0].supplier_id;
      }
    }

    if (!supplierId) {
      throw Object.assign(new Error('Could not determine supplier. Please try again.'), { status: 400 });
    }

    // Validate shopOwnerId exists
    const ownerCheck = await client.query('SELECT id FROM public.users WHERE id = $1', [shopOwnerId]);
    if (ownerCheck.rows.length === 0) {
      throw Object.assign(new Error('Shop owner not found'), { status: 400 });
    }

    // Validate supplierId exists
    const supplierCheck = await client.query('SELECT id FROM public.users WHERE id = $1', [supplierId]);
    if (supplierCheck.rows.length === 0) {
      throw Object.assign(new Error('Supplier not found'), { status: 400 });
    }

    let result;
    if (orderId) {
      // Validate order exists
      const orderCheck = await client.query('SELECT id FROM public.orders WHERE id = $1', [orderId]);
      if (orderCheck.rows.length === 0) {
        orderId = null; // Order doesn't exist, insert without it
      }
    }

    if (orderId) {
      result = await client.query(
        `INSERT INTO public.ratings (order_id, shop_owner_id, supplier_id, rating, review)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (order_id) DO UPDATE
           SET rating = EXCLUDED.rating,
               review = EXCLUDED.review,
               supplier_id = EXCLUDED.supplier_id
         RETURNING id, order_id, shop_owner_id, supplier_id, rating, review, created_at`,
        [orderId, shopOwnerId, supplierId, rating, comment ?? null],
      );
    } else {
      // No valid orderId — insert without it (order_id is nullable)
      result = await client.query(
        `INSERT INTO public.ratings (order_id, shop_owner_id, supplier_id, rating, review)
         VALUES (NULL, $1, $2, $3, $4)
         RETURNING id, order_id, shop_owner_id, supplier_id, rating, review, created_at`,
        [shopOwnerId, supplierId, rating, comment ?? null],
      );
    }

    await client.query('COMMIT');

    const row = result.rows[0];
    return {
      id: row.id,
      orderId: row.order_id,
      shopOwnerId: row.shop_owner_id,
      supplierId: row.supplier_id,
      rating: Number(row.rating),
      comment: row.review,
      createdAt: row.created_at.toISOString(),
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * Resolve order + supplier from product name for a shop owner.
 * Used when notification metadata is missing (old notifications).
 */
export async function resolveOrderForReview(
  shopOwnerId: string,
  productName: string,
): Promise<{ orderId: string; supplierId: string } | null> {
  const { rows } = await db.query(
    `SELECT id AS order_id, supplier_id
     FROM public.orders
     WHERE shop_owner_id = $1
       AND LOWER(product_name) LIKE LOWER($2)
       AND status = 'delivered'
     ORDER BY created_at DESC
     LIMIT 1`,
    [shopOwnerId, `%${productName}%`],
  );
  if (rows.length === 0) return null;
  return { orderId: rows[0].order_id, supplierId: rows[0].supplier_id };
}

/**
 * Get average rating and review count for a supplier.
 */
export async function getSupplierRating(
  supplierId: string,
): Promise<{ rating: number; reviewCount: number }> {
  const { rows } = await db.query(
    `SELECT
       COALESCE(ROUND(AVG(rating)::numeric, 1), 5.0) AS avg_rating,
       COUNT(*)::int AS review_count
     FROM public.ratings
     WHERE supplier_id = $1`,
    [supplierId],
  );
  return {
    rating: Number(rows[0]?.avg_rating ?? 5.0),
    reviewCount: rows[0]?.review_count ?? 0,
  };
}
