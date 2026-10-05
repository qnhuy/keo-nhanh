module.exports = function registerRoutes({ app, sql, bcrypt, jwt, JWT_SECRET }) {

app.get('/user-profiles/:userId', async (req, res) => {
    try {
        const request = new sql.Request();
        request.input('userId', sql.UniqueIdentifier, req.params.userId);
        const result = await request.query("SELECT * FROM User_profiles WHERE UserId = @userId");
        if (result.recordset.length > 0) {
            let record = result.recordset[0];
            let profile = {
                _id: record.Id,
                userId: record.UserId,
                phone: record.Phone,
                avatar: record.Avatar,
                fullName: record.FullName,
                position: record.Position,
                location: record.Location,
                isLookingForTeam: record.IsLookingForTeam
            };
            res.json({ success: true, profile });
        } else {
            res.json({ success: false, message: 'Chưa có profile' });
        }
    } catch (e) {
        res.status(500).json({ success: false, message: 'Lỗi server' });
    }
});

app.post('/user-profiles', async (req, res) => {
    try {
        const p = req.body;
        const request = new sql.Request();
        request.input('userId', sql.UniqueIdentifier, p.userId);
        request.input('phone', sql.NVarChar, p.phone);
        request.input('avatar', sql.NVarChar, p.avatar || '');
        request.input('fullName', sql.NVarChar, p.fullName);
        request.input('position', sql.NVarChar, p.position);
        request.input('location', sql.NVarChar, p.location);
        
        await request.query(`
            IF EXISTS(SELECT 1 FROM User_profiles WHERE UserId = @userId)
                UPDATE UserProfiles SET Phone=@phone, Avatar=@avatar, FullName=@fullName, Position=@position, Location=@location WHERE UserId=@userId
            ELSE
                INSERT INTO UserProfiles (UserId, Phone, Avatar, FullName, Position, Location) VALUES (@userId, @phone, @avatar, @fullName, @position, @location)
        `);
        res.json({ success: true, message: 'Cập nhật thành công' });
    } catch (e) {
        res.status(500).json({ success: false, message: 'Lỗi server' });
    }
});

// --- TEAMS ---

};
