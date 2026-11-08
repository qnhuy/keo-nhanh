import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/services.dart';

/// Màn hình Chat với Trợ lý AI gợi ý kèo đấu
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    'Kèo bóng mở hôm nay',
    'Kèo khu vực Tân Bình',
    'Kèo khu vực Quận 7',
    'Kèo cuối tuần này',
  ];

  @override
  void initState() {
    super.initState();
    // Khởi tạo tin nhắn chào mừng từ trợ lý AI
    _messages.add(
      AiChatMessage(
        id: 'welcome',
        text: 'Xin chào! Tôi là Trợ lý AI của Kèo Nhanh. Bạn đang muốn tìm kèo đấu ở khu vực nào, thời gian ra sao hoặc trình độ mong muốn thế nào? Hãy chia sẻ với tôi nhé!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? customText]) async {
    final text = (customText ?? _inputController.text).trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    final userMessage = AiChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await AiService.sendMessage(
        message: text,
        history: _messages,
      );

      final botMessage = AiChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: response.reply,
        isUser: false,
        timestamp: DateTime.now(),
        suggestedMatches: response.matches,
        isError: !response.success,
      );

      if (mounted) {
        setState(() {
          _messages.add(botMessage);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(
            AiChatMessage(
              id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
              text: 'Đã xảy ra sự cố khi kết nối. Vui lòng thử lại.',
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _handleResetChat() {
    setState(() {
      _messages.clear();
      _messages.add(
        AiChatMessage(
          id: 'welcome',
          text: 'Đoạn hội thoại đã được làm mới. Hãy cho tôi biết nhu cầu tìm kiếm trận đấu của bạn!',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Danh sách tin nhắn
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (ctx, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildLoadingBubble();
                  }
                  final msg = _messages[index];
                  return _buildMessageItem(msg);
                },
              ),
            ),

            // Thanh Quick Prompts (khi không trong trạng thái loading)
            if (!_isLoading) _buildQuickPrompts(),

            // Thanh nhập tin nhắn
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE2E8F0), height: 1),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1E293B)),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trợ lý Kèo Nhanh AI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Gợi ý kèo thông minh',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Làm mới hội thoại',
          icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
          onPressed: _handleResetChat,
        ),
      ],
    );
  }

  Widget _buildMessageItem(AiChatMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: msg.isError ? const Color(0xFFFEF2F2) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: msg.isError ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isError ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Hiển thị danh sách thẻ kèo nếu AI có gợi ý
          if (msg.suggestedMatches.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'KÈO ĐẤU ĐỀ XUẤT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ...msg.suggestedMatches.map((m) => _buildMatchCard(m)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchCard(MatchModel m) {
    String timeStr = 'Chưa xác định';
    if (m.playTime != null) {
      final dt = m.playTime!;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      timeStr = '$hour:$minute - $day/$month/${dt.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/matchDetail', extra: m.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        m.fieldName.isNotEmpty ? m.fieldName : 'Sân bóng',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Đang mở',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.groups_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      m.creatorTeam.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ],
                ),
                if (m.location != null && m.location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          m.location!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Xem chi tiết & Bắt kèo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFF16A34A)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Trợ lý đang phân tích dữ liệu...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickPrompts.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final prompt = _quickPrompts[i];
          return ActionChip(
            label: Text(
              prompt,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
              ),
            ),
            backgroundColor: const Color(0xFFF0FDF4),
            side: const BorderSide(color: Color(0xFFBBF7D0)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _handleSendMessage(prompt),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSendMessage(),
              decoration: InputDecoration(
                hintText: 'Hỏi về kèo đấu, khu vực, giờ đá...',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF16A34A)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _isLoading ? null : () => _handleSendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
