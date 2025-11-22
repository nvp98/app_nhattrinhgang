import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

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
                          Text('Welcome', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                          Text('Dani Martinez', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Icon(Icons.signal_cellular_alt, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm công đoạn / mẻ thép',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                  _CategoryCard(icon: Icons.work_outline, label: 'Công đoạn'),
                  _CategoryCard(icon: Icons.precision_manufacturing, label: 'Mẻ thép'),
                  _CategoryCard(icon: Icons.inventory_2_outlined, label: 'Kho'),
                  _CategoryCard(icon: Icons.qr_code_scanner, label: 'QR'),
                  _CategoryCard(icon: Icons.analytics_outlined, label: 'Báo cáo'),
                  _CategoryCard(icon: Icons.settings_outlined, label: 'Thiết lập'),
                ],
              ),
              const SizedBox(height: 16),
              Text('Gợi ý', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _SuggestionCard(title: 'Kiểm tra mẻ thép A-123'),
              _SuggestionCard(title: 'Đối chiếu số liệu công đoạn'),
            ]),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 6),
              Text(label),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
        ),
        title: Text(title),
        subtitle: const Text('Chi tiết đề xuất'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}