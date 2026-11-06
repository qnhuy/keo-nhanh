module.exports = function registerRoutes({ app, sql }) {

    // 1. GET /admin/stats - Thống kê tổng quan hệ thống
    app.get('/admin/stats', async (req, res) => {
        try {
            const userCountRes = await sql.query("SELECT COUNT(*) AS total FROM Users");
            const teamCountRes = await sql.query("SELECT COUNT(*) AS total FROM Teams");
            const matchCountRes = await sql.query("SELECT COUNT(*) AS total FROM Matches");
            const openMatchRes = await sql.query("SELECT COUNT(*) AS total FROM Matches WHERE LOWER(Status) = 'open'");
            const matchedMatchRes = await sql.query("SELECT COUNT(*) AS total FROM Matches WHERE LOWER(Status) IN ('matched', 'finished')");

            res.json({
                success: true,
                stats: {
                    totalUsers: userCountRes.recordset[0]?.total || 0,
                    totalTeams: teamCountRes.recordset[0]?.total || 0,
                    totalMatches: matchCountRes.recordset[0]?.total || 0,
                    openMatches: openMatchRes.recordset[0]?.total || 0,
                    matchedMatches: matchedMatchRes.recordset[0]?.total || 0,
                }
            });
        } catch (e) {
            console.error('Error fetching admin stats:', e);
            res.status(500).json({ success: false, message: 'Lỗi server khi lấy thống kê' });
        }
    });

    // 2. GET /admin/users - Danh sách người dùng và phân quyền
    app.get('/admin/users', async (req, res) => {
        try {
            const result = await sql.query(`
                SELECT u.Id AS id, u.Username AS username, u.Role AS role,
                       p.FullName AS fullName, p.Phone AS phone, p.Location AS location, p.Position AS position
                FROM Users u
                LEFT JOIN User_profiles p ON u.Id = p.UserId
                ORDER BY u.Username ASC
            `);

            const users = result.recordset.map(row => ({
                id: row.id,
                username: row.username,
                role: row.role || 'player',
                fullName: row.fullName || 'Chưa cập nhật',
                phone: row.phone || 'Chưa cập nhật',
                location: row.location || 'Chưa cập nhật',
                position: row.position || 'Chưa rõ',
            }));

            res.json({ success: true, users });
        } catch (e) {
            console.error('Error fetching users for admin:', e);
            res.status(500).json({ success: false, users: [] });
        }
    });

    // 3. PATCH /admin/users/:id/role - Cập nhật Role người dùng
    app.patch('/admin/users/:id/role', async (req, res) => {
        try {
            const { id } = req.params;
            const { role } = req.body;

            if (!role) {
                return res.status(400).json({ success: false, message: 'Thiếu quyền (role).' });
            }

            const request = new sql.Request();
            request.input('id', sql.UniqueIdentifier, id);
            request.input('role', sql.NVarChar, role.toLowerCase());

            await request.query("UPDATE Users SET Role = @role WHERE Id = @id");
            res.json({ success: true, message: 'Cập nhật phân quyền thành công!' });
        } catch (e) {
            console.error('Error updating user role:', e);
            res.status(500).json({ success: false, message: 'Lỗi server khi cập nhật role' });
        }
    });

    // 4. POST /admin/broadcast - Gửi thông báo đến toàn bộ người dùng
    app.post('/admin/broadcast', async (req, res) => {
        try {
            const { title, message } = req.body;
            if (!title || !message) {
                return res.status(400).json({ success: false, message: 'Vui lòng nhập đầy đủ tiêu đề và nội dung.' });
            }

            const usersRes = await sql.query("SELECT Id FROM Users");
            const users = usersRes.recordset;

            for (const u of users) {
                const reqInsert = new sql.Request();
                reqInsert.input('userId', sql.UniqueIdentifier, u.Id);
                reqInsert.input('title', sql.NVarChar, title);
                reqInsert.input('message', sql.NVarChar, message);
                await reqInsert.query(`
                    INSERT INTO Notifications (UserId, Title, Message, Type, RelatedId, IsRead, CreatedAt)
                    VALUES (@userId, @title, @message, 'system', NULL, 0, GETDATE())
                `);
            }

            res.json({
                success: true,
                message: `Đã gửi thông báo thành công tới ${users.length} tài khoản người dùng!`,
                sentCount: users.length,
            });
        } catch (e) {
            console.error('Error broadcasting notification:', e);
            res.status(500).json({ success: false, message: 'Lỗi server khi gửi thông báo' });
        }
    });

    // 5. DELETE /admin/matches/:id - Xóa/Hủy trận đấu vi phạm
    app.delete('/admin/matches/:id', async (req, res) => {
        try {
            const { id } = req.params;
            const request = new sql.Request();
            request.input('id', sql.UniqueIdentifier, id);

            await request.query("DELETE FROM Matches WHERE Id = @id");
            res.json({ success: true, message: 'Đã xóa kèo đấu thành công!' });
        } catch (e) {
            console.error('Error deleting match:', e);
            res.status(500).json({ success: false, message: 'Lỗi server khi xóa kèo đấu' });
        }
    });

    // 6. DELETE /admin/teams/:id - Giải tán đội bóng vi phạm
    app.delete('/admin/teams/:id', async (req, res) => {
        try {
            const { id } = req.params;
            const request = new sql.Request();
            request.input('id', sql.UniqueIdentifier, id);

            // Xóa các bảng phụ thuộc trước
            await request.query(`
                DELETE FROM TeamPlayers WHERE TeamId = @id;
                DELETE FROM Invitations WHERE TeamId = @id;
                DELETE FROM JoinRequests WHERE TeamId = @id;
                DELETE FROM Messages WHERE TeamId = @id;
                DELETE FROM Matches WHERE CreatorTeamId = @id OR MatchedWithTeamId = @id;
                DELETE FROM Teams WHERE Id = @id;
            `);

            res.json({ success: true, message: 'Đã giải tán đội bóng thành công!' });
        } catch (e) {
            console.error('Error deleting team:', e);
            res.status(500).json({ success: false, message: 'Lỗi server khi giải tán đội bóng' });
        }
    });

};
