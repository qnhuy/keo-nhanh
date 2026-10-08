module.exports = function registerRoutes({ app, sql, bcrypt, jwt, JWT_SECRET }) {

app.get('/matches', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT m.*, t.Name AS TeamName 
            FROM Matches m 
            LEFT JOIN Teams t ON m.CreatorTeamId = t.Id
        `);
        const data = result.recordset.map(m => ({
            _id: m.Id, status: m.Status, playTime: m.PlayTime, fieldName: m.FieldName,
            creatorTeamId: { name: m.TeamName || 'Đội ẩn danh' }
        }));
        res.json({ success: true, data });
    } catch (e) {
        res.json({ success: false, data: [] });
    }
});

app.post('/matches', async (req, res) => {
    try {
        const { userId, playTime, fieldName, location, latitude, longitude } = req.body;
        const request = new sql.Request();
        request.input('userId', sql.UniqueIdentifier, userId);

        const teamRes = await request.query(`
            SELECT TOP 1 Id 
            FROM Teams 
            WHERE CaptainId = @userId
        `);
        
        if (teamRes.recordset.length === 0) {
            return res.status(400).json({ success: false, message: 'Bạn phải tạo đội bóng trước khi đăng kèo!' });
        }
        const teamId = teamRes.recordset[0].Id;

        request.input('teamId', sql.UniqueIdentifier, teamId);
        request.input('playTime', sql.DateTime, new Date(playTime));
        request.input('fieldName', sql.NVarChar, fieldName);
        request.input('location', sql.NVarChar, location || '');
        request.input('latitude', sql.Float, latitude || null);
        request.input('longitude', sql.Float, longitude || null);

        await request.query(`
            INSERT INTO Matches (CreatorTeamId, PlayTime, FieldName, Location, Latitude, Longitude)
            VALUES (@teamId, @playTime, @fieldName, @location, @latitude, @longitude)
        `);
        res.json({ success: true, message: 'Tạo kèo thành công' });
    } catch (e) {
        console.error(e);
        res.status(500).json({ success: false, message: 'Lỗi server' });
    }
});

// --- PLAYERS ---

app.get('/matches/my-matches/:teamId', async (req, res) => {
    try {
        const request = new sql.Request();
        request.input('teamId', sql.UniqueIdentifier, req.params.teamId);
        const result = await request.query(`
            SELECT m.*, 
                   t.Name AS CreatorTeamName, t.Logo AS CreatorTeamLogo,
                   t2.Name AS MatchedTeamName, t2.Logo AS MatchedTeamLogo 
            FROM Matches m 
            LEFT JOIN Teams t ON m.CreatorTeamId = t.Id
            LEFT JOIN Teams t2 ON m.MatchedWithTeamId = t2.Id
            WHERE m.CreatorTeamId = @teamId OR m.MatchedWithTeamId = @teamId
            ORDER BY m.PlayTime ASC
        `);
        const data = result.recordset.map(m => ({
            _id: m.Id, 
            status: m.Status, 
            playTime: m.PlayTime, 
            fieldName: m.FieldName,
            location: m.Location,
            creatorTeamId: { _id: m.CreatorTeamId, name: m.CreatorTeamName || 'Đội ẩn danh', logo: m.CreatorTeamLogo },
            matchedWithTeamId: m.MatchedWithTeamId ? { _id: m.MatchedWithTeamId, name: m.MatchedTeamName || 'Đội ẩn danh', logo: m.MatchedTeamLogo } : null
        }));
        res.json({ success: true, data });
    } catch (e) {
        console.error('Error fetching my-matches:', e);
        res.json({ success: false, data: [] });
    }
});

app.get('/matches/:id', async (req, res) => {
    try {
        const request = new sql.Request();
        request.input('id', sql.UniqueIdentifier, req.params.id);
        const result = await request.query(`
            SELECT m.*, 
                   t.Name AS CreatorTeamName, t.Logo AS CreatorTeamLogo,
                   t2.Name AS MatchedTeamName, t2.Logo AS MatchedTeamLogo
            FROM Matches m 
            LEFT JOIN Teams t ON m.CreatorTeamId = t.Id
            LEFT JOIN Teams t2 ON m.MatchedWithTeamId = t2.Id
            WHERE m.Id = @id
        `);
        if (result.recordset.length === 0) return res.status(404).json({ success: false, message: 'Không tìm thấy kèo' });
        const m = result.recordset[0];
        const data = {
            _id: m.Id, 
            status: m.Status, 
            playTime: m.PlayTime, 
            fieldName: m.FieldName, 
            fieldAddress: m.Location,
            location: m.Location,
            creatorTeamId: { _id: m.CreatorTeamId, name: m.CreatorTeamName || 'Đội ẩn danh', logo: m.CreatorTeamLogo },
            matchedWithTeamId: m.MatchedWithTeamId ? { _id: m.MatchedWithTeamId, name: m.MatchedTeamName || 'Đội ẩn danh', logo: m.MatchedTeamLogo } : null
        };
        res.json({ success: true, data, ...data });
    } catch (e) {
        console.error('Error fetching match by id:', e);
        res.status(500).json({ success: false });
    }
});

app.patch('/matches/:id/match', async (req, res) => {
    try {
        const { id } = req.params;
        const { matchedWithTeamId, userId } = req.body;

        const request = new sql.Request();
        request.input('id', sql.UniqueIdentifier, id);
        const matchRes = await request.query("SELECT * FROM Matches WHERE Id = @id");
        if (matchRes.recordset.length === 0) {
            return res.status(404).json({ success: false, message: "Không tìm thấy trận đấu" });
        }

        const match = matchRes.recordset[0];
        if (match.Status !== 'open') {
            return res.status(400).json({ success: false, message: "Trận đấu đã được ghép hoặc đã hủy" });
        }

        if (match.CreatorTeamId.toLowerCase() === matchedWithTeamId.toLowerCase()) {
            return res.status(400).json({ success: false, message: "Không thể nhận kèo của chính đội mình" });
        }

        const teamReq = new sql.Request();
        teamReq.input('teamId', sql.UniqueIdentifier, matchedWithTeamId);
        const teamRes = await teamReq.query("SELECT * FROM Teams WHERE Id = @teamId");
        if (teamRes.recordset.length === 0) {
            return res.status(404).json({ success: false, message: "Không tìm thấy đội bóng" });
        }
        const team = teamRes.recordset[0];
        if (team.CaptainId.toLowerCase() !== userId.toLowerCase()) {
            return res.status(403).json({ success: false, message: "Chỉ đội trưởng mới có quyền nhận kèo" });
        }

        const updateReq = new sql.Request();
        updateReq.input('id', sql.UniqueIdentifier, id);
        updateReq.input('matchedWithTeamId', sql.UniqueIdentifier, matchedWithTeamId);
        await updateReq.query(`
            UPDATE Matches 
            SET MatchedWithTeamId = @matchedWithTeamId, Status = 'matched', UpdatedAt = GETDATE()
            WHERE Id = @id
        `);

        // Tự động tạo và gửi thông báo cho người đăng kèo khi có đội khác xác nhận ghép kèo
        try {
            const creatorReq = new sql.Request();
            creatorReq.input('creatorTeamId', sql.UniqueIdentifier, match.CreatorTeamId);
            const creatorRes = await creatorReq.query("SELECT CaptainId, Name FROM Teams WHERE Id = @creatorTeamId");
            if (creatorRes.recordset.length > 0) {
                const creatorCaptainId = creatorRes.recordset[0].CaptainId;
                const fieldName = match.FieldName || 'sân bóng';
                const matchedTeamName = team.Name || 'Một đội bóng';
                const notifReq = new sql.Request();
                notifReq.input('userId', sql.UniqueIdentifier, creatorCaptainId);
                notifReq.input('title', sql.NVarChar, 'Ghép kèo thành công! ⚽');
                notifReq.input('message', sql.NVarChar, `Đội "${matchedTeamName}" đã xác nhận ghép kèo thi đấu tại ${fieldName}.`);
                notifReq.input('type', sql.NVarChar, 'match_matched');
                notifReq.input('relatedId', sql.UniqueIdentifier, id);
                await notifReq.query(`
                    INSERT INTO Notifications (UserId, Title, Message, Type, RelatedId, IsRead, CreatedAt)
                    VALUES (@userId, @title, @message, @type, @relatedId, 0, GETDATE())
                `);
            }
        } catch (notifErr) {
            console.error('Lỗi tạo notification ghép kèo:', notifErr);
        }

        res.json({ success: true, message: "Nhận kèo thành công" });
    } catch (e) {
        console.error('Error matching team:', e);
        res.status(500).json({ success: false, message: "Lỗi server: " + e.message });
    }
});

app.patch('/matches/:id/cancel', async (req, res) => {
    try {
        const { id } = req.params;
        const { userId } = req.body;

        const request = new sql.Request();
        request.input('id', sql.UniqueIdentifier, id);
        const matchRes = await request.query(`
            SELECT m.*, t.CaptainId AS CreatorCaptainId, t2.CaptainId AS MatchedCaptainId
            FROM Matches m
            LEFT JOIN Teams t ON m.CreatorTeamId = t.Id
            LEFT JOIN Teams t2 ON m.MatchedWithTeamId = t2.Id
            WHERE m.Id = @id
        `);
        if (matchRes.recordset.length === 0) {
            return res.status(404).json({ success: false, message: "Không tìm thấy trận đấu" });
        }

        const match = matchRes.recordset[0];
        if (match.Status !== 'matched') {
            return res.status(400).json({ success: false, message: "Trận đấu không ở trạng thái có thể hủy ghép" });
        }

        const isCreatorCap = match.CreatorCaptainId && match.CreatorCaptainId.toLowerCase() === userId.toLowerCase();
        const isMatchedCap = match.MatchedCaptainId && match.MatchedCaptainId.toLowerCase() === userId.toLowerCase();
        if (!isCreatorCap && !isMatchedCap) {
            return res.status(403).json({ success: false, message: "Chỉ đội trưởng của 2 đội mới có quyền hủy kèo" });
        }

        await request.query(`
            UPDATE Matches 
            SET MatchedWithTeamId = NULL, Status = 'open', UpdatedAt = GETDATE()
            WHERE Id = @id
        `);

        res.json({ success: true, message: "Hủy kèo thành công" });
    } catch (e) {
        console.error('Error cancelling match:', e);
        res.status(500).json({ success: false, message: "Lỗi server: " + e.message });
    }
});

app.delete('/matches/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const request = new sql.Request();
        request.input('id', sql.UniqueIdentifier, id);
        await request.query("DELETE FROM Matches WHERE Id = @id");
        res.json({ success: true, message: "Xóa trận đấu thành công" });
    } catch (e) {
        console.error('Error deleting match:', e);
        res.status(500).json({ success: false, message: "Lỗi server: " + e.message });
    }
});

};
