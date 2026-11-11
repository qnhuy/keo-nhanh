const { PayOS } = require('@payos/node');
const QRCode = require('qrcode');

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
 * Sinh mã VietQR (Base64 PNG) chuẩn NAPAS 247
 */
async function generateVietQrData({ bin, accountNo, accountName, amount, description, orderCode }) {
    // 1. Thử gọi API VietQR v2 để nhận mẫu template VietQR chính thức (kèm logo MBBank và Napas 247)
    try {
        const vqRes = await fetch('https://api.vietqr.io/v2/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                accountNo,
                accountName,
                acqId: bin,
                amount,
                addInfo: description,
                format: 'text',
                template: 'compact2'
            })
        });
        const vqData = await vqRes.json();
        if (vqData.code === '00' && vqData.data && vqData.data.qrDataURL) {
            return {
                qrCode: vqData.data.qrDataURL,
                rawString: vqData.data.qrCode
            };
        }
    } catch (e) {
        console.warn('[PayOS] VietQR API v2 call error, falling back to local QRCode generator:', e.message);
    }

    // 2. Fallback ngoại tuyến: Tạo mã QR PNG trực tiếp bằng thư viện qrcode
    const fallbackText = `https://pay.payos.vn/web/mock-${orderCode}`;
    const localDataUrl = await QRCode.toDataURL(fallbackText, {
        width: 350,
        margin: 2,
        color: { dark: '#0F172A', light: '#FFFFFF' }
    });

    return {
        qrCode: localDataUrl,
        rawString: fallbackText
    };
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

            let qrImage = result.qrCode;
            // Nếu result.qrCode là chuỗi text EMVCo (không phải URL hay Data URL), chuyển sang Data URL PNG
            if (qrImage && !qrImage.startsWith('http') && !qrImage.startsWith('data:image')) {
                qrImage = await QRCode.toDataURL(qrImage, { width: 350, margin: 2 });
            }

            return {
                isMock: false,
                orderCode: result.orderCode || orderCode,
                amount: result.amount || amount,
                description: result.description || description,
                accountNumber: result.accountNumber || '0333888999',
                accountName: result.accountName || 'CONG DONG KEO NHANH',
                bin: result.bin || '970422',
                bankName: 'MBBank (Ngân Hàng Quân Đội)',
                qrCode: qrImage || result.checkoutUrl,
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

    const qrResult = await generateVietQrData({
        bin: mockBin,
        accountNo: mockAccount,
        accountName: mockAccountName,
        amount,
        description,
        orderCode
    });

    return {
        isMock: true,
        orderCode,
        amount,
        description,
        accountNumber: mockAccount,
        accountName: mockAccountName,
        bin: mockBin,
        bankName: 'MBBank (Ngân Hàng Quân Đội)',
        qrCode: qrResult.qrCode,
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
