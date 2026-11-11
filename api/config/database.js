const sql = require('mssql');

const dbConfig = {
    user: process.env.DB_USER || 'sa',
    password: process.env.DB_PASSWORD || 'YourStrongPassword123!',
    server: process.env.DB_SERVER || 'localhost',
    database: process.env.DB_NAME || 'Keonhanh',
    options: { encrypt: false, trustServerCertificate: true }
};

/// Tự động kiểm tra và đồng bộ cấu trúc bảng (Payments, AiDailyUsage, IsPaid, IsPinned)
async function ensureSchema() {
    try {
        const request = new sql.Request();

        // 1. Kiểm tra và bổ sung cột IsPaid, PaidUntil vào bảng Users
        await request.query(`
            IF COL_LENGTH('dbo.Users', 'IsPaid') IS NULL 
                ALTER TABLE dbo.Users ADD IsPaid BIT DEFAULT 0;
            IF COL_LENGTH('dbo.Users', 'PaidUntil') IS NULL 
                ALTER TABLE dbo.Users ADD PaidUntil DATETIME NULL;
        `);

        // 2. Kiểm tra và bổ sung cột IsPinned vào bảng Matches
        await request.query(`
            IF COL_LENGTH('dbo.Matches', 'IsPinned') IS NULL 
                ALTER TABLE dbo.Matches ADD IsPinned BIT DEFAULT 0;
        `);

        // 3. Kiểm tra và tạo bảng Payments nếu chưa tồn tại
        await request.query(`
            IF OBJECT_ID('dbo.Payments', 'U') IS NULL
            BEGIN
                CREATE TABLE dbo.Payments (
                    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
                    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(Id),
                    OrderCode BIGINT NOT NULL UNIQUE,
                    Amount INT NOT NULL DEFAULT 29000,
                    PackageName NVARCHAR(100) DEFAULT N'Gói Đặc Quyền 1 Tháng',
                    Status NVARCHAR(50) DEFAULT 'PENDING' CHECK (Status IN ('PENDING', 'PAID', 'CANCELLED')),
                    PaymentUrl NVARCHAR(MAX),
                    QrCode NVARCHAR(MAX),
                    CreatedAt DATETIME DEFAULT GETDATE(),
                    PaidAt DATETIME NULL
                );
            END
        `);

        // 4. Kiểm tra và tạo bảng AiDailyUsage nếu chưa tồn tại
        await request.query(`
            IF OBJECT_ID('dbo.AiDailyUsage', 'U') IS NULL
            BEGIN
                CREATE TABLE dbo.AiDailyUsage (
                    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
                    UserId UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES dbo.Users(Id),
                    UsageDate DATE DEFAULT CAST(GETDATE() AS DATE),
                    QuestionCount INT DEFAULT 1,
                    CONSTRAINT UQ_User_Date UNIQUE (UserId, UsageDate)
                );
            END
        `);

        console.log('[Database] Schema đã tự động đồng bộ (Payments, AiDailyUsage, IsPaid, IsPinned).');
    } catch (err) {
        console.error('[Database] Lỗi khi tự động kiểm tra schema:', err.message);
    }
}

async function connectDatabase() {
    try {
        await sql.connect(dbConfig);
        console.log('Connected to SQL Server');
        await ensureSchema();
    } catch (error) {
        console.error('SQL Server connection error:', error);
    }
}

module.exports = { sql, connectDatabase, ensureSchema };
