import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../models/match_model.dart';
import '../../services/match_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/notification_button.dart';
import '../../widgets/status_badge.dart';

/// Màn hình "Trang Chủ"
/// Hiển thị lời chào, banner tạo kèo nhanh, các nút tính năng chính và danh sách các kèo đấu nổi bật
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ===========================================================================
  // PHẦN 1: CÁC BIẾN QUẢN LÝ DỮ LIỆU (STATE)
  // ===========================================================================

  List<MatchModel> _matches = []; // Danh sách kèo đấu nổi bật
  bool _loading = true; // Trạng thái đang tải dữ liệu kèo
  String? _errorMessage; // Thông báo lỗi khi không thể tải kèo

  @override
  void initState() {
    super.initState();
    _fetchMatches(); // Tải danh sách kèo khi mở trang chủ
  }

  // ===========================================================================
  // PHẦN 2: CÁC HÀM XỬ LÝ (GỌI SERVICE)
  // ===========================================================================

  /// Tải danh sách các trận đấu từ máy chủ qua MatchService
  Future<void> _fetchMatches() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final matchesData = await MatchService.getAllMatches();
      if (mounted) {
        setState(() {
          _matches = matchesData;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
      debugPrint("Lỗi tải danh sách kèo đấu: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Hộp thoại nhắc đăng nhập khi truy cập tính năng cần tài khoản
  void _showLoginAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Yêu cầu đăng nhập',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn cần đăng nhập để tìm và xin gia nhập đội bóng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login');
            },
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PHẦN 3: GIAO DIỆN CHÍNH (BUILD)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final String username = isLoggedIn ? (auth.username ?? "Người dùng") : "";

    return Scaffold(
      backgroundColor: const Color(0xFFF4FDF4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchMatches,
          color: const Color(0xFF22C55E),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // 1. Lời chào & Nút Đăng nhập/Hồ sơ
              _buildHeader(isLoggedIn, username),
              const SizedBox(height: 20),

              // 2. Banner giới thiệu & Nút Tạo kèo nhanh
              _buildHeroBanner(),
              const SizedBox(height: 16),

              // 2.1. Thẻ Trợ lý AI gợi ý kèo đấu
              _buildAiAssistantCard(),
              const SizedBox(height: 24),

              // 3. Khối 4 tính năng chính (Tìm đội, Tìm người, Tạo đội, Tạo kèo)
              _buildFeatureGrid(isLoggedIn),
              const SizedBox(height: 32),

              // 4. Tiêu đề danh sách kèo nổi bật
              _buildMatchSectionHeader(),
              const SizedBox(height: 16),

              // 5. Danh sách các kèo nổi bật
              _buildMatchList(),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PHẦN 4: CÁC WIDGET CON (TÁCH NHỎ CODE ĐỂ ĐƠN GIẢN VÀ DỄ HIỂU)
  // ===========================================================================

  /// Header trên cùng: Lời chào và Nút Đăng nhập/Đăng ký hoặc Avatar
  Widget _buildHeader(bool isLoggedIn, String username) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isLoggedIn ? 'Xin chào, $username' : 'KeoNhanh',
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF166534),
            fontWeight: FontWeight.w800,
          ),
        ),
        if (isLoggedIn)
          Row(
            children: [
              IconButton(
                onPressed: () => context.push('/ai-chat'),
                tooltip: 'Trợ lý AI',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF16A34A), size: 18),
                ),
              ),
              const NotificationButton(),
            ],
          )
        else
          Row(
            children: [
              IconButton(
                onPressed: () => context.push('/ai-chat'),
                tooltip: 'Trợ lý AI',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF16A34A), size: 18),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => context.push('/register'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0FDF4),
                  side: const BorderSide(color: Color(0xFF4ADE80)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Đăng ký',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Thẻ Trợ lý AI gợi ý kèo đấu
  Widget _buildAiAssistantCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/ai-chat'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trợ lý Kèo Nhanh AI',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hỏi đáp và gợi ý kèo đấu thông minh',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF16A34A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Banner xanh lá cây nổi bật: "Đặt kèo cực nhanh"
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D14532D),
            offset: Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đặt kèo cực nhanh',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tìm đội - tìm người - ghép kèo chỉ trong vài phút',
            style: TextStyle(
              color: Color(0xFFDCFCE7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => context.push('/createMatch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Tạo kèo ngay',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Khối lưới 4 nút tính năng
  Widget _buildFeatureGrid(bool isLoggedIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tính năng chính',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF14532D),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildActionCard(
              title: 'Tìm đội',
              icon: Icons.groups,
              iconColor: const Color(0xFF22C55E),
              onTap: () {
                if (!isLoggedIn) {
                  _showLoginAlert(context);
                  return;
                }
                context.push('/findTeam');
              },
            ),
            const SizedBox(width: 12),
            _buildActionCard(
              title: 'Tìm người',
              icon: Icons.person_add,
              iconColor: const Color(0xFF3B82F6),
              onTap: () => context.go('/players'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionCard(
              title: 'Tạo đội',
              icon: Icons.security,
              iconColor: const Color(0xFFF59E0B),
              onTap: () => context.push('/createTeam'),
            ),
            const SizedBox(width: 12),
            _buildActionCard(
              title: 'Tạo kèo',
              icon: Icons.sports_soccer,
              iconColor: const Color(0xFFEF4444),
              onTap: () => context.push('/createMatch'),
            ),
          ],
        ),
      ],
    );
  }

  /// Tiêu đề khu vực kèo nổi bật
  Widget _buildMatchSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Kèo nổi bật',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF14532D),
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => context.push('/allMatches'),
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (!_loading)
              GestureDetector(
                onTap: _fetchMatches,
                child: const Icon(
                  Icons.refresh,
                  color: Color(0xFF22C55E),
                  size: 20,
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Khối danh sách kèo nổi bật (Xử lý trạng thái Loading / Error / Empty / List)
  Widget _buildMatchList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF22C55E)),
              SizedBox(height: 12),
              Text(
                'Đang tải kèo nổi bật...',
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFEE2E2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xFFEF4444)),
            const SizedBox(height: 10),
            Text(
              'Lỗi: $_errorMessage',
              style: const TextStyle(color: Color(0xFFDC2626)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCFCE7)),
        ),
        child: const Column(
          children: [
            Icon(Icons.sports_soccer, size: 40, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'Hiện chưa có kèo đấu nào đang tìm đối.',
              style: TextStyle(
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Hiển thị tối đa 5 kèo mới nhất
    return Column(
      children: _matches.take(5).map((item) => _buildMatchCard(item)).toList(),
    );
  }

  /// Thẻ hiển thị một kèo bóng đá
  Widget _buildMatchCard(MatchModel item) {
    return GestureDetector(
      onTap: () => context.push('/matchDetail', extra: {'matchId': item.id}),
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCFCE7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A16A34A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.creatorTeam.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF14532D),
                    ),
                  ),
                ),
                StatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.fieldName,
                    style: const TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  DateTimeFormatter.formatMatchTime(item.playTime),
                  style: const TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Xem / Tham gia kèo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thẻ nút chức năng (Tìm đội, Tìm người, Tạo đội, Tạo kèo)
  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCFCE7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A16A34A),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 36, color: iconColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14532D),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
