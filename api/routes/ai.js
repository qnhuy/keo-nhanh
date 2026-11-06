module.exports = function registerRoutes({ app, sql }) {

    /**
     * Thuật toán lọc dự phòng (Safe Fallback Matcher)
     * Đảm bảo hệ thống luôn trả về kết quả chính xác ngay cả khi chưa có API Key
     */
    function fallbackMatcher(message, openMatches) {
        const text = (message || '').toLowerCase();
        let matched = [];

        // 1. Lọc theo địa điểm / Quận huyện
        const locationKeywords = [
            'quận 1', 'quận 2', 'quận 3', 'quận 4', 'quận 5', 'quận 6', 'quận 7', 'quận 8',
            'quận 9', 'quận 10', 'quận 11', 'quận 12', 'tân bình', 'bình thạnh', 'phú nhuận',
            'gò vấp', 'bình tân', 'thủ đức', 'hà nội', 'cầu giấy', 'đà nẵng', 'hải châu'
        ];
        const matchedLoc = locationKeywords.find(loc => text.includes(loc));

        // 2. Lọc theo thời gian
        const isToday = text.includes('hôm nay') || text.includes('tối nay') || text.includes('chiều nay');
        const isTomorrow = text.includes('ngày mai') || text.includes('mai');
        const now = new Date();

        matched = openMatches.filter(m => {
            const loc = (m.Location || '').toLowerCase();
            const field = (m.FieldName || '').toLowerCase();
            const pTime = new Date(m.PlayTime);

            let locOk = true;
            if (matchedLoc) {
                locOk = loc.includes(matchedLoc) || field.includes(matchedLoc);
            }

            let timeOk = true;
            if (isToday) {
                timeOk = pTime.toDateString() === now.toDateString();
            } else if (isTomorrow) {
                const tomorrow = new Date();
                tomorrow.setDate(now.getDate() + 1);
                timeOk = pTime.toDateString() === tomorrow.toDateString();
            }

            return locOk && timeOk;
        });

        // Nếu lọc quá chặt không có kết quả, lấy các kèo sắp diễn ra nhất
        if (matched.length === 0 && openMatches.length > 0) {
            matched = openMatches.slice(0, 3);
            return {
                reply: `Hiện tại chưa có kèo nào hoàn toàn khớp với tìm kiếm của bạn. Dưới đây là ${matched.length} kèo đấu đang mở gần nhất trong hệ thống mà bạn có thể tham khảo:`,
                recommendedMatchIds: matched.map(m => m.Id)
            };
        }

        const count = Math.min(matched.length, 4);
        const topMatches = matched.slice(0, count);

        let reply = `Tôi đã tìm thấy ${topMatches.length} kèo đấu đang mở phù hợp với yêu cầu của bạn:`;
        if (matchedLoc) {
            reply = `Tôi đã tìm thấy ${topMatches.length} kèo đấu đang mở tại khu vực ${matchedLoc.toUpperCase()} phù hợp với yêu cầu của bạn:`;
        }

        return {
            reply,
            recommendedMatchIds: topMatches.map(m => m.Id)
        };
    }

    // POST /api/ai/chat - Trợ lý AI tư vấn và gợi ý kèo đấu
    app.post('/ai/chat', async (req, res) => {
        try {
            const { message, history } = req.body;
            if (!message || typeof message !== 'string') {
                return res.status(400).json({ success: false, message: 'Nội dung tin nhắn không hợp lệ' });
            }

            // 1. Lấy danh sách các kèo đấu đang mở (Status = 'open') từ SQL Server
            const matchesQuery = `
                SELECT m.Id, m.FieldName, m.Location, m.PlayTime, m.Status,
                       m.Latitude, m.Longitude,
                       t.Id AS CreatorTeamId, t.Name AS CreatorTeamName,
                       t.SkillLevel AS CreatorSkillLevel, t.Logo AS CreatorTeamLogo
                FROM Matches m
                LEFT JOIN Teams t ON m.CreatorTeamId = t.Id
                WHERE LOWER(m.Status) = 'open'
                ORDER BY m.PlayTime ASC
            `;
            const dbResult = await sql.query(matchesQuery);
            const openMatches = dbResult.recordset || [];

            // Chuyển đổi dữ liệu chuẩn cho Flutter MatchModel
            const matchMap = new Map();
            for (const row of openMatches) {
                matchMap.set(row.Id, {
                    _id: row.Id,
                    status: row.Status || 'open',
                    playTime: row.PlayTime ? new Date(row.PlayTime).toISOString() : new Date().toISOString(),
                    fieldName: row.FieldName || 'Sân bóng',
                    location: row.Location || 'Chưa rõ',
                    latitude: row.Latitude,
                    longitude: row.Longitude,
                    creatorTeamId: {
                        _id: row.CreatorTeamId,
                        name: row.CreatorTeamName || 'Đội bóng',
                        skillLevel: row.CreatorSkillLevel || 'Trung bình',
                        logo: row.CreatorTeamLogo || ''
                    }
                });
            }

            const apiKey = process.env.GEMINI_API_KEY;
            const model = process.env.GEMINI_MODEL || 'gemini-1.5-flash';

            // Nếu có API Key, gọi Google Gemini API
            if (apiKey && apiKey.trim() !== '') {
                try {
                    const compactMatchesList = openMatches.map(m => ({
                        id: m.Id,
                        san: m.FieldName,
                        diaChi: m.Location,
                        thoiGian: m.PlayTime,
                        doiDangKeo: m.CreatorTeamName,
                        trinhDo: m.CreatorSkillLevel
                    }));

                    const systemInstructionText = `
Bạn là Trợ lý AI thể thao thông minh của nền tảng bóng đá Kèo Nhanh.
Nhiệm vụ của bạn là tư vấn, phân tích và gợi ý các trận đấu bóng đá phù hợp với yêu cầu của người dùng.

DANH SÁCH CÁC KÈO ĐẤU ĐANG MỞ THỰC TẾ TRONG HỆ THỐNG:
${JSON.stringify(compactMatchesList, null, 2)}

QUY TẮC BẮT BUỘC:
1. Trả lời bằng tiếng Việt lịch sự, thân thiện, súc tích. Tuyệt đối không sử dụng bất kỳ biểu tượng cảm xúc (emoji) nào trong toàn bộ câu trả lời.
2. CHỈ gợi ý các kèo đấu có trong danh sách trên. Tuyệt đối không bịa đặt kèo đấu, sân bóng hay đội bóng không có thật.
3. Nếu không có kèo phù hợp, giải thích ngắn gọn và gợi ý người dùng tạo kèo mới.
4. Trả về kết quả duy nhất ở định dạng JSON hợp lệ tuân thủ schema sau:
{
  "reply": "Nội dung phản hồi của bạn gửi tới người dùng...",
  "recommendedMatchIds": ["id1", "id2"]
}
`;

                    // Chuẩn hóa history
                    const contents = [];
                    if (Array.isArray(history)) {
                        for (const h of history.slice(-6)) { // Giữ tối đa 6 tin nhắn gần nhất
                            if (h.role && h.text) {
                                contents.push({
                                    role: h.role === 'model' ? 'model' : 'user',
                                    parts: [{ text: h.text }]
                                });
                            }
                        }
                    }
                    contents.push({
                        role: 'user',
                        parts: [{ text: message }]
                    });

                    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
                    const geminiResponse = await fetch(geminiUrl, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            systemInstruction: {
                                parts: [{ text: systemInstructionText }]
                            },
                            contents: contents,
                            generationConfig: {
                                temperature: 0.3,
                                responseMimeType: 'application/json'
                            }
                        })
                    });

                    if (geminiResponse.ok) {
                        const geminiData = await geminiResponse.json();
                        const candidate = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
                        if (candidate) {
                            const parsed = JSON.parse(candidate);
                            const recommendedIds = Array.isArray(parsed.recommendedMatchIds) ? parsed.recommendedMatchIds : [];
                            const recommendedMatches = recommendedIds
                                .map(id => matchMap.get(id))
                                .filter(Boolean);

                            return res.json({
                                success: true,
                                reply: parsed.reply || 'Dưới đây là một số kèo đấu phù hợp với bạn:',
                                matches: recommendedMatches,
                                source: 'gemini'
                            });
                        }
                    } else {
                        const errText = await geminiResponse.text();
                        console.warn('Gemini API returned error, falling back to local matcher:', errText);
                    }
                } catch (geminiError) {
                    console.error('Lỗi khi gọi Gemini API:', geminiError);
                    // Tiếp tục rơi xuống fallback bên dưới
                }
            }

            // Fallback khi chưa cấu hình API key hoặc gọi Gemini lỗi
            const fallbackResult = fallbackMatcher(message, openMatches);
            const recommendedMatches = fallbackResult.recommendedMatchIds
                .map(id => matchMap.get(id))
                .filter(Boolean);

            return res.json({
                success: true,
                reply: fallbackResult.reply,
                matches: recommendedMatches,
                source: 'fallback'
            });

        } catch (e) {
            console.error('Error in /api/ai/chat:', e);
            res.status(500).json({
                success: false,
                reply: 'Hệ thống đang gặp sự cố khi xử lý yêu cầu. Vui lòng thử lại sau ít phút.',
                matches: []
            });
        }
    });

};
