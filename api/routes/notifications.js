module.exports = function registerNotificationRoutes({ app, sql }) {

    // Helper xử lý lấy danh sách thông báo
    const handleGetNotifications = async (req, res) => {
        try {
            const userId = req.params.userId || req.query.userId;
            if (!userId) {
                return res.status(400).json({ success: false, message: 'Thiếu userId' });
            }

            const request = new sql.Request();
            request.input('userId', sql.UniqueIdentifier, userId);
            const result = await request.query(`
                SELECT Id AS _id, Id, UserId, Title, Message, Type, RelatedId, IsRead, CreatedAt
                FROM Notifications
                WHERE UserId = @userId
                ORDER BY CreatedAt DESC
            `);

            const notifications = result.recordset.map(n => ({
                _id: n._id,
                id: n.Id,
                userId: n.UserId,
                title: n.Title,
                message: n.Message,
                type: n.Type,
                relatedId: n.RelatedId,
                isRead: Boolean(n.IsRead),
                createdAt: n.CreatedAt
            }));

            const unreadCount = notifications.filter(n => !n.isRead).length;

            res.json({
                success: true,
                data: notifications,
                unreadCount
            });
        } catch (e) {
            console.error('Error fetching notifications:', e);
            res.status(500).json({ success: false, message: e.message, data: [], unreadCount: 0 });
        }
    };

    // 1. GET /notifications và /notification (hỗ trợ cả params và query)
    app.get('/notifications', handleGetNotifications);
    app.get('/notifications/:userId', handleGetNotifications);
    app.get('/notification', handleGetNotifications);
    app.get('/notification/:userId', handleGetNotifications);

    // 2. PATCH /notifications/:id/read (Đánh dấu 1 thông báo đã đọc)
    const handleMarkAsRead = async (req, res) => {
        try {
            const { id } = req.params;
            const request = new sql.Request();
            request.input('id', sql.UniqueIdentifier, id);
            await request.query("UPDATE Notifications SET IsRead = 1 WHERE Id = @id");
            res.json({ success: true, message: 'Đã đánh dấu đã đọc' });
        } catch (e) {
            console.error('Error marking notification as read:', e);
            res.status(500).json({ success: false, message: e.message });
        }
    };

    app.patch('/notifications/:id/read', handleMarkAsRead);
    app.patch('/notification/:id/read', handleMarkAsRead);

    // 3. PATCH /notifications/read-all/:userId (Đánh dấu tất cả thông báo của user đã đọc)
    const handleMarkAllAsRead = async (req, res) => {
        try {
            const { userId } = req.params;
            const request = new sql.Request();
            request.input('userId', sql.UniqueIdentifier, userId);
            await request.query("UPDATE Notifications SET IsRead = 1 WHERE UserId = @userId");
            res.json({ success: true, message: 'Đã đánh dấu tất cả đã đọc' });
        } catch (e) {
            console.error('Error marking all notifications as read:', e);
            res.status(500).json({ success: false, message: e.message });
        }
    };

    app.patch('/notifications/read-all/:userId', handleMarkAllAsRead);
    app.patch('/notification/read-all/:userId', handleMarkAllAsRead);

    // 4. POST /notifications (Tạo thông báo mới thủ công nếu cần)
    const handleCreateNotification = async (req, res) => {
        try {
            const { userId, title, message, type, relatedId } = req.body;
            if (!userId || !title || !message) {
                return res.status(400).json({ success: false, message: 'Thiếu thông tin thông báo' });
            }

            const request = new sql.Request();
            request.input('userId', sql.UniqueIdentifier, userId);
            request.input('title', sql.NVarChar, title);
            request.input('message', sql.NVarChar, message);
            request.input('type', sql.NVarChar, type || 'general');
            request.input('relatedId', sql.UniqueIdentifier, relatedId || null);

            await request.query(`
                INSERT INTO Notifications (UserId, Title, Message, Type, RelatedId, IsRead, CreatedAt)
                VALUES (@userId, @title, @message, @type, @relatedId, 0, GETDATE())
            `);

            res.json({ success: true, message: 'Tạo thông báo thành công' });
        } catch (e) {
            console.error('Error creating notification:', e);
            res.status(500).json({ success: false, message: e.message });
        }
    };

    app.post('/notifications', handleCreateNotification);
    app.post('/notification', handleCreateNotification);

    // 5. DELETE /notifications/:id (Xóa thông báo)
    const handleDeleteNotification = async (req, res) => {
        try {
            const { id } = req.params;
            const request = new sql.Request();
            request.input('id', sql.UniqueIdentifier, id);
            await request.query("DELETE FROM Notifications WHERE Id = @id");
            res.json({ success: true, message: 'Đã xóa thông báo' });
        } catch (e) {
            console.error('Error deleting notification:', e);
            res.status(500).json({ success: false, message: e.message });
        }
    };

    app.delete('/notifications/:id', handleDeleteNotification);
    app.delete('/notification/:id', handleDeleteNotification);
};
