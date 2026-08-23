import 'dotenv/config';
export const env = {
    port: Number(process.env.PORT ?? 8081),
    databaseUrl: process.env.DATABASE_URL ??
        'postgresql://postgres:password@localhost:5432/tradelink',
    jwtSecret: process.env.JWT_SECRET ?? '',
    authProvider: process.env.AUTH_PROVIDER ?? 'supabase',
    // Demo (X-User-Id header) auth is the default until Supabase-JWT
    // login ships in the Flutter client. Override with DEMO_MODE=false.
    demoMode: (process.env.DEMO_MODE ?? 'true').toLowerCase() === 'true',
    corsOrigins: (process.env.CORS_ORIGINS ?? 'http://localhost:8080')
        .split(',')
        .map((o) => o.trim()),
};
//# sourceMappingURL=env.js.map