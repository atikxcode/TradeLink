// Shared API DTOs. Field names mirror the Flutter client models so the
// frontend can deserialize responses without mapping.

export type UserRole = 'shop_owner' | 'supplier';

export interface StockItem {
  id: string;
  userId: string;
  productId: string | null;
  category: string;
  productName: string;
  quantity: number;
  unit: string;
  pricePerUnit: number;
  isAvailable: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface NearbyDemand {
  id: string;
  shopOwnerId: string;
  productName: string;
  category: string;
  quantity: number;
  unit: string;
  notes: string | null;
  status: DemandStatus;
  createdAt: string;
}

export type DemandStatus =
  | 'pending'
  | 'accepted'
  | 'delivered'
  | 'cancelled';

export interface OrderItem {
  id: string;
  demandId: string | null;
  shopOwnerId: string;
  supplierId: string;
  productName: string;
  quantity: number;
  unit: string;
  totalAmount: number;
  status: OrderStatus;
  deliveryAddress: string | null;
  createdAt: string;
}

export type OrderStatus =
  | 'pending'
  | 'accepted'
  | 'in_transit'
  | 'delivered'
  | 'cancelled';

export interface NotificationItem {
  id: string;
  userId: string;
  title: string;
  subtitle: string;
  type: string;
  isRead: boolean;
  createdAt: string;
}

// ----- Request payloads -----

export interface CreateStockPayload {
  category: string;
  productName: string;
  quantity: number;
  unit: string;
  pricePerUnit: number;
}

export interface HomeStatsResponse {
  newDemandsCount: number;
  pendingOrdersCount: number;
  stockItemsCount: number;
  nearbyDemands: NearbyDemand[];
}

export interface AcceptDemandResponse {
  order: OrderItem;
  deliveryOtp: string;
  demandId: string;
  message: string;
}