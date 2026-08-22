import { db } from '../db/pool.js';

export interface PendingOrderRow {
  order_id: string;
  delivery_otp: string | null;
  order_status: string;
  order_time: Date;
  product_name: string;
  quantity: number;
  unit: string;
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
    quantity: row.quantity,
    unit: row.unit,
    deliveryLocation: row.delivery_location,
    shopOwnerName: row.shop_owner_name,
    shopOwnerPhone: row.shop_owner_phone,
  };
}

/**
 * Fetch pending orders (accepted / in_transit) for the logged-in stockholder.
 *
 * The query joins orders → demands → users and LEFT JOINs otps to surface
 * the delivery OTP when one has been generated.
 */
export async function getPendingOrders(
  stockholderId: string,
): Promise<PendingOrderDto[]> {
  const { rows } = await db.query<PendingOrderRow>(
    `SELECT
       o.id                                       AS order_id,
       ot.otp_code                                AS delivery_otp,
       o.status                                   AS order_status,
       o.created_at                               AS order_time,
       d.product_name,
       o.quantity,
       o.unit,
       COALESCE(d.delivery_address, o.delivery_address) AS delivery_location,
       u.full_name                                AS shop_owner_name,
       u.phone_number                             AS shop_owner_phone
     FROM public.orders o
     JOIN public.demands d ON o.demand_id = d.id
     JOIN public.users  u ON d.shop_owner_id = u.id
     LEFT JOIN public.otps ot ON ot.order_id = o.id
     WHERE o.supplier_id = $1
       AND o.status IN ('accepted', 'in_transit')
     ORDER BY o.created_at DESC`,
    [stockholderId],
  );

  return rows.map(mapPendingOrderRow);
}
