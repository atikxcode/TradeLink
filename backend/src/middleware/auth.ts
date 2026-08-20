import { createHmac, timingSafeEqual } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';
import { env } from '../config/env.js';

export interface AuthRequest extends Request {
  userId?: string;
  role?: 'stockholder' | 'shop_owner';
}

const ROLE_DELIMITER = '::';

/**
 * Authenticates the caller and attaches `userId` + `role` to the request.
 *
 * - Supabase mode: expects `Authorization: Bearer <JWT>` and verifies the
 *   signature with the Supabase JWT secret, then derives the role from the
 *   token's `app_metadata.role` or `user_metadata.role`.
 * - Dev mode: accepts a plain `X-User-Id` header (no DB / auth required).
 */
export function requireAuth(
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): void {
  if (env.demoMode) {
    const headerId = req.header('X-User-Id');
    if (!headerId) {
      res.status(401).json({ error: 'X-User-Id header required in demo mode' });
      return;
    }
    const [userId, role] = headerId.split(ROLE_DELIMITER);
    req.userId = userId;
    req.role = role === 'shop_owner' ? 'shop_owner' : 'stockholder';
    next();
    return;
  }

  const token = req.header('Authorization')?.replace(/^Bearer\s+/i, '');
  if (!token) {
    res.status(401).json({ error: 'Missing bearer token' });
    return;
  }

  try {
    const payload = verifyJwt(token);
    req.userId = payload.sub as string;
    const meta = payload.app_metadata ?? payload.user_metadata ?? {};
    req.role =
      meta.role === 'shop_owner' || meta.role === 'stockholder'
        ? meta.role
        : 'stockholder';
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

/** Require the authenticated user to be a stockholder. */
export function requireStockholder(
  req: AuthRequest,
  res: Response,
  next: NextFunction,
): void {
  if (req.role !== 'stockholder') {
    res.status(403).json({ error: 'Stockholder role required' });
    return;
  }
  next();
}

interface JwtPayload {
  sub?: string;
  app_metadata?: { role?: string };
  user_metadata?: { role?: string };
}

function verifyJwt(token: string): JwtPayload {
  if (!env.jwtSecret) {
    throw new Error('JWT_SECRET not configured');
  }
  const [header, payload, signature] = token.split('.');
  if (!header || !payload || !signature) {
    throw new Error('Malformed token');
  }

  const expected = createHmac('sha256', env.jwtSecret)
    .update(`${header}.${payload}`)
    .digest();
  const provided = base64UrlToBytes(signature);

  if (!timingSafeEqual(expected, provided)) {
    throw new Error('Signature mismatch');
  }

  return JSON.parse(base64UrlToString(payload)) as JwtPayload;
}

function base64UrlToString(value: string): string {
  const base64 = value.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64.padEnd(base64.length + ((4 - (base64.length % 4)) % 4), '=');
  return Buffer.from(padded, 'base64').toString('utf8');
}

function base64UrlToBytes(value: string): Buffer {
  const base64 = value.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64.padEnd(base64.length + ((4 - (base64.length % 4)) % 4), '=');
  return Buffer.from(padded, 'base64');
}