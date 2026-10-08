module.exports = function registerRoutes({ app, sql, bcrypt, jwt, JWT_SECRET }) {

app.post('/invitations', async (req, res) => {
    try {
        const { teamId, playerProfileId, captainUserId } = req.body;
        if (!teamId || !playerProfileId || !captainUserId) {
            return res.status(400).json({ success: false, message: "Thiếu thông tin mời cầu thủ." });
        }

        // 1. Kiểm tra đội bóng và quyền đội trưởng
        const teamReq = new sql.Request();
        teamReq.input('teamId', sql.UniqueIdentifier, teamId);
        const teamRes = await teamReq.query("SELECT * FROM Teams WHERE Id = @teamId");
        if (teamRes.recordset.length === 0) {
            return res.status(404).json({ success: false, message: "Không tìm thấy đội bóng." });
        }

        const team = teamRes.recordset[0];
        if (team.CaptainId.toString().toLowerCase() !== captainUserId.toString().toLowerCase()) {
            return res.status(403).json({ success: false, message: "Chỉ đội trưởng mới có quyền mời cầu thủ vào đội." });
        }

        // 2. Lấy thông tin cầu thủ được mời
        const playerReq = new sql.Request();
        playerReq.input('profileId', sql.UniqueIdentifier, playerProfileId);
        const playerRes = await playerReq.query("SELECT * FROM User_profiles WHERE Id = @profileId");
        if (playerRes.recordset.length === 0) {
            return res.status(404).json({ success: false, message: "Không tìm thấy hồ sơ cầu thủ." });
        }

        const playerProfile = playerRes.recordset[0];
        const targetUserId = playerProfile.UserId;

        // 3. Không thể tự mời chính mình!
        if (targetUserId.toString().toLowerCase() === captainUserId.toString().toLowerCase()) {
            return res.status(400).json({ success: false, message: "Bạn là đội trưởng, không thể tự mời chính mình vào đội!" });
        }

        // 4. Kiểm tra xem cầu thủ đã ở trong đội này chưa
        const inTeamReq = new sql.Request();
        inTeamReq.input('teamId', sql.UniqueIdentifier, teamId);
        inTeamReq.input('profileId', sql.UniqueIdentifier, playerProfileId);
        const inTeamRes = await inTeamReq.query("SELECT 1 FROM TeamPlayers WHERE TeamId = @teamId AND UserProfileId = @profileId");
        if (inTeamRes.recordset.length > 0) {
            return res.status(400).json({ success: false, message: "Cầu thủ này đã là thành viên trong đội của bạn." });
        }

        // 5. Kiểm tra xem đã gửi lời mời đang chờ duyệt chưa
        const existReq = new sql.Request();
        existReq.input('teamId', sql.UniqueIdentifier, teamId);
        existReq.input('userId', sql.UniqueIdentifier, targetUserId);
        const existRes = await existReq.query("SELECT 1 FROM Invitations WHERE TeamId = @teamId AND UserId = @userId AND Status = 'pending'");
        if (existRes.recordset.length > 0) {
            return res.status(400).json({ success: false, message: "Bạn đã gửi lời mời cho cầu thủ này rồi, đang chờ phản hồi." });
        }

        // 6. Gửi lời mời mới
        const insertReq = new sql.Request();
        insertReq.input('teamId', sql.UniqueIdentifier, teamId);
        insertReq.input('userId', sql.UniqueIdentifier, targetUserId);
        await insertReq.query(`
            INSERT INTO Invitations (TeamId, UserId, Status, CreatedAt, UpdatedAt)
            VALUES (@teamId, @userId, 'pending', GETDATE(), GETDATE())
        `);

        res.json({ success: true, message: "Đã gửi lời mời tham gia đội bóng thành công!" });
    } catch (e) {
        console.error('Error creating invitation:', e);
        res.status(500).json({ success: false, message: "Lỗi server: " + e.message });
    }
});

app.get('/invitations/user/:userId', async (req, res) => {
    try {
        const request = new sql.Request();
        request.input('userId', sql.UniqueIdentifier, req.params.userId);
        const result = await request.query(`
            SELECT i.Id AS _id, i.Status AS status, i.CreatedAt AS createdAt,
                   t.Id AS teamId, t.Name AS teamName, t.Logo AS teamLogo, t.Location AS teamLocation,
                   u.Username AS captainUsername, p.FullName AS captainFullName
            FROM Invitations i
            JOIN Teams t ON i.TeamId = t.Id
            JOIN Users u ON t.CaptainId = u.Id
            LEFT JOIN User_profiles p ON u.Id = p.UserId
            WHERE i.UserId = @userId AND i.Status = 'pending'
            ORDER BY i.CreatedAt DESC
        `);

        const data = result.recordset.map(row => ({
            _id: row._id,
            status: row.status,
            createdAt: row.createdAt,
            teamId: {
                _id: row.teamId,
                name: row.teamName,
                logo: row.teamLogo,
                location: row.teamLocation,
            },
            captainId: {
                username: row.captainFullName || row.captainUsername || 'Đội trưởng',
            }
        }));

        res.json({ success: true, data });
    } catch (e) {
        console.error('Error fetching invitations:', e);
        res.json({ success: false, data: [] });
    }
});

app.patch('/invitations/:id/accept', async (req, res) => {
    try {
        const { id } = req.params;
        const request = new sql.Request();
        request.input('id', sql.UniqueIdentifier, id);
        const invRes = await request.query("SELECT * FROM Invitations WHERE Id = @id");
        if (invRes.recordset.length === 0) return res.status(404).json({ success: false, message: "Không tìm thấy lời mời" });

        const inv = invRes.recordset[0];
        const profReq = new sql.Request();
        profReq.input('userId', sql.UniqueIdentifier, inv.UserId);
        const profRes = await profReq.query("SELECT Id FROM User_profiles WHERE UserId = @userId");
        if (profRes.recordset.length > 0) {
            const profileId = profRes.recordset[0].Id;
            const addReq = new sql.Request();
            addReq.input('teamId', sql.UniqueIdentifier, inv.TeamId);
            addReq.input('profileId', sql.UniqueIdentifier, profileId);
            await addReq.query(`
                IF NOT EXISTS (SELECT 1 FROM TeamPlayers WHERE TeamId = @teamId AND UserProfileId = @profileId)
                BEGIN
                    INSERT INTO TeamPlayers (TeamId, UserProfileId) VALUES (@teamId, @profileId);
                END
                UPDATE User_profiles SET IsLookingForTeam = 0, UpdatedAt = GETDATE() WHERE Id = @profileId;
            `);
        }
        await request.query("UPDATE Invitations SET Status = 'accepted', UpdatedAt = GETDATE() WHERE Id = @id");
        res.json({ success: true, message: "Đã tham gia đội bóng" });
    } catch (e) {
        res.status(500).json({ success: false, message: e.message });
    }
});

app.patch('/invitations/:id/reject', async (req, res) => {
    try {
        const { id } = req.params;
        const request = new sql.Request();
        request.input('id', sql.UniqueIdentifier, id);
        await request.query("UPDATE Invitations SET Status = 'rejected', UpdatedAt = GETDATE() WHERE Id = @id");
        res.json({ success: true, message: "Đã từ chối lời mời" });
    } catch (e) {
        res.status(500).json({ success: false, message: e.message });
    }
});

app.get('/invitations/me', (req, res) => res.json({ success: true, data: [] }));

};
