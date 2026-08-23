import 'dotenv/config';
export const env = {
    port: Number(process.env.PORT ?? 8081),
    databaseUrl: process.env.DATABASE_URL ??
        'postgresql://postgres:password@localhost:5432/tradelink',
    jwtSecret: process.env.JWT_SECRET ?? '',
    authProvider: process.env.AUTH_PROVIDER ?? 'supabase',
    demoMode: (process.env.DEMO_MODE ?? 'false').toLowerCase() === 'true',
    corsOrigins: (process.env.CORS_ORIGINS ?? 'http://localhost:8080')
        .split(',')
        .map((o) => o.trim()),
};
//# sourceMappingURL=env.js.map