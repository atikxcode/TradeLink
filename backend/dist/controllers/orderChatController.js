import { asyncHandler } from '../middleware/asyncHandler.js';
import { db } from '../db/pool.js';
function httpError(message, status) {
    return Object.assign(new Error(message), { status });
}
const ORDER_CHAT_SELECT = `
  SELECT c.id,
         c.order_id,
         c.last_message,
         c.updated_at,
         o.shop_owner_id,
         o.supplier_id,
         o.delivery_man_id,
         COALESCE(ou.business_name, ou.full_name, 'Shop Owner') AS shop_owner_name,
         COALESCE(su.business_name, su.full_name, 'Supplier') AS supplier_name,
         COALESCE(du.full_name, 'Delivery Rider') AS delivery_man_name
  FROM public.order_chats c
  JOIN public.orders o ON o.id = c.order_id
  LEFT JOIN public.users ou ON ou.id = o.shop_owner_id
  LEFT JOIN public.users su ON su.id = o.supplier_id
  LEFT JOIN public.users du ON du.id = o.delivery_man_id
`;
function mapOrderChat(row) {
    return {
        id: row.id,
        orderId: row.order_id,
        lastMessage: row.last_message ?? '',
        updatedAt: row.updated_at?.toISOString?.() ?? String(row.updated_at),
        shopOwnerId: row.shop_owner_id,
        shopOwnerName: row.shop_owner_name,
        supplierId: row.supplier_id,
        supplierName: row.supplier_name,
        deliveryManId: row.delivery_man_id,
        deliveryManName: row.delivery_man_name,
    };
}
/**
 * GET /orders/:orderId/chat/messages
 * Fetches the order chat thread and its messages. Creates the thread if it doesn't exist.
 */
export const getOrderChatMessagesHandler = asyncHandler(async (req, res) => {
    const userId = req.userId;
    const orderId = String(req.params.orderId);
    const client = await db.connect();
    try {
        await client.query('BEGIN');
        // Check if order exists and if user is a participant
        const orderRes = await client.query(`SELECT shop_owner_id, supplier_id, delivery_man_id 
         FROM public.orders WHERE id = $1`, [orderId]);
        const order = orderRes.rows[0];
        if (!order)
            throw httpError('Order not found', 404);
        if (order.shop_owner_id !== userId &&
            order.supplier_id !== userId &&
            order.delivery_man_id !== userId) {
            throw httpError('You are not a participant of this order', 403);
        }
        // Find or create order chat
        let chatRes = await client.query(`${ORDER_CHAT_SELECT} WHERE c.order_id = $1 FOR UPDATE`, [orderId]);
        if (chatRes.rows.length === 0) {
            await client.query(`INSERT INTO public.order_chats (order_id) VALUES ($1)`, [orderId]);
            chatRes = await client.query(`${ORDER_CHAT_SELECT} WHERE c.order_id = $1`, [orderId]);
        }
        const chat = chatRes.rows[0];
        const chatId = chat.id;
        // Fetch messages
        const msgsRes = await client.query(`SELECT m.*, COALESCE(u.business_name, u.full_name, 'User') AS sender_name, u.last_active_at
         FROM public.order_messages m
         LEFT JOIN public.users u ON u.id = m.sender_id
         WHERE m.order_chat_id = $1
         ORDER BY m.created_at ASC`, [chatId]);
        await client.query('COMMIT');
        res.json({
            success: true,
            data: {
                chat: mapOrderChat(chat),
                messages: msgsRes.rows.map((m) => ({
                    id: m.id,
                    senderType: m.sender_type,
                    senderId: m.sender_id,
                    senderName: m.sender_name,
                    textContent: m.text_content,
                    imageUrl: m.image_url,
                    createdAt: m.created_at.toISOString(),
                    lastActiveAt: m.last_active_at ? m.last_active_at.toISOString() : null,
                })),
            },
        });
    }
    catch (err) {
        await client.query('ROLLBACK');
        throw err;
    }
    finally {
        client.release();
    }
});
/**
 * POST /orders/:orderId/chat/messages
 * Appends a message to the order chat and bumps updated_at.
 * Body: { textContent }
 */
export const sendOrderChatMessageHandler = asyncHandler(async (req, res) => {
    const senderId = req.userId;
    const role = (req.role ?? '').toLowerCase();
    let senderType = 'SHOP_OWNER';
    if (role === 'supplier')
        senderType = 'SUPPLIER';
    if (role === 'delivery_man' || role === 'delivery')
        senderType = 'DELIVERY_RIDER';
    const orderId = String(req.params.orderId);
    const { textContent } = req.body;
    const text = textContent?.trim();
    if (!text) {
        res.status(400).json({ success: false, error: 'textContent is required' });
        return;
    }
    const client = await db.connect();
    try {
        await client.query('BEGIN');
        const orderRes = await client.query(`SELECT shop_owner_id, supplier_id, delivery_man_id 
         FROM public.orders WHERE id = $1`, [orderId]);
        const order = orderRes.rows[0];
        if (!order)
            throw httpError('Order not found', 404);
        if (order.shop_owner_id !== senderId &&
            order.supplier_id !== senderId &&
            order.delivery_man_id !== senderId) {
            throw httpError('You are not a participant of this order', 403);
        }
        // Get or create chat
        let chatRes = await client.query(`SELECT id FROM public.order_chats WHERE order_id = $1 FOR UPDATE`, [orderId]);
        let chatId;
        if (chatRes.rows.length === 0) {
            const insertChat = await client.query(`INSERT INTO public.order_chats (order_id) VALUES ($1) RETURNING id`, [orderId]);
            chatId = insertChat.rows[0].id;
        }
        else {
            chatId = chatRes.rows[0].id;
        }
        const inserted = await client.query(`INSERT INTO public.order_messages
           (order_chat_id, sender_type, sender_id, text_content)
         VALUES ($1, $2, $3, $4)
         RETURNING id, created_at`, [chatId, senderType, senderId, text]);
        await client.query(`UPDATE public.order_chats SET last_message = $1, updated_at = now()
         WHERE id = $2`, [text.slice(0, 200), chatId]);
        // Notify other participants
        const otherParticipants = [order.shop_owner_id, order.supplier_id, order.delivery_man_id]
            .filter((id) => id && id !== senderId);
        for (const pId of otherParticipants) {
            await client.query(`INSERT INTO notifications (user_id, title, subtitle, type)
           VALUES ($1, $2, $3, 'order_chat')`, [pId, 'New message in Order Chat', text.slice(0, 80)]);
        }
        await client.query('COMMIT');
        res.status(201).json({
            success: true,
            data: {
                id: inserted.rows[0].id,
                createdAt: inserted.rows[0].created_at.toISOString(),
            },
        });
    }
    catch (err) {
        await client.query('ROLLBACK');
        throw err;
    }
    finally {
        client.release();
    }
});
/**
 * POST /orders/:orderId/chat/messages/image
 * Uploads an image as a message to the order chat.
 * Uses multer for file upload.
 */
export const sendOrderChatImageHandler = asyncHandler(async (req, res) => {
    const senderId = req.userId;
    const role = (req.role ?? '').toLowerCase();
    let senderType = 'SHOP_OWNER';
    if (role === 'supplier')
        senderType = 'SUPPLIER';
    if (role === 'delivery_man' || role === 'delivery')
        senderType = 'DELIVERY_RIDER';
    const orderId = String(req.params.orderId);
    const file = req.file;
    if (!file) {
        res.status(400).json({ success: false, error: 'Image file is required' });
        return;
    }
    const imageUrl = `/uploads/${file.filename}`;
    const client = await db.connect();
    try {
        await client.query('BEGIN');
        const orderRes = await client.query(`SELECT shop_owner_id, supplier_id, delivery_man_id 
         FROM public.orders WHERE id = $1`, [orderId]);
        const order = orderRes.rows[0];
        if (!order)
            throw httpError('Order not found', 404);
        if (order.shop_owner_id !== senderId &&
            order.supplier_id !== senderId &&
            order.delivery_man_id !== senderId) {
            throw httpError('You are not a participant of this order', 403);
        }
        // Get or create chat
        let chatRes = await client.query(`SELECT id FROM public.order_chats WHERE order_id = $1 FOR UPDATE`, [orderId]);
        let chatId;
        if (chatRes.rows.length === 0) {
            const insertChat = await client.query(`INSERT INTO public.order_chats (order_id) VALUES ($1) RETURNING id`, [orderId]);
            chatId = insertChat.rows[0].id;
        }
        else {
            chatId = chatRes.rows[0].id;
        }
        const inserted = await client.query(`INSERT INTO public.order_messages
           (order_chat_id, sender_type, sender_id, image_url)
         VALUES ($1, $2, $3, $4)
         RETURNING id, created_at`, [chatId, senderType, senderId, imageUrl]);
        await client.query(`UPDATE public.order_chats SET last_message = $1, updated_at = now()
         WHERE id = $2`, ['📷 Image', chatId]);
        // Notify other participants
        const otherParticipants = [order.shop_owner_id, order.supplier_id, order.delivery_man_id]
            .filter((id) => id && id !== senderId);
        for (const pId of otherParticipants) {
            await client.query(`INSERT INTO notifications (user_id, title, subtitle, type)
           VALUES ($1, $2, $3, 'order_chat')`, [pId, 'New image in Order Chat', '📷 Image']);
        }
        await client.query('COMMIT');
        res.status(201).json({
            success: true,
            data: {
                id: inserted.rows[0].id,
                createdAt: inserted.rows[0].created_at.toISOString(),
                imageUrl,
            },
        });
    }
    catch (err) {
        await client.query('ROLLBACK');
        throw err;
    }
    finally {
        client.release();
    }
});
//# sourceMappingURL=orderChatController.js.map