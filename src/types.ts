/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export interface AppUser {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  role: 'director' | 'employee';
  password?: string;
  createdAt: string;
  telegramId?: number;
  telegramUsername?: string;
}

export type OrderStatus = 'new' | 'measurement' | 'production' | 'delivery' | 'completed' | 'cancelled';
export type ProductionStage = 'frame' | 'foam' | 'upholstery' | 'assembly' | 'ready';

export interface CostBreakdown {
  woodSheetsCount: number;
  woodSheetPrice: number;
  edgeMeters: number;
  edgePrice: number;
  fittingsCost: number;
  laborCost: number;
  overheadCost: number;
}

export interface Order {
  id: string;
  clientName: string;
  clientPhone: string;
  productType: string;
  material: string;
  dimensions: string;
  price: number;
  paidAmount: number;
  status: OrderStatus;
  productionStage?: ProductionStage;
  createdAt: string;
  deliveryDate: string;
  notes?: string;
  measurementId?: string;
  employeeId?: string;
  costBreakdown?: CostBreakdown;
  clientIin?: string;
  contractWarrantyMonths?: number;
  contractTermsDays?: number;
  contractSeller?: string;
}

export interface Client {
  id: string;
  name: string;
  phone: string;
  email?: string;
  address: string;
  totalOrders: number;
  totalSpent: number;
  createdAt: string;
  notes?: string;
}

export interface Product {
  id: string;
  name: string;
  category: 'sofa' | 'table' | 'chair' | 'bed' | 'wardrobe' | 'custom';
  basePrice: number;
  description: string;
  materials: string[];
}

export interface InventoryItem {
  id: string;
  name: string;
  category: 'material' | 'wood' | 'foam' | 'hardware' | 'accessories';
  quantity: number;
  unit: string;
  minQuantity: number;
  costPerUnit: number;
}

export interface Employee {
  id: string;
  name: string;
  role: 'carpenter' | 'upholsterer' | 'designer' | 'measurer' | 'courier' | 'manager';
  phone: string;
  activeTasks: number;
  completedTasks: number;
  totalBonuses: number;
}

export interface Measurement {
  id: string;
  clientName: string;
  phone: string;
  address: string;
  date: string;
  status: 'pending' | 'completed';
  notes: string;
  width?: number;
  depth?: number;
  height?: number;
  roomType?: string;
  obstacles?: string[];
  angle90?: boolean;
}
