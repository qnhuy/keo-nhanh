import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/empty_state.dart';

/// Màn hình: TẤT CẢ KÈO ĐẤU ĐANG TÌM ĐỐI (AllMatchesScreen)
/// Chức năng: Hiển thị toàn bộ các trận đấu đang có trạng thái "Đang mở" (open).
/// Người dùng có thể xem danh sách, lọc và bấm vào để xem chi tiết hoặc bắt kèo.
class AllMatchesScreen extends StatefulWidget {
  const AllMatchesScreen({super.key});

  @override
  State<AllMatchesScreen> createState() => _AllMatchesScreenState();
}

class _AllMatchesScreenState extends State<AllMatchesScreen> {
  // ===========================================================================
  // PHẦN 1: CÁC BIẾN QUẢN LÝ DỮ LIỆU (STATE)
  // ===========================================================================

  // Danh sách các kèo đấu đang mở được lấy từ Service
  List<MatchModel> _matches = [];

  // Trạng thái đang tải dữ liệu từ máy chủ
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Tự động gọi Service tải danh sách kèo khi mở màn hình
    _fetchOpenMatches();
  }

  // ===========================================================================
  // PHẦN 2: CÁC HÀM XỬ LÝ (GỌI SERVICE)
  // ===========================================================================

  /// Lấy toàn bộ các kèo có trạng thái 'open' qua MatchService
  Future<void> _fetchOpenMatches() async {
    setState(() => _loading = true);

    try {
      final allMatches = await MatchService.getAllMatches();
      // Chỉ lọc các kèo đang tìm đối (status == 'open')
      final openMatches = allMatches.where((m) => m.status.toLowerCase() == 'open').toList();

      if (mounted) {
        setState(() => _matches = openMatches.reversed.toList());
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách tất cả kèo đang mở: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===========================================================================
  // PHẦN 3: GIAO DIỆN CHÍNH (BUILD)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Tất cả kèo đấu',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const LoadingView(message: 'Đang tải danh sách kèo...')
          : _matches.isEmpty
              ? _buildEmptyState()
              : _buildMatchList(),
    );
  }

  // ===========================================================================
  // PHẦN 4: CÁC THÀNH PHẦN GIAO DIỆN CON (WIDGETS)
  // ===========================================================================

  /// Widget: Giao diện khi chưa có kèo nào đang mở
  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.sports_soccer_outlined,
      title: 'Chưa có kèo nào đang mở',
      subtitle: 'Hiện tại chưa có đội nào tạo kèo đấu. Bạn có thể là người đầu tiên tạo kèo!',
      actionLabel: 'Tạo kèo ngay',
      onAction: () => context.push('/createMatch'),
    );
  }

  /// Widget: Danh sách các kèo đấu có hỗ trợ kéo vuốt làm mới
  Widget _buildMatchList() {
    return RefreshIndicator(
      onRefresh: _fetchOpenMatches,
      color: const Color(0xFF22C55E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matches.length,
        itemBuilder: (ctx, i) => _buildMatchCard(_matches[i]),
      ),
    );
  }

  /// Widget: Thẻ hiển thị một trận đấu
  Widget _buildMatchCard(MatchModel item) {
    return GestureDetector(
      onTap: () => context.push('/matchDetail', extra: {'matchId': item.id}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            // Dòng trên: Tên đội và huy hiệu Đang tìm đối
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.creatorTeam.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 12),

            // Dòng địa điểm sân bóng
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF666666)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.fieldName,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dòng thời gian thi đấu
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Color(0xFF666666)),
                const SizedBox(width: 8),
                Text(
                  DateTimeFormatter.formatMatchTime(item.playTime),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nút bấm chi tiết
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Xem chi tiết & Bắt kèo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
