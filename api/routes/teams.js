module.exports = function registerRoutes({ app, sql, bcrypt, jwt, JWT_SECRET }) {

app.get('/teams', async (req, res) => {
    try {
        const result = await sql.query(`
            SELECT t.*, u.Username AS CaptainUsername, p.FullName AS CaptainFullName
            FROM Teams t
            LEFT JOIN Users u ON t.CaptainId = u.Id
            LEFT JOIN User_profiles p ON u.Id = p.UserId
        `);

        const teamIds = result.recordset.map(t => `'${t.Id}'`);
        let playersMap = {};

        if (teamIds.length > 0) {
            const teamIdsStr = teamIds.join(',');
            const playersQuery = `
                SELECT t.Id AS TeamId, p.Id AS _id
                FROM Teams t
                JOIN User_profiles p ON t.CaptainId = p.UserId
                WHERE t.Id IN (${teamIdsStr})
                UNION
                SELECT tp.TeamId, tp.UserProfileId AS _id
                FROM TeamPlayers tp
                WHERE tp.TeamId IN (${teamIdsStr})
            `;
            const playersResult = await sql.query(playersQuery);
            for (const p of playersResult.recordset) {
                if (!playersMap[p.TeamId]) playersMap[p.TeamId] = [];
                playersMap[p.TeamId].push({ _id: p._id });
            }
        }

        const data = result.recordset.map(t => {
            const capName = t.CaptainFullName || t.CaptainUsername || 'Ẩn danh';
            return {
                _id: t.Id, 
                name: t.Name, 
                logo: t.Logo, 
                level: t.SkillLevel, 
                skillLevel: t.SkillLevel, 
                location: t.Location,
                isRecruiting: t.IsRecruiting, 
                desc: '', 
                captainId: {
                    _id: t.CaptainId,
                    username: capName
                }, 
                captainName: capName,
                players: playersMap[t.Id] || []
            };
        });
        res.json({ success: true, data });
    } catch (e) {
        console.error('Error fetching teams:', e);
        res.json({ success: false, data: [] });
    }
});

app.post('/teams', async (req, res) => {
    try {
        const { name, logo, skillLevel, location, isRecruiting, captainId } = req.body;
        const request = new sql.Request();
        request.input('name', sql.NVarChar, name);
        request.input('logo', sql.NVarChar, logo || '');
        request.input('skillLevel', sql.NVarChar, skillLevel || 'Sơ cấp');
        request.input('location', sql.NVarChar, location);
        request.input('isRecruiting', sql.Bit, isRecruiting ? 1 : 0);
        request.input('captainId', sql.UniqueIdentifier, captainId); // Uses Users.Id directly

        await request.query(`
            INSERT INTO Teams (Name, Logo, SkillLevel, Location, IsRecruiting, CaptainId)
            VALUES (@name, @logo, @skillLevel, @location, @isRecruiting, @captainId);
            UPDATE User_profiles SET IsLookingForTeam = 0, UpdatedAt = GETDATE() WHERE UserId = @captainId;
        `);
        res.json({ success: true, message: 'Tạo đội thành công' });
    } catch (e) {
        console.error(e);
        res.status(500).json({ success: false, message: 'Lỗi server' });
    }
});

app.get('/teams/my-team/:profileId', async (req, res) => {
    try {
        const request = new sql.Request();
        request.input('profileId', sql.UniqueIdentifier, req.params.profileId);
        const result = await request.query(`
            SELECT DISTINCT t.*, u.Username AS CaptainUsername, p_cap.FullName AS CaptainFullName
            FROM Teams t
            LEFT JOIN Users u ON t.CaptainId = u.Id
            LEFT JOIN User_profiles p_cap ON u.Id = p_cap.UserId
            LEFT JOIN TeamPlayers tp ON t.Id = tp.TeamId
            WHERE t.CaptainId IN (SELECT UserId FROM User_profiles WHERE Id = @profileId)
               OR tp.UserProfileId = @profileId
        `);

        const teamIds = result.recordset.map(t => `'${t.Id}'`);
        let playersMap = {};

        if (teamIds.length > 0) {
            const teamIdsStr = teamIds.join(',');
            const playersQuery = `
                -- Captain profile
                SELECT t.Id AS TeamId, p.Id AS _id, p.FullName AS fullName, p.Position AS position, 
                       p.Location AS location, p.Phone AS phone, p.Avatar AS avatar, p.UserId AS userId, 1 AS isCaptain
                FROM Teams t
                JOIN User_profiles p ON t.CaptainId = p.UserId
                WHERE t.Id IN (${teamIdsStr})
                UNION
                -- Team members
                SELECT tp.TeamId, p.Id AS _id, p.FullName AS fullName, p.Position AS position, 
                       p.Location AS location, p.Phone AS phone, p.Avatar AS avatar, p.UserId AS userId, 0 AS isCaptain
                FROM TeamPlayers tp
                JOIN User_profiles p ON tp.UserProfileId = p.Id
                WHERE tp.TeamId IN (${teamIdsStr})
            `;
            const playersResult = await sql.query(playersQuery);
            for (const p of playersResult.recordset) {
                if (!playersMap[p.TeamId]) playersMap[p.TeamId] = [];
                playersMap[p.TeamId].push({
                    _id: p._id,
                    fullName: p.fullName,
                    position: p.position,
                    location: p.location,
                    phone: p.phone,
                    avatar: p.avatar,
                    userId: p.userId
                });
            }
        }

        const data = result.recordset.map(t => {
            const capName = t.CaptainFullName || t.CaptainUsername || 'Ẩn danh';
            return {
                _id: t.Id, 
                name: t.Name, 
                logo: t.Logo, 
                level: t.SkillLevel, 
                skillLevel: t.SkillLevel, 
                location: t.Location,
                isRecruiting: t.IsRecruiting, 
                desc: '', 
                captainId: {
                    _id: t.CaptainId,
                    username: capName
                }, 
                captainName: capName,
                players: playersMap[t.Id] || []
            };
        });
        res.json({ success: true, data });
    } catch (e) {
        console.error('Error fetching my-team:', e);
        res.json({ success: false, data: [] });
    }
});

// --- MATCHES ---

app.patch('/teams/:teamId/kick/:profileId', async (req, res) => {
    try {
        const { teamId, profileId } = req.params;
        const request = new sql.Request();
        request.input('teamId', sql.UniqueIdentifier, teamId);
        request.input('profileId', sql.UniqueIdentifier, profileId);

        const capCheck = await request.query(`
            SELECT t.CaptainId, p.Id AS CaptainProfileId
            FROM Teams t
            JOIN User_profiles p ON t.CaptainId = p.UserId
            WHERE t.Id = @teamId
        `);
        if (capCheck.recordset.length > 0 && capCheck.recordset[0].CaptainProfileId.toLowerCase() === profileId.toLowerCase()) {
            return res.status(400).json({ success: false, message: "Không thể kick đội trưởng." });
        }

        await request.query(`
            DELETE FROM TeamPlayers WHERE TeamId = @teamId AND UserProfileId = @profileId;
            UPDATE User_profiles SET IsLookingForTeam = 1, UpdatedAt = GETDATE() WHERE Id = @profileId;
        `);

        res.json({ success: true, message: "Đã xóa thành viên khỏi đội." });
    } catch (e) {
        console.error('Error kicking player:', e);
        res.status(500).json({ success: false, message: "Lỗi server: " + e.message });
    }
});

app.patch('/teams/:teamId/toggle-recruiting', async (req, res) => {
    try {
        const { teamId } = req.params;
        const { captainUserId } = req.body;

        const request = new sql.Request();
        request.input('teamId', sql.UniqueIdentifier, teamId);
        const result = await request.query("SELECT * FROM Teams WHERE Id = @teamId");
        if (result.recordset.length === 0) {
            return res.status(404).json({ success: false, message: "Không tìm thấy đội bóng." });
        }

        const team = result.recordset[0];
        if (captainUserId && team.CaptainId.toLowerCase() !== captainUserId.toLowerCase()) {
            return res.status(403).json({ success: false, message: "Chỉ đội trưởng mới có thể thao tác này." });
        }

        const newIsRecruiting = team.IsRecruiting ? 0 : 1;
        const newStatus = newIsRecruiting ? 'Searching' : 'Full';

        const updateReq = new sql.Request();
        updateReq.input('teamId', sql.UniqueIdentifier, teamId);
        updateReq.input('isRecruiting', sql.Bit, newIsRecruiting);
        updateReq.input('recruitingStatus', sql.NVarChar, newStatus);
        await updateReq.query(`
            UPDATE Teams 
            SET IsRecruiting = @isRecruiting, RecruitingStatus = @recruitingStatus, UpdatedAt = GETDATE()
            WHERE Id = @teamId
        `);

        res.json({
            success: true,
            isRecruiting: newIsRecruiting === 1,
            message: newIsRecruiting === 1
                ? "Đã mở lại tuyển thành viên."
                : "Đã dừng tuyển thành viên. Người khác sẽ không thể gửi yêu cầu gia nhập."
        });
    } catch (e) {
        console.error('Error toggling recruiting:', e);
        res.status(500).json({ success: false, message: "Lỗi server: " + e.message });
    }
});

};
