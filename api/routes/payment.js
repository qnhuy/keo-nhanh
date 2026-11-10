const { createPaymentLink, verifyWebhookData, isConfigured } = require('../config/payos');

module.exports = function registerPaymentRoutes({ app, sql }) {

    // 1. POST /payment/create-payment-link - Tạo liên kết thanh toán PayOS (29.000 VNĐ)
    app.post('/payment/create-payment-link', async (req, res) => {
        try {
            const { userId } = req.body;
            const amount = parseInt(process.env.PAYOS_PACKAGE_PRICE || '29000', 10);

            if (!userId) {
                return res.status(400).json({ success: false, message: 'Thiếu userId của người dùng.' });
            }

            // Sinh mã OrderCode duy nhất dạng số nguyên (tối đa 9 chữ số theo chuẩn PayOS)
            const orderCode = Number(String(Date.now()).slice(-8) + Math.floor(Math.random() * 10));
            const description = 'KEO NHANH 1 THANG';

            // Tạo link qua SDK PayOS (hoặc Mock VietQR an toàn)
            const paymentData = await createPaymentLink({
                orderCode,
                amount,
                description
            });

            // Lưu bản ghi vào bảng Payments với trạng thái PENDING
            const request = new sql.Request();
            request.input('userId', sql.UniqueIdentifier, userId);
            request.input('orderCode', sql.BigInt, orderCode);
            request.input('amount', sql.Int, amount);
            request.input('paymentUrl', sql.NVarChar, paymentData.checkoutUrl);
            request.input('qrCode', sql.NVarChar, paymentData.qrCode);

            await request.query(`
                INSERT INTO Payments (UserId, OrderCode, Amount, PackageName, Status, PaymentUrl, QrCode, CreatedAt)
                VALUES (@userId, @orderCode, @amount, N'Gói Đặc Quyền 1 Tháng', 'PENDING', @paymentUrl, @qrCode, GETDATE())
            `);

            res.json({
                success: true,
                message: 'Khởi tạo giao dịch thanh toán thành công!',
                payment: {
                    orderCode,
                    amount,
                    description,
                    accountNumber: paymentData.accountNumber,
                    accountName: paymentData.accountName,
                    bankName: paymentData.bankName || 'MBBank',
                    bin: paymentData.bin || '970422',
                    qrCode: paymentData.qrCode,
                    checkoutUrl: paymentData.checkoutUrl,
                    isMock: paymentData.isMock
                }
            });

        } catch (err) {
            console.error('[Payment] Lỗi khi tạo payment link:', err);
            res.status(500).json({ success: false, message: 'Lỗi server khi khởi tạo thanh toán: ' + err.message });
        }
    });

    // 2. POST /payment/payos-webhook - Webhook nhận callback từ server PayOS
    app.post('/payment/payos-webhook', async (req, res) => {
        try {
            console.log('[PayOS Webhook] Nhận callback:', req.body);
            const webhookData = await verifyWebhookData(req.body);

            if (!webhookData) {
                return res.status(400).json({ success: false, message: 'Dữ liệu Webhook không hợp lệ.' });
            }

            const orderCode = webhookData.orderCode;
            const code = webhookData.code; // "00" là thành công trong PayOS

            if (orderCode && (code === '00' || code === 0 || webhookData.success)) {
                const request = new sql.Request();
                request.input('orderCode', sql.BigInt, orderCode);

                // Tìm giao dịch
                const findRes = await request.query("SELECT * FROM Payments WHERE OrderCode = @orderCode");
                const payment = findRes.recordset[0];

                if (payment && payment.Status !== 'PAID') {
                    const updateReq = new sql.Request();
                    updateReq.input('orderCode', sql.BigInt, orderCode);
                    updateReq.input('userId', sql.UniqueIdentifier, payment.UserId);

                    // Cập nhật trạng thái thanh toán
                    await updateReq.query(`
                        UPDATE Payments 
                        SET Status = 'PAID', PaidAt = GETDATE() 
                        WHERE OrderCode = @orderCode
                    `);

                    // Kích hoạt hoặc gia hạn 30 ngày cho tài khoản
                    await updateReq.query(`
                        UPDATE Users 
                        SET IsPaid = 1,
                            PaidUntil = DATEADD(day, 30, CASE WHEN PaidUntil > GETDATE() THEN PaidUntil ELSE GETDATE() END)
                        WHERE Id = @userId
                    `);

                    console.log(`[PayOS Webhook] Đã kích hoạt 30 ngày thành viên đặc quyền cho User: ${payment.UserId}`);
                }
            }

            // PayOS yêu cầu phản hồi HTTP 200 nhanh chóng
            res.json({ success: true, message: 'Webhook đã được xử lý thành công.' });

        } catch (err) {
            console.error('[PayOS Webhook] Lỗi khi xử lý webhook:', err);
            res.status(500).json({ success: false, message: 'Lỗi server khi xử lý webhook: ' + err.message });
        }
    });

    // 3. GET /payment/check-status/:orderCode - Kiểm tra trạng thái đơn hàng (phục vụ Polling trên app)
    app.get('/payment/check-status/:orderCode', async (req, res) => {
        try {
            const { orderCode } = req.params;
            const request = new sql.Request();
            request.input('orderCode', sql.BigInt, orderCode);

            const result = await request.query(`
                SELECT p.*, u.IsPaid AS userIsPaid, u.PaidUntil AS userPaidUntil
                FROM Payments p
                JOIN Users u ON p.UserId = u.Id
                WHERE p.OrderCode = @orderCode
            `);

            if (result.recordset.length === 0) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy mã đơn hàng.' });
            }

            const payment = result.recordset[0];
            const isPaidActive = payment.userIsPaid === true && payment.userPaidUntil && new Date(payment.userPaidUntil) > new Date();

            res.json({
                success: true,
                orderCode: payment.OrderCode,
                status: payment.Status,
                isPaid: payment.Status === 'PAID',
                userSubscription: {
                    isPaidActive,
                    paidUntil: payment.userPaidUntil
                }
            });

        } catch (err) {
            console.error('[Payment] Lỗi khi kiểm tra trạng thái đơn hàng:', err);
            res.status(500).json({ success: false, message: 'Lỗi server khi tra cứu đơn hàng.' });
        }
    });

    // 4. GET /payment/subscription/:userId - Lấy thông tin đặc quyền hiện tại của người dùng
    app.get('/payment/subscription/:userId', async (req, res) => {
        try {
            const { userId } = req.params;
            const request = new sql.Request();
            request.input('userId', sql.UniqueIdentifier, userId);

            const result = await request.query(`
                SELECT Id, Username, IsPaid, PaidUntil 
                FROM Users 
                WHERE Id = @userId
            `);

            if (result.recordset.length === 0) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng.' });
            }

            const user = result.recordset[0];
            const now = new Date();
            const paidUntil = user.PaidUntil ? new Date(user.PaidUntil) : null;
            const isPaidActive = Boolean(user.IsPaid && paidUntil && paidUntil > now);
            const daysRemaining = isPaidActive ? Math.ceil((paidUntil - now) / (1000 * 60 * 60 * 24)) : 0;

            res.json({
                success: true,
                isPaid: isPaidActive,
                paidUntil: user.PaidUntil,
                daysRemaining
            });

        } catch (err) {
            console.error('[Payment] Lỗi khi lấy thông tin subscription:', err);
            res.status(500).json({ success: false, message: 'Lỗi server khi lấy thông tin gói.' });
        }
    });

    // 5. POST /payment/simulate-success/:orderCode - Hỗ trợ Demo/Test giả lập thanh toán thành công tức thì
    app.post('/payment/simulate-success/:orderCode', async (req, res) => {
        try {
            const { orderCode } = req.params;
            const request = new sql.Request();
            request.input('orderCode', sql.BigInt, orderCode);

            const findRes = await request.query("SELECT * FROM Payments WHERE OrderCode = @orderCode");
            const payment = findRes.recordset[0];

            if (!payment) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy đơn hàng cần giả lập.' });
            }

            const updateReq = new sql.Request();
            updateReq.input('orderCode', sql.BigInt, orderCode);
            updateReq.input('userId', sql.UniqueIdentifier, payment.UserId);

            // Cập nhật trạng thái PAID
            await updateReq.query(`
                UPDATE Payments 
                SET Status = 'PAID', PaidAt = GETDATE() 
                WHERE OrderCode = @orderCode
            `);

            // Gia hạn 30 ngày
            await updateReq.query(`
                UPDATE Users 
                SET IsPaid = 1,
                    PaidUntil = DATEADD(day, 30, CASE WHEN PaidUntil > GETDATE() THEN PaidUntil ELSE GETDATE() END)
                WHERE Id = @userId
            `);

            res.json({
                success: true,
                message: 'Giả lập thanh toán thành công! Tài khoản đã được kích hoạt 30 ngày đặc quyền.'
            });

        } catch (err) {
            console.error('[Payment] Lỗi giả lập thanh toán:', err);
            res.status(500).json({ success: false, message: 'Lỗi server: ' + err.message });
        }
    });
};
