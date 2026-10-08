module.exports = function registerRoutes({ app, sql, bcrypt, jwt, JWT_SECRET }) {

app.get('/join-requests/captain/:userId', async (req, res) => {
    try {
        const request = new sql.Request();
        request.input('userId', sql.UniqueIdentifier, req.params.userId);
        const result = await request.query(`
            SELECT jr.*, p.FullName, p.Position, p.Avatar, p.Location, p.Phone
            FROM JoinRequests jr
            JOIN User_profiles p ON jr.RequesterId = p.Id
            JOIN Teams t ON jr.TeamId = t.Id
            WHERE t.CaptainId = @userId AND jr.Status = 'pending'
        `);
        const data = result.recordset.map(r => ({
            _id: r.Id, 
            status: r.Status, 
            requesterId: { 
                _id: r.RequesterId, 
                fullName: r.FullName, 
                position: r.Position, 
                avatar: r.Avatar,
                location: r.Location,
                phone: r.Phone
            },
            teamId: r.TeamId
        }));
        res.json({ success: true, data });
    } catch (e) {
        console.error('Error fetching captain join requests:', e);
        res.json({ success: false, data: [] });
    }
});

app.get('/join-requests/player/:profileId', async (req, res) => {
    try {
        const request = new sql.Request();
        request.input('profileId', sql.UniqueIdentifier, req.params.profileId);
        const result = await request.query(`
            SELECT jr.*, t.Name AS TeamName, t.Location AS TeamLocation, t.CaptainId, u.Username AS CaptainUsername, p.FullName AS CaptainFullName
            FROM JoinRequests jr
            LEFT JOIN Teams t ON jr.TeamId = t.Id
            LEFT JOIN Users u ON t.CaptainId = u.Id
            LEFT JOIN User_profiles p ON u.Id = p.UserId
            WHERE jr.RequesterId = @profileId
        `);
        const data = result.recordset.map(r => {
            const capName = r.CaptainFullName || r.CaptainUsername || 'Ẩn danh';
            return {
                _id: r.Id, 
                status: r.Status, 
                teamId: { 
                    _id: r.TeamId,
                    name: r.TeamName || '',
                    location: r.TeamLocation || '',
                    captainId: {
                        _id: r.CaptainId,
                        username: capName
                    }
                }
            };
        });
        res.json({ success: true, data });
    } catch (e) {
        console.error('Error in /api/join-requests/player:', e);
        res.json({ success: false, data: [] });
    }
});

app.post('/join-requests', async (req, res) => {
    try {
        const { teamId, requesterId } = req.body;
        const request = new sql.Request();
        request.input('teamId', sql.UniqueIdentifier, teamId);
        request.input('requesterId', sql.UniqueIdentifier, requesterId);
        await request.query("INSERT INTO JoinRequests (TeamId, RequesterId) VALUES (@teamId, @requesterId)");
        res.json({ success: true, message: 'Đã gửi yêu cầu' });
    } catch (e) {
        res.json({ success: false, message: 'Lỗi' });
    }
});

app.patch('/join-requests/:id/approve', async (req, res) => {
    try {
        const { id } = req.params;
        const request = new sql.Request();
        request.input('id', sql.UniqueIdentifier, id);

        const checkRes = await request.query("SELECT * FROM JoinRequests WHERE Id = @id");
        if (checkRes.recordset.length === 0) {
            return res.status(404).json({ success: false, message: "Không tìm thấy yêu cầu." });
        }

        const joinReq = checkRes.recordset[0];
        if (joinReq.Status !== 'pending') {
            return res.status(400).json({ success: false, message: "Yêu cầu này đã được xử lý rồi." });
        }

        const teamId = joinReq.TeamId;
        const requesterId = joinReq.RequesterId;

        // Kiểm tra cầu thủ đã tham gia đội nào chưa
        const teamCheckReq = new sql.Request();
        teamCheckReq.input('requesterId', sql.UniqueIdentifier, requesterId);
        const inTeamRes = await teamCheckReq.query("SELECT 1 FROM TeamPlayers WHERE UserProfileId = @requesterId");
        if (inTeamRes.recordset.length > 0) {
            const updateReq = new sql.Request();
            updateReq.input('id', sql.UniqueIdentifier, id);
            await updateReq.query("UPDATE JoinRequests SET Status = 'rejected', UpdatedAt = GETDATE() WHERE Id = @id");
            return res.status(400).json({ success: false, message: "Cầu thủ này đã gia nhập một đội khác." });
        }

        // Thêm vào bảng TeamPlayers
        const addPlayerReq = new sql.Request();
        addPlayerReq.input('teamId', sql.UniqueIdentifier, teamId);
        addPlayerReq.input('requesterId', sql.UniqueIdentifier, requesterId);
        await addPlayerReq.query(`
            IF NOT EXISTS (SELECT 1 FROM TeamPlayers WHERE TeamId = @teamId AND UserProfileId = @requesterId)
            BEGIN
                INSERT INTO TeamPlayers (TeamId, UserProfileId) VALUES (@teamId, @requesterId);
            END
        `);

        // Kiểm tra số lượng thành viên (>= 14 người thì tự động khóa tuyển)
        const countReq = new sql.Request();
        countReq.input('teamId', sql.UniqueIdentifier, teamId);
        const countRes = await countReq.query("SELECT COUNT(*) AS total FROM TeamPlayers WHERE TeamId = @teamId");
        if (countRes.recordset[0].total >= 13) {
            await countReq.query("UPDATE Teams SET IsRecruiting = 0, RecruitingStatus = 'Full', UpdatedAt = GETDATE() WHERE Id = @teamId");
        }

        // Cập nhật UserProfile: IsLookingForTeam = 0
        const profileReq = new sql.Request();
        profileReq.input('requesterId', sql.UniqueIdentifier, requesterId);
        await profileReq.query("UPDATE User_profiles SET IsLookingForTeam = 0, UpdatedAt = GETDATE() WHERE Id = @requesterId");

        // Cập nhật trạng thái JoinRequest hiện tại thành approved
        const approveReq = new sql.Request();
        approveReq.input('id', sql.UniqueIdentifier, id);
        approveReq.input('requesterId', sql.UniqueIdentifier, requesterId);
        await approveReq.query(`
            UPDATE JoinRequests SET Status = 'approved', UpdatedAt = GETDATE() WHERE Id = @id;
            UPDATE JoinRequests SET Status = 'rejected', UpdatedAt = GETDATE() WHERE RequesterId = @requesterId AND Status = 'pending' AND Id <> @id;
        `);

        res.json({ success: true, message: "Đã phê duyệt thành viên vào đội." });
    } catch (e) {
        console.error('Error approving join request:', e);
        res.status(500).json({ success: false, message: "Lỗi server: " + e.message });
    }
});

app.patch('/join-requests/:id/reject', async (req, res) => {
    try {
        const { id } = req.params;
        const request = new sql.Request();
        request.input('id', sql.UniqueIdentifier, id);

        const checkRes = await request.query("SELECT * FROM JoinRequests WHERE Id = @id");
        if (checkRes.recordset.length === 0) {
            return res.status(404).json({ success: false, message: "Không tìm thấy yêu cầu." });
        }

        const joinReq = checkRes.recordset[0];
        if (joinReq.Status !== 'pending') {
            return res.status(400).json({ success: false, message: "Yêu cầu này đã được xử lý rồi." });
        }

        await request.query("UPDATE JoinRequests SET Status = 'rejected', UpdatedAt = GETDATE() WHERE Id = @id");
        res.json({ success: true, message: "Đã từ chối yêu cầu gia nhập." });
    } catch (e) {
        console.error('Error rejecting join request:', e);
        res.status(500).json({ success: false, message: "Lỗi server: " + e.message });
    }
});

};
