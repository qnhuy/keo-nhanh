module.exports = function registerRoutes({ app, sql, bcrypt, jwt, JWT_SECRET }) {

app.post('/auth/register', async (req, res) => {
    try {
        const { username, password } = req.body;
        const hash = await bcrypt.hash(password, 10);
        
        const request = new sql.Request();
        request.input('user', sql.NVarChar, username);
        const check = await request.query("SELECT * FROM Users WHERE Username = @user");
        if (check.recordset.length > 0) return res.status(400).json({ success: false, message: 'Tài khoản đã tồn tại' });

        request.input('pass', sql.NVarChar, hash);
        await request.query("INSERT INTO Users (Username, Password) VALUES (@user, @pass)");
        res.json({ success: true, message: 'Đăng ký thành công' });
    } catch (e) {
        console.error(e);
        res.status(500).json({ success: false, message: 'Lỗi server' });
    }
});

app.post('/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        const request = new sql.Request();
        request.input('user', sql.NVarChar, username);
        const result = await request.query("SELECT * FROM Users WHERE Username = @user");
        
        if (result.recordset.length === 0) return res.status(401).json({ success: false, message: 'Sai tài khoản' });
        
        const user = result.recordset[0];
        const match = await bcrypt.compare(password, user.Password);
        if (!match) return res.status(401).json({ success: false, message: 'Sai mật khẩu' });

        const token = jwt.sign({ id: user.Id }, JWT_SECRET);
        res.json({
            success: true,
            token,
            user: { id: user.Id, username: user.Username, role: user.Role }
        });
    } catch (e) {
        console.error(e);
        res.status(500).json({ success: false, message: 'Lỗi server' });
    }
});

// --- USER PROFILES ---

};
