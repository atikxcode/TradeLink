import { describe, it, expect } from 'vitest';
import { parseId, createStockSchema } from '../src/middleware/validation.js';

describe('parseId - White Box Path Coverage', () => {
  const validUuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

  describe('Path 1: Valid UUID input', () => {
    it('returns the same UUID string', () => {
      expect(parseId(validUuid)).toBe(validUuid);
    });

    it('accepts uppercase UUID', () => {
      const upper = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
      expect(parseId(upper)).toBe(upper);
    });

    it('accepts mixed-case UUID', () => {
      const mixed = 'a1B2c3D4-e5F6-7890-abCD-ef1234567890';
      expect(parseId(mixed)).toBe(mixed);
    });
  });

  describe('Path 2: Undefined id', () => {
    it('throws error with default name "id"', () => {
      expect(() => parseId(undefined)).toThrow('Invalid id');
    });

    it('throws error with custom name', () => {
      expect(() => parseId(undefined, 'userId')).toThrow('Invalid userId');
    });

    it('error has status 400', () => {
      try {
        parseId(undefined);
      } catch (e: any) {
        expect(e.status).toBe(400);
      }
    });
  });

  describe('Path 3: Invalid UUID format', () => {
    it('throws for empty string', () => {
      expect(() => parseId('')).toThrow('Invalid id');
    });

    it('throws for random string', () => {
      expect(() => parseId('not-a-uuid')).toThrow('Invalid id');
    });

    it('throws for UUID without dashes', () => {
      expect(() => parseId('a1b2c3d4e5f67890abcdef1234567890')).toThrow('Invalid id');
    });

    it('throws for too-short UUID', () => {
      expect(() => parseId('a1b2c3d4-e5f6-7890')).toThrow('Invalid id');
    });

    it('throws for UUID with invalid chars', () => {
      expect(() => parseId('g1b2c3d4-e5f6-7890-abcd-ef1234567890')).toThrow('Invalid id');
    });
  });
});

describe('createStockSchema - Black Box Boundary Value Analysis', () => {
  const validPayload = {
    customProductName: 'Rice',
    category: 'Grocery',
    quantity: 100,
    unit: 'kg',
    pricePerUnit: 50,
  };

  describe('Valid inputs', () => {
    it('accepts minimal valid payload', () => {
      const result = createStockSchema.safeParse(validPayload);
      expect(result.success).toBe(true);
    });

    it('accepts payload with all optional fields', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        masterProductId: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        imageUrl: 'https://example.com/img.jpg',
        deliveryRadiusKm: 25,
      });
      expect(result.success).toBe(true);
    });
  });

  describe('customProductName validation', () => {
    it('rejects empty string', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        customProductName: '',
      });
      expect(result.success).toBe(false);
    });

    it('rejects whitespace-only string', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        customProductName: '   ',
      });
      expect(result.success).toBe(false);
    });

    it('accepts single character', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        customProductName: 'A',
      });
      expect(result.success).toBe(true);
    });

    it('rejects 256 characters', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        customProductName: 'A'.repeat(256),
      });
      expect(result.success).toBe(false);
    });

    it('accepts 200 characters', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        customProductName: 'A'.repeat(200),
      });
      expect(result.success).toBe(true);
    });
  });

  describe('category validation', () => {
    it.each(['Grocery', 'Pharmacy', 'Stationery', 'Hardware'])(
      'accepts valid category: %s',
      (cat) => {
        const result = createStockSchema.safeParse({
          ...validPayload,
          category: cat,
        });
        expect(result.success).toBe(true);
      },
    );

    it('rejects invalid category', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        category: 'Electronics',
      });
      expect(result.success).toBe(false);
    });

    it('rejects empty category', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        category: '',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('quantity validation (boundary values)', () => {
    it('rejects 0', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        quantity: 0,
      });
      expect(result.success).toBe(false);
    });

    it('rejects negative', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        quantity: -1,
      });
      expect(result.success).toBe(false);
    });

    it('accepts 1 (min valid)', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        quantity: 1,
      });
      expect(result.success).toBe(true);
    });

    it('accepts 1,000,000 (max valid)', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        quantity: 1_000_000,
      });
      expect(result.success).toBe(true);
    });

    it('rejects 1,000,001 (above max)', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        quantity: 1_000_001,
      });
      expect(result.success).toBe(false);
    });

    it('rejects non-number', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        quantity: 'abc',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('unit validation', () => {
    it.each(['kg', 'litre', 'pcs'])('accepts valid unit: %s', (unit) => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        unit,
      });
      expect(result.success).toBe(true);
    });

    it('rejects invalid unit', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        unit: 'tonnes',
      });
      expect(result.success).toBe(false);
    });
  });

  describe('pricePerUnit validation', () => {
    it('accepts 0 (free)', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        pricePerUnit: 0,
      });
      expect(result.success).toBe(true);
    });

    it('rejects negative price', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        pricePerUnit: -1,
      });
      expect(result.success).toBe(false);
    });

    it('accepts 1,000,000 (max)', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        pricePerUnit: 1_000_000,
      });
      expect(result.success).toBe(true);
    });

    it('rejects 1,000,001 (above max)', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        pricePerUnit: 1_000_001,
      });
      expect(result.success).toBe(false);
    });
  });

  describe('imageUrl validation', () => {
    it('accepts valid URL', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        imageUrl: 'https://example.com/image.png',
      });
      expect(result.success).toBe(true);
    });

    it('rejects invalid URL', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        imageUrl: 'not-a-url',
      });
      expect(result.success).toBe(false);
    });

    it('accepts omitted imageUrl', () => {
      const result = createStockSchema.safeParse(validPayload);
      expect(result.success).toBe(true);
    });
  });

  describe('deliveryRadiusKm validation', () => {
    it('accepts default value (10) when omitted', () => {
      const result = createStockSchema.safeParse(validPayload);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.deliveryRadiusKm).toBe(10);
      }
    });

    it('accepts 1 (min)', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        deliveryRadiusKm: 1,
      });
      expect(result.success).toBe(true);
    });

    it('accepts 100 (max)', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        deliveryRadiusKm: 100,
      });
      expect(result.success).toBe(true);
    });

    it('rejects 0 (below min)', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        deliveryRadiusKm: 0,
      });
      expect(result.success).toBe(false);
    });

    it('rejects 101 (above max)', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        deliveryRadiusKm: 101,
      });
      expect(result.success).toBe(false);
    });

    it('rejects non-integer', () => {
      const result = createStockSchema.safeParse({
        ...validPayload,
        deliveryRadiusKm: 10.5,
      });
      expect(result.success).toBe(false);
    });
  });
});
