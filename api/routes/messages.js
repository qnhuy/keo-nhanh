module.exports = function registerRoutes({ app, sql, bcrypt, jwt, JWT_SECRET }) {

app.get('/messages/:teamId', async (req, res) => {
    try {
        const request = new sql.Request();
        request.input('teamId', sql.UniqueIdentifier, req.params.teamId);
        const result = await request.query(`
            SELECT m.*, p.FullName, p.Avatar 
            FROM Messages m
            JOIN Users u ON m.SenderId = u.Id
            JOIN User_profiles p ON u.Id = p.UserId
            WHERE m.TeamId = @teamId
            ORDER BY m.CreatedAt ASC
        `);
        const data = result.recordset.map(m => ({
            _id: m.Id, content: m.Content, createdAt: m.CreatedAt,
            senderId: { _id: m.SenderId, fullName: m.FullName, avatar: m.Avatar }
        }));
        res.json(data);
    } catch (e) {
        res.json([]);
    }
});

app.post('/messages', async (req, res) => {
    try {
        const { teamId, senderId, content } = req.body;
        const request = new sql.Request();
        request.input('teamId', sql.UniqueIdentifier, teamId);
        request.input('senderId', sql.UniqueIdentifier, senderId);
        request.input('content', sql.NVarChar, content);
        await request.query("INSERT INTO Messages (TeamId, SenderId, Content) VALUES (@teamId, @senderId, @content)");
        res.json({ success: true });
    } catch (e) {
        res.json({ success: false });
    }
});

};
