import cors from 'cors';
import express, { type NextFunction, type Request, type Response } from 'express';
import { env } from './config/env.js';
import { requireAuth } from './middleware/auth.js';
import stockholderRoutes from './routes/stockholder.routes.js';

export const app = express();

app.use(cors({ origin: env.corsOrigins }));
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ success: true, message: 'TradeLink API is running' });
});

app.use('/api/v1', requireAuth, stockholderRoutes);

// 404 handler
app.use((_req, res) => {
  res.status(404).json({ success: false, error: 'Route not found' });
});

// Central error handler
app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  const error = err as Error & { status?: number };

  if (error instanceof SyntaxError) {
    res.status(400).json({ success: false, error: 'Invalid JSON body' });
    return;
  }

  const zodError = error as unknown as { name?: string; issues?: unknown[] };
  if (zodError.name === 'ZodError') {
    res.status(400).json({ success: false, error: 'Validation failed', details: zodError.issues });
    return;
  }

  const status = error.status ?? 500;
  if (status >= 500) {
    console.error('[api] unexpected error:', error);
  }
  res.status(status).json({ success: false, error: error.message ?? 'Internal server error' });
});