module.exports = function registerRoutes({ app, sql, bcrypt, jwt, JWT_SECRET }) {

app.get('/players', async (req, res) => {
    try {
        const result = await sql.query("SELECT * FROM User_profiles");
        const data = result.recordset.map(p => ({
            _id: p.Id, 
            userId: p.UserId,
            fullName: p.FullName, 
            position: p.Position, 
            location: p.Location, 
            phone: p.Phone, 
            avatar: p.Avatar, 
            isLookingForTeam: p.IsLookingForTeam
        }));
        res.json({ success: true, players: data });
    } catch (e) {
        res.json({ success: false, players: [] });
    }
});

};
