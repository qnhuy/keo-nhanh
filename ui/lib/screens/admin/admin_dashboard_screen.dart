import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/admin_models.dart';
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../services/admin_service.dart';
import '../../services/match_service.dart';
import '../../services/team_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

/// Màn hình Bảng điều khiển Quản trị viên (Admin Dashboard)
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State Tab 1: Thống kê
  AdminStatsModel? _stats;
  bool _statsLoading = true;

  // State Tab 2: Kèo & Đội
  int _moderationType = 0; // 0: Kèo đấu, 1: Đội bóng
  List<MatchModel> _allMatches = [];
  List<TeamModel> _allTeams = [];
  bool _modLoading = true;

  // State Tab 3: Người dùng
  List<AdminUserModel> _allUsers = [];
  List<AdminUserModel> _filteredUsers = [];
  bool _usersLoading = true;
  final TextEditingController _userSearchController = TextEditingController();

  // State Tab 4: Thông báo
  final TextEditingController _notifTitleController = TextEditingController();
  final TextEditingController _notifMessageController = TextEditingController();
  bool _sendingBroadcast = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
    _fetchStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchController.dispose();
    _notifTitleController.dispose();
    _notifMessageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == 0 && _stats == null) {
      _fetchStats();
    } else if (index == 1 && (_allMatches.isEmpty && _allTeams.isEmpty)) {
      _fetchModerationData();
    } else if (index == 2 && _allUsers.isEmpty) {
      _fetchUsers();
    }
  }

  // ===========================================================================
  // LOGIC TAB 1: THỐNG KÊ
  // ===========================================================================

  Future<void> _fetchStats() async {
    setState(() => _statsLoading = true);
    final data = await AdminService.getStats();
    if (mounted) {
      setState(() {
        _stats = data;
        _statsLoading = false;
      });
    }
  }

  // ===========================================================================
  // LOGIC TAB 2: KIỂM DUYỆT KÈO VÀ ĐỘI BÓNG
  // ===========================================================================

  Future<void> _fetchModerationData() async {
    setState(() => _modLoading = true);
    if (_moderationType == 0) {
      final matches = await MatchService.getAllMatches();
      if (mounted) {
        setState(() {
          _allMatches = matches;
          _modLoading = false;
        });
      }
    } else {
      final teams = await TeamService.getAllTeams();
      if (mounted) {
        setState(() {
          _allTeams = teams;
          _modLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteMatch(MatchModel match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa kèo đấu'),
        content: Text('Bạn có chắc muốn xóa vĩnh viễn kèo của "${match.creatorTeam.name}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await AdminService.deleteMatch(match.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Đã xóa kèo đấu thành công'),
            backgroundColor: res['success'] ? const Color(0xFF16A34A) : Colors.red,
          ),
        );
        if (res['success']) _fetchModerationData();
      }
    }
  }

  Future<void> _confirmDeleteTeam(TeamModel team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận giải tán đội'),
        content: Text('Giải tán đội "${team.name}" sẽ xóa toàn bộ thành viên và các kèo đấu liên quan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Giải tán', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await AdminService.deleteTeam(team.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Đã giải tán đội bóng thành công'),
            backgroundColor: res['success'] ? const Color(0xFF16A34A) : Colors.red,
          ),
        );
        if (res['success']) _fetchModerationData();
      }
    }
  }

  // ===========================================================================
  // LOGIC TAB 3: NGƯỜI DÙNG VÀ PHÂN QUYỀN
  // ===========================================================================

  Future<void> _fetchUsers() async {
    setState(() => _usersLoading = true);
    final users = await AdminService.getAllUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _usersLoading = false;
      });
    }
  }

  void _onSearchUsers(String keyword) {
    final query = keyword.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((u) {
          return u.username.toLowerCase().contains(query) ||
              u.fullName.toLowerCase().contains(query) ||
              u.phone.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _changeRole(AdminUserModel user, String newRole) async {
    if (user.role.toLowerCase() == newRole.toLowerCase()) return;
    final res = await AdminService.updateUserRole(userId: user.id, newRole: newRole);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Đã cập nhật phân quyền'),
          backgroundColor: res['success'] ? const Color(0xFF16A34A) : Colors.red,
        ),
      );
      if (res['success']) _fetchUsers();
    }
  }

  // ===========================================================================
  // LOGIC TAB 4: THÔNG BÁO HỆ THỐNG (BROADCAST)
  // ===========================================================================

  Future<void> _handleSendBroadcast() async {
    final title = _notifTitleController.text.trim();
    final message = _notifMessageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ tiêu đề và nội dung thông báo!')),
      );
      return;
    }

    setState(() => _sendingBroadcast = true);
    final res = await AdminService.broadcastNotification(
      title: title,
      message: message,
    );

    if (mounted) {
      setState(() => _sendingBroadcast = false);
      if (res['success'] == true) {
        _notifTitleController.clear();
        _notifMessageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Đã gửi thông báo thành công!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gửi thông báo thất bại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // GIAO DIỆN CHÍNH (BUILD)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Quản Trị Hệ Thống',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF16A34A),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF16A34A),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.sports_soccer_outlined), text: 'Kèo & Đội'),
            Tab(icon: Icon(Icons.people_outline), text: 'Tài khoản'),
            Tab(icon: Icon(Icons.campaign_outlined), text: 'Thông báo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildModerationTab(),
          _buildUsersTab(),
          _buildBroadcastTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: TỔNG QUAN (OVERVIEW)
  // ===========================================================================

  Widget _buildOverviewTab() {
    if (_statsLoading) {
      return const LoadingView(message: 'Đang tải số liệu thống kê...');
    }

    if (_stats == null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Không thể tải thống kê',
        actionLabel: 'Thử lại',
        onAction: _fetchStats,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: const Color(0xFF16A34A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chỉ số hoạt động',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.45,
              children: [
                _buildKpiCard(
                  title: 'Người dùng',
                  value: _stats!.totalUsers.toString(),
                  icon: Icons.people_outline,
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                ),
                _buildKpiCard(
                  title: 'Đội bóng',
                  value: _stats!.totalTeams.toString(),
                  icon: Icons.shield_outlined,
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFF5F3FF),
                ),
                _buildKpiCard(
                  title: 'Kèo đang mở',
                  value: _stats!.openMatches.toString(),
                  icon: Icons.sports_soccer,
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                ),
                _buildKpiCard(
                  title: 'Kèo đã ghép đối',
                  value: _stats!.matchedMatches.toString(),
                  icon: Icons.handshake_outlined,
                  color: const Color(0xFFEA580C),
                  bgColor: const Color(0xFFFFF7ED),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      const Text(
                        'Tổng số trận đấu trong hệ thống',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        '${_stats!.totalMatches} trận',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _stats!.totalMatches > 0
                          ? _stats!.matchedMatches / _stats!.totalMatches
                          : 0.0,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFDCFCE7),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tỷ lệ ghép đối thành công: ${_stats!.totalMatches > 0 ? ((_stats!.matchedMatches / _stats!.totalMatches) * 100).toStringAsFixed(1) : 0}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: KIỂM DUYỆT (KÈO & ĐỘI)
  // ===========================================================================

  Widget _buildModerationTab() {
    return Column(
      children: [
        // Thanh chọn loại danh mục
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Kèo đấu')),
                  selected: _moderationType == 0,
                  selectedColor: const Color(0xFFDCFCE7),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _moderationType == 0 ? const Color(0xFF15803D) : Colors.grey[700],
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _moderationType = 0);
                      _fetchModerationData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Đội bóng')),
                  selected: _moderationType == 1,
                  selectedColor: const Color(0xFFDCFCE7),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _moderationType == 1 ? const Color(0xFF15803D) : Colors.grey[700],
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _moderationType = 1);
                      _fetchModerationData();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),

        // Danh sách hiển thị
        Expanded(
          child: _modLoading
              ? const LoadingView(message: 'Đang tải danh sách...')
              : _moderationType == 0
                  ? _buildMatchesList()
                  : _buildTeamsList(),
        ),
      ],
    );
  }

  Widget _buildMatchesList() {
    if (_allMatches.isEmpty) {
      return const EmptyState(
        icon: Icons.sports_soccer,
        title: 'Chưa có kèo đấu nào',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchModerationData,
      color: const Color(0xFF16A34A),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _allMatches.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final m = _allMatches[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.creatorTeam.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: m.status, fontSize: 11),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sân: ${m.fieldName}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thời gian: ${DateTimeFormatter.formatMatchTime(m.playTime)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  tooltip: 'Xóa kèo vi phạm',
                  onPressed: () => _confirmDeleteMatch(m),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamsList() {
    if (_allTeams.isEmpty) {
      return const EmptyState(
        icon: Icons.shield_outlined,
        title: 'Chưa có đội bóng nào',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchModerationData,
      color: const Color(0xFF16A34A),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _allTeams.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final t = _allTeams[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF15803D), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đội trưởng: ${t.captainName}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      Text(
                        'Khu vực: ${t.location.isNotEmpty ? t.location : "Chưa cập nhật"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  tooltip: 'Giải tán đội',
                  onPressed: () => _confirmDeleteTeam(t),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // TAB 3: NGƯỜI DÙNG & PHÂN QUYỀN
  // ===========================================================================

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Ô tìm kiếm tài khoản
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _userSearchController,
            onChanged: _onSearchUsers,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên tài khoản hoặc họ tên...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _userSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _userSearchController.clear();
                        _onSearchUsers('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),

        // Danh sách tài khoản
        Expanded(
          child: _usersLoading
              ? const LoadingView(message: 'Đang tải danh sách người dùng...')
              : _filteredUsers.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_search_outlined,
                      title: 'Không tìm thấy người dùng phù hợp',
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchUsers,
                      color: const Color(0xFF16A34A),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final u = _filteredUsers[i];
                          final isUserAdmin = u.role.toLowerCase() == 'admin';
                          final isCaptain = u.role.toLowerCase() == 'captain';

                          Color roleBg = const Color(0xFFF3F4F6);
                          Color roleFg = Colors.grey[700]!;
                          if (isUserAdmin) {
                            roleBg = const Color(0xFFFEE2E2);
                            roleFg = const Color(0xFFDC2626);
                          } else if (isCaptain) {
                            roleBg = const Color(0xFFDCFCE7);
                            roleFg = const Color(0xFF15803D);
                          }

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: roleBg,
                                  child: Icon(
                                    isUserAdmin
                                        ? Icons.admin_panel_settings_outlined
                                        : isCaptain
                                            ? Icons.shield_outlined
                                            : Icons.person_outline,
                                    color: roleFg,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '@${u.username}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: roleBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    u.role.toUpperCase(),
                                    style: TextStyle(
                                      color: roleFg,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (role) => _changeRole(u, role),
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'admin',
                                      child: Text('Cấp quyền Admin'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'captain',
                                      child: Text('Đặt làm Đội trưởng'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'player',
                                      child: Text('Đặt làm Cầu thủ'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: PHÁT THÔNG BÁO HỆ THỐNG
  // ===========================================================================

  Widget _buildBroadcastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.campaign_outlined, color: Color(0xFF15803D), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phát thông báo hệ thống',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Thông báo sẽ hiển thị trên chuông của tất cả tài khoản',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tiêu đề
                const Text(
                  'Tiêu đề thông báo',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notifTitleController,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Bảo trì hệ thống hoặc Giải đấu mới',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nội dung
                const Text(
                  'Nội dung chi tiết',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notifMessageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Nhập nội dung thông báo gửi đến các cầu thủ...',
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nút gửi
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _sendingBroadcast ? null : _handleSendBroadcast,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _sendingBroadcast
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_outlined, size: 18),
                    label: Text(
                      _sendingBroadcast ? 'Đang gửi thông báo...' : 'Gửi thông báo toàn hệ thống',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
