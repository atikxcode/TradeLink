import { db } from '../db/pool.js';

export interface PendingOrderRow {
  order_id: string;
  delivery_otp: string | null;
  order_status: string;
  order_time: Date;
  product_name: string;
  quantity: number;
  unit: string;
  total_amount: number;
  delivery_location: string | null;
  shop_owner_name: string;
  shop_owner_phone: string;
}

export interface PendingOrderDto {
  orderId: string;
  deliveryOtp: string | null;
  orderStatus: string;
  orderTime: string;
  productName: string;
  quantity: number;
  unit: string;
  totalAmount: number;
  deliveryLocation: string | null;
  shopOwnerName: string;
  shopOwnerPhone: string;
}

function mapPendingOrderRow(row: PendingOrderRow): PendingOrderDto {
  return {
    orderId: row.order_id,
    deliveryOtp: row.delivery_otp,
    orderStatus: row.order_status,
    orderTime: row.order_time.toISOString(),
    productName: row.product_name,
    quantity: Number(row.quantity),
    unit: row.unit,
    totalAmount: Number(row.total_amount),
    deliveryLocation: row.delivery_location,
    shopOwnerName: row.shop_owner_name,
    shopOwnerPhone: row.shop_owner_phone,
  };
}

/**
 * Fetch orders for the logged-in supplier.
 * Handles both direct orders (no demand_id) and demand-based orders.
 * Returns orders in: pending, accepted, out_for_delivery, in_transit statuses.
 */
export async function getPendingOrders(
  stockholderId: string,
): Promise<PendingOrderDto[]> {
  const { rows } = await db.query<PendingOrderRow>(
    `SELECT
       o.id                                       AS order_id,
       o.delivery_otp                             AS delivery_otp,
       o.status                                   AS order_status,
       o.created_at                               AS order_time,
       o.product_name,
       o.quantity,
       o.unit,
       o.total_amount,
       COALESCE(o.delivery_address, '')           AS delivery_location,
       COALESCE(u.full_name, 'Unknown')           AS shop_owner_name,
       COALESCE(u.phone_number, '')               AS shop_owner_phone
     FROM public.orders o
     JOIN public.users u ON o.shop_owner_id = u.id
     WHERE o.supplier_id = $1
       AND o.status IN ('pending', 'accepted', 'out_for_delivery', 'in_transit')
     ORDER BY
       CASE o.status
         WHEN 'pending' THEN 0
         WHEN 'accepted' THEN 1
         WHEN 'out_for_delivery' THEN 2
         WHEN 'in_transit' THEN 3
       END,
       o.created_at DESC`,
    [stockholderId],
  );

  return rows.map(mapPendingOrderRow);
}
