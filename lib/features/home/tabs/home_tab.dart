import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nhattrinhgang_mobile/core/stores/localstore.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await LocalStore.clear();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B2545), Color(0xFF00529C)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.white24, radius: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Xin chào,',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(color: Colors.white)),
                          // Text('Dani Martinez',
                          //     style: theme.textTheme.bodyMedium
                          //         ?.copyWith(color: Colors.white70)),
                          FutureBuilder<String?>(
                            future: LocalStore.getUsername(),
                            builder: (context, snapshot) {
                              final username = snapshot.data ?? '---';
                              return Text(
                                username,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.signal_cellular_alt, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Danh mục', style: theme.textTheme.titleMedium),
                  TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  // _CategoryCard(icon: Icons.work_outline, label: 'Công đoạn'),
                  // _CategoryCard(icon: Icons.precision_manufacturing, label: 'Mẻ thép'),
                  // _CategoryCard(icon: Icons.inventory_2_outlined, label: 'Kho'),
                  // _CategoryCard(icon: Icons.qr_code_scanner, label: 'QR'),
                  // _CategoryCard(icon: Icons.analytics_outlined, label: 'Báo cáo'),
                  _CategoryCard(
                      icon: Icons.settings_outlined, label: 'Thiết lập'),
                  _CategoryCard(
                    icon: Icons.logout,
                    label: 'Đăng xuất',
                    isDanger: true,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Text('Gợi ý', style: theme.textTheme.titleMedium),
              // const SizedBox(height: 8),
              // _SuggestionCard(title: 'Kiểm tra mẻ thép A-123'),
              // _SuggestionCard(title: 'Đối chiếu số liệu công đoạn'),
            ]),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.label,
    this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDanger ? Colors.red : theme.colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDanger ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDanger ? Colors.red.shade200 : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDanger ? Colors.red : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: const Color(0xFFF8FAFC),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.check_circle_outline,
              color: theme.colorScheme.primary),
        ),
        title: Text(title),
        subtitle: const Text('Chi tiết đề xuất'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
