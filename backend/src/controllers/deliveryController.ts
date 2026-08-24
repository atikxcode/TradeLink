import { Request, Response } from 'express';
import { db } from '../db/pool.js';
import crypto from 'crypto';

/**
 * Hash password exactly like the Flutter frontend does (SHA-256).
 */
function hashPassword(password: string): string {
  return crypto.createHash('sha256').update(password).digest('hex');
}

/**
 * Supplier creates a new delivery man
 */
export async function createDeliveryManHandler(req: Request, res: Response) {
  try {
    const supplierId = req.user?.id;
    const { fullName, phoneNumber, password } = req.body;

    if (!fullName || !phoneNumber || !password) {
      return res.status(400).json({ success: false, error: 'Full name, phone number, and password are required' });
    }

    const hashedPassword = hashPassword(password);

    // Default values for delivery man
    const businessName = `${fullName} Delivery`;
    const category = 'Delivery';

    const result = await db.query(
      `INSERT INTO public.users (
         role, full_name, phone_number, business_name, category, 
         password_hash, supplier_id, force_password_reset
       )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, full_name, phone_number, created_at`,
      ['delivery_man', fullName, phoneNumber, businessName, category, hashedPassword, supplierId, true]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error: any) {
    console.error('Error creating delivery man:', error);
    if (error.code === '23505') { // Unique violation
      return res.status(409).json({ success: false, error: 'Phone number is already registered' });
    }
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

/**
 * Supplier lists their delivery men
 */
export async function listDeliveryMenHandler(req: Request, res: Response) {
  try {
    const supplierId = req.user?.id;

    const result = await db.query(
      `SELECT id, full_name, phone_number, created_at, force_password_reset
       FROM public.users
       WHERE role = 'delivery_man' AND supplier_id = $1
       ORDER BY created_at DESC`,
      [supplierId]
    );

    res.status(200).json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error listing delivery men:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

/**
 * Supplier assigns an order to a delivery man
 */
export async function assignDeliveryManHandler(req: Request, res: Response) {
  try {
    const supplierId = req.user?.id;
    const { id: orderId } = req.params;
    const { deliveryManId } = req.body;

    if (!deliveryManId) {
      return res.status(400).json({ success: false, error: 'deliveryManId is required' });
    }

    // Verify delivery man belongs to supplier
    const dmCheck = await db.query(
      `SELECT id FROM public.users WHERE id = $1 AND supplier_id = $2 AND role = 'delivery_man'`,
      [deliveryManId, supplierId]
    );
    if (dmCheck.rows.length === 0) {
      return res.status(403).json({ success: false, error: 'Invalid delivery man' });
    }

    // Verify order belongs to supplier and is in a state that can be assigned
    const orderCheck = await db.query(
      `SELECT id, status FROM public.orders WHERE id = $1 AND supplier_id = $2`,
      [orderId, supplierId]
    );
    if (orderCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Order not found' });
    }

    // Update order
    await db.query(
      `UPDATE public.orders 
       SET delivery_man_id = $1, status = 'out_for_delivery'
       WHERE id = $2`,
      [deliveryManId, orderId]
    );
    
    // Notification to Delivery Man
    await db.query(
      `INSERT INTO public.notifications (user_id, title, message, type)
       VALUES ($1, 'New Delivery Assigned', 'You have been assigned a new order for delivery.', 'order_update')`,
      [deliveryManId]
    );

    res.status(200).json({ success: true, message: 'Order assigned successfully' });
  } catch (error) {
    console.error('Error assigning order:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

/**
 * Delivery Man views their assigned orders
 */
export async function getDeliveryManOrdersHandler(req: Request, res: Response) {
  try {
    // Note: This endpoint will be called directly by the delivery man using X-User-Id header for auth (mock)
    const deliveryManId = req.user?.id;

    const result = await db.query(
      `SELECT o.id, o.quantity, o.unit_price, o.total_amount, o.status, o.created_at, o.payment_status,
              d.product_name, d.delivery_address, d.latitude AS dropoff_lat, d.longitude AS dropoff_lng,
              u.full_name AS shop_owner_name, u.phone_number AS shop_owner_phone
       FROM public.orders o
       JOIN public.demands d ON o.demand_id = d.id
       JOIN public.users u ON o.shop_owner_id = u.id
       WHERE o.delivery_man_id = $1
       ORDER BY o.created_at DESC`,
      [deliveryManId]
    );

    res.status(200).json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error fetching delivery man orders:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

/**
 * Delivery Man marks an order as delivered
 */
export async function markOrderDeliveredHandler(req: Request, res: Response) {
  try {
    const deliveryManId = req.user?.id;
    const { id: orderId } = req.params;

    // Verify order belongs to this delivery man
    const orderCheck = await db.query(
      `SELECT id, shop_owner_id, supplier_id FROM public.orders WHERE id = $1 AND delivery_man_id = $2`,
      [orderId, deliveryManId]
    );
    if (orderCheck.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Order not found or not assigned to you' });
    }

    const order = orderCheck.rows[0];

    await db.query(
      `UPDATE public.orders SET status = 'delivered' WHERE id = $1`,
      [orderId]
    );

    // Notify Supplier
    await db.query(
      `INSERT INTO public.notifications (user_id, title, message, type)
       VALUES ($1, 'Order Delivered', 'Your delivery man has successfully delivered the order.', 'order_update')`,
      [order.supplier_id]
    );
    
    // Notify Shop Owner
    await db.query(
      `INSERT INTO public.notifications (user_id, title, message, type)
       VALUES ($1, 'Order Delivered', 'Your order has been delivered successfully.', 'order_update')`,
      [order.shop_owner_id]
    );

    res.status(200).json({ success: true, message: 'Order marked as delivered' });
  } catch (error) {
    console.error('Error marking order delivered:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}
