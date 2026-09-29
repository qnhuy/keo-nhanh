const sql = require('mssql');

const dbConfig = {
    user: process.env.DB_USER || 'sa',
    password: process.env.DB_PASSWORD || 'YourStrongPassword123!',
    server: process.env.DB_SERVER || 'localhost',
    database: process.env.DB_NAME || 'Keonhanh',
    options: { encrypt: false, trustServerCertificate: true }
};

async function connectDatabase() {
    try {
        await sql.connect(dbConfig);
        console.log('Connected to SQL Server');
    } catch (error) {
        console.error('SQL Server connection error:', error);
    }
}

module.exports = { sql, connectDatabase };
