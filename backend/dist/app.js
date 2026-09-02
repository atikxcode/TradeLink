import cors from 'cors';
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { requireAuth } from './middleware/auth.js';
import stockholderRoutes from './routes/stockholder.routes.js';
import stockImageRoutes from './routes/image.routes.js';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const app = express();
app.set('trust proxy', 1);
app.use(cors({ origin: true }));
app.use(express.json());
const API_VERSION = '2026-08-26.1';
app.get('/health', (_req, res) => {
    res.json({ success: true, message: 'TradeLink API is running', version: API_VERSION, ts: Date.now() });
});
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));
// Public image endpoint — must stay outside requireAuth (Image.network
// sends no auth headers). Backed by Postgres, survives restarts.
app.use('/stock-images', stockImageRoutes);
app.use('/api/v1', requireAuth, stockholderRoutes);
// Serve Flutter web build
const webDir = path.join(__dirname, '..', 'web');
app.use(express.static(webDir));
// SPA fallback — serve index.html for non-API, non-file routes
app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api/') || req.path.startsWith('/uploads') || req.path.startsWith('/stock-images')) {
        return next();
    }
    res.sendFile(path.join(webDir, 'index.html'));
});
// 404 handler for API routes
app.use((_req, res) => {
    res.status(404).json({ success: false, error: 'Route not found' });
});
// Central error handler
app.use((err, _req, res, _next) => {
    const error = err;
    if (error instanceof SyntaxError) {
        res.status(400).json({ success: false, error: 'Invalid JSON body' });
        return;
    }
    const zodError = error;
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
//# sourceMappingURL=app.js.map