const { PayOS } = require('@payos/node');

const clientId = process.env.PAYOS_CLIENT_ID;
const apiKey = process.env.PAYOS_API_KEY;
const checksumKey = process.env.PAYOS_CHECKSUM_KEY;

const isConfigured = Boolean(
    clientId &&
    apiKey &&
    checksumKey &&
    !clientId.includes('your_') &&
    !apiKey.includes('your_') &&
    !checksumKey.includes('your_')
);

let payosClient = null;
if (isConfigured) {
    try {
        payosClient = new PayOS({
            clientId,
            apiKey,
            checksumKey
        });
        console.log('[PayOS] Cổng thanh toán PayOS đã sẵn sàng (Production/Sandbox Mode).');
    } catch (e) {
        console.warn('[PayOS] Lỗi khi khởi tạo PayOS client, chuyển về Mock Mode:', e.message);
    }
} else {
    console.log('[PayOS] Chưa cấu hình đầy đủ API Key trong .env. Kích hoạt Safe Mock Mode để test demo.');
}

/**
 * Tạo link thanh toán PayOS hoặc Mock VietQR nếu chưa có API Key
 */
async function createPaymentLink({ orderCode, amount = 29000, description = 'KEO NHANH 1 THANG', returnUrl, cancelUrl }) {
    if (isConfigured && payosClient) {
        try {
            const result = await payosClient.paymentRequests.create({
                orderCode,
                amount,
                description,
                returnUrl: returnUrl || 'http://localhost:3000/api/payment/success',
                cancelUrl: cancelUrl || 'http://localhost:3000/api/payment/cancel'
            });
            return {
                isMock: false,
                orderCode: result.orderCode || orderCode,
                amount: result.amount || amount,
                description: result.description || description,
                accountNumber: result.accountNumber || '0333888999',
                accountName: result.accountName || 'CONG DONG KEO NHANH',
                bin: result.bin || '970422',
                qrCode: result.qrCode || `https://img.vietqr.io/image/970422-0333888999-compact2.png?amount=${amount}&addInfo=${encodeURIComponent(description)}&accountName=CONG%20DONG%20KEO%20NHANH`,
                checkoutUrl: result.checkoutUrl || `https://pay.payos.vn/web/${result.paymentLinkId || ''}`,
                paymentLinkId: result.paymentLinkId
            };
        } catch (err) {
            console.error('[PayOS] Lỗi khi gọi PayOS API, fallback sang Mock VietQR:', err.message);
        }
    }

    // Fallback Mock VietQR chuẩn NAPAS 247
    const mockBin = '970422'; // MBBank
    const mockAccount = '0333888999';
    const mockAccountName = 'KEONHANH PLATFORM';
    const encodedDesc = encodeURIComponent(description);
    const vietQrUrl = `https://img.vietqr.io/image/${mockBin}-${mockAccount}-compact2.png?amount=${amount}&addInfo=${encodedDesc}&accountName=${encodeURIComponent(mockAccountName)}`;

    return {
        isMock: true,
        orderCode,
        amount,
        description,
        accountNumber: mockAccount,
        accountName: mockAccountName,
        bin: mockBin,
        bankName: 'MBBank (Ngân Hàng Quân Đội)',
        qrCode: vietQrUrl,
        checkoutUrl: `https://pay.payos.vn/web/mock-${orderCode}`
    };
}

/**
 * Xác thực chữ ký webhook từ PayOS
 */
async function verifyWebhookData(webhookBody) {
    if (isConfigured && payosClient) {
        return await payosClient.webhooks.verify(webhookBody);
    }
    // Nếu mock mode, bỏ qua verify và trả về data
    return webhookBody?.data || webhookBody;
}

module.exports = {
    isConfigured,
    createPaymentLink,
    verifyWebhookData
};
