// Shared API DTOs. Field names mirror the Flutter client models so the
// frontend can deserialize responses without mapping.

export interface StockItem {
  id: string;
  stockholderId: string;
  category: string;
  productName: string;
  quantityAvailable: number;
  unit: string;
  pricePerUnit: number;
  serviceRadiusKm: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface NearbyDemand {
  id: string;
  shopOwnerId: string;
  productName: string;
  quantity: number;
  unit: string;
  deliveryLocation: string | null;
  notes: string | null;
  status: DemandStatus;
  distanceKm: number | null;
  createdAt: string;
}

export type DemandStatus =
  | 'pending'
  | 'accepted'
  | 'declined'
  | 'completed';

export interface OrderItem {
  id: string;
  demandId: string;
  stockholderId: string;
  shopOwnerId: string;
  deliveryOtp: string;
  status: OrderStatus;
  createdAt: string;
}

export type OrderStatus =
  | 'accepted'
  | 'out_for_delivery'
  | 'delivered'
  | 'cancelled';

export interface NotificationItem {
  id: string;
  recipientId: string;
  recipientRole: 'stockholder' | 'shop_owner';
  title: string;
  message: string;
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
  serviceRadiusKm?: number;
}

export interface HomeStatsResponse {
  newDemandsCount: number;
  pendingOrdersCount: number;
  stockItemsCount: number;
  nearbyDemands: NearbyDemand[];
}

export interface AcceptDemandResponse {
  order: OrderItem;
  demandId: string;
  message: string;
}