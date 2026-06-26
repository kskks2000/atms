import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 960;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: !isDesktop ? const NavigationDrawerWidget() : null,
      body: Row(
        children: [
          // 1. Sidebar for Desktop
          if (isDesktop) const SidebarWidget(),
          
          // 2. Main Workspace
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar Header
                    _buildTopBar(context, authProvider, !isDesktop),
                    const SizedBox(height: 20),

                    // Anomaly Alert Banner
                    _buildAnomalyBanner(),
                    const SizedBox(height: 24),

                    // KPI Metrics Grid
                    _buildMetricGrid(size),
                    const SizedBox(height: 24),

                    // Two Column Boards (7:3 ratio)
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: _buildOrderBoard()),
                          const SizedBox(width: 24),
                          Expanded(flex: 3, child: _buildControlBoard()),
                        ],
                      )
                    else ...[
                      _buildOrderBoard(),
                      const SizedBox(height: 24),
                      _buildControlBoard(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildTopBar(BuildContext context, AuthProvider auth, bool showMenuButton) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (showMenuButton)
              IconButton(
                icon: const Icon(Icons.menu, color: AppColors.primary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            Text(
              '대시보드',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '[${auth.tenantId?.toUpperCase() ?? "TENANT"}] ${auth.userId ?? "User"} 님 (Planner)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.textSecondary),
              tooltip: '로그아웃',
              onPressed: () {
                auth.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnomalyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Amber 100
        border: const Border(left: BorderSide(color: AppColors.warning, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '[이상 대기 알림] 경기80아1234 (기흥 물류센터) 상차 하역 45분 경과 - 대기 지연 가산비 발생 우려.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92400E), // Amber 800
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(Size size) {
    final double childAspectRatio = size.width > 1200 ? 1.8 : 1.4;
    return GridView.count(
      crossAxisCount: size.width > 1200 ? 4 : (size.width > 600 ? 2 : 1),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: childAspectRatio,
      children: [
        _buildMetricCard(
          title: '금일 총 오더수',
          value: '154 건',
          trend: '전일 대비 +12%',
          icon: Icons.assignment_outlined,
          isTrendUp: true,
        ),
        _buildMetricCard(
          title: '배차 대기 오더',
          value: '12 건',
          trend: '긴급 오더 2건 포함',
          icon: Icons.pending_actions_outlined,
          isTrendUp: false,
          isWarning: true,
        ),
        _buildMetricCard(
          title: '운송 진행 차량',
          value: '48 대',
          trend: '정상 45 / 지연 3',
          icon: Icons.local_shipping_outlined,
          isTrendUp: null,
        ),
        _buildMetricCard(
          title: '금일 정산 예정액',
          value: '2,540 만원',
          trend: '마감 확정 85% 완료',
          icon: Icons.payments_outlined,
          isTrendUp: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
    bool? isTrendUp,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, color: AppColors.textLight, size: 20),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Row(
            children: [
              if (isTrendUp != null)
                Icon(
                  isTrendUp ? Icons.trending_up : (isWarning ? Icons.warning : Icons.trending_down),
                  color: isTrendUp ? AppColors.success : (isWarning ? AppColors.error : AppColors.error),
                  size: 16,
                ),
              if (isTrendUp != null) const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isWarning ? AppColors.error : (isTrendUp == true ? AppColors.success : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderBoard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '실시간 운송 오더 현황판',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Icon(Icons.refresh, color: AppColors.textLight, size: 20),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 32,
              horizontalMargin: 24,
              columns: const [
                DataColumn(label: Text('오더번호', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                DataColumn(label: Text('화주사', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                DataColumn(label: Text('출발 거점', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                DataColumn(label: Text('도착 거점', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                DataColumn(label: Text('진행 상태', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                DataColumn(label: Text('배정 차량', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              ],
              rows: [
                _buildDataRow('ORD-A-001', 'LG전자', '평택 물류센터', '구로 대리점', '운송중', '경기80아1234', AppColors.secondary, const Color(0xFFE0F2FE)),
                _buildDataRow('ORD-A-002', 'LG화학', '여수 공장', '인천 컨테이너부두', '배차완료', '전남85바9876', AppColors.warning, const Color(0xFFFEF3C7)),
                _buildDataRow('ORD-A-003', 'LG디스플레이', '파주 OLED센터', '평택 스마트항', '하역완료', '서울70사5521', AppColors.success, const Color(0xFFD1FAE5)),
                _buildDataRow('ORD-A-004', 'LG생활건강', '청주 물류허브', '강남 면세점', '오더접수', '-', AppColors.textSecondary, const Color(0xFFF1F5F9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(
    String orderNo,
    String shipper,
    String origin,
    String dest,
    String status,
    String vehicle,
    Color statusColor,
    Color statusBg,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(orderNo, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(shipper)),
        DataCell(Text(origin)),
        DataCell(Text(dest)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ),
        DataCell(Text(vehicle)),
      ],
    );
  }

  Widget _buildControlBoard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '실시간 차량 관제 (GPS)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          // Mock Map Layout
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 50,
                  left: 40,
                  child: Column(
                    children: [
                      Icon(Icons.location_on, color: AppColors.secondary, size: 24),
                      Text('경기80아1234', style: TextStyle(color: Colors.white, fontSize: 9, backgroundColor: AppColors.primary)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 50,
                  right: 40,
                  child: Column(
                    children: [
                      Icon(Icons.location_on, color: AppColors.warning, size: 24),
                      Text('경남90자2345', style: TextStyle(color: Colors.white, fontSize: 9, backgroundColor: AppColors.primary)),
                    ],
                  ),
                ),
                Icon(Icons.navigation_outlined, color: Colors.white30, size: 40),
                Positioned(
                  bottom: 12,
                  child: Text(
                    'NAVER MAP API 연동 영역',
                    style: TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Utilization Panels
          _buildUtilStat('차량 평균 중량적재 효율', 0.824, AppColors.secondary),
          const SizedBox(height: 16),
          _buildUtilStat('차량 평균 부피적재 효율 (CBM)', 0.751, AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildUtilStat(String label, double percent, Color fillColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            Text('${(percent * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(fillColors),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// SIDEBAR WIDGET (Desktop View)
// ----------------------------------------------------
class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.primary,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            border: const Border(bottom: BorderSide(color: Colors.white10)),
            child: const Row(
              children: [
                Icon(Icons.local_shipping, color: AppColors.secondary, size: 24),
                SizedBox(width: 12),
                Text(
                  'K-CASTLE TMS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                _buildMenuItem(Icons.dashboard, '대시보드', active: true),
                _buildMenuItem(Icons.receipt_long, '운송 오더 관리'),
                _buildMenuItem(Icons.route, '배차 계획 수립'),
                _buildMenuItem(Icons.map, '실시간 차량 관제'),
                _buildMenuItem(Icons.account_balance_wallet, '정산 및 마감'),
                _buildMenuItem(Icons.settings, '시스템 설정'),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Enterprise TMS v1.0\n© 2026 K-Castle Group',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: active ? Colors.white : AppColors.textLight, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: active,
        selectedTileColor: active ? Colors.white.withOpacity(0.06) : null,
        onTap: () {},
      ),
    );
  }
}

// ----------------------------------------------------
// MOBILE DRAWER
// ----------------------------------------------------
class NavigationDrawerWidget extends StatelessWidget {
  const NavigationDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.primary,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
            child: Row(
              children: [
                const Icon(Icons.local_shipping, color: AppColors.secondary, size: 30),
                const SizedBox(width: 12),
                Text(
                  'K-CASTLE TMS',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          ListTile(leading: const Icon(Icons.dashboard, color: Colors.white), title: const Text('대시보드', style: TextStyle(color: Colors.white)), onTap: () {}),
          ListTile(leading: const Icon(Icons.receipt_long, color: AppColors.textLight), title: const Text('운송 오더 관리', style: TextStyle(color: AppColors.textLight)), onTap: () {}),
          ListTile(leading: const Icon(Icons.route, color: AppColors.textLight), title: const Text('배차 계획 수립', style: TextStyle(color: AppColors.textLight)), onTap: () {}),
          ListTile(leading: const Icon(Icons.map, color: AppColors.textLight), title: const Text('실시간 차량 관제', style: TextStyle(color: AppColors.textLight)), onTap: () {}),
          ListTile(leading: const Icon(Icons.account_balance_wallet, color: AppColors.textLight), title: const Text('정산 및 마감', style: TextStyle(color: AppColors.textLight)), onTap: () {}),
          ListTile(leading: const Icon(Icons.settings, color: AppColors.textLight), title: const Text('시스템 설정', style: TextStyle(color: AppColors.textLight)), onTap: () {}),
        ],
      ),
    );
  }
}
