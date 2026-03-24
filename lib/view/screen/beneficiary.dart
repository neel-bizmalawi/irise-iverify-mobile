import 'package:flutter/material.dart';

class BeneficiaryListScreen extends StatefulWidget {
  const BeneficiaryListScreen({super.key});

  @override
  State<BeneficiaryListScreen> createState() => _BeneficiaryListScreenState();
}

class _BeneficiaryListScreenState extends State<BeneficiaryListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _beneficiaries = [
    {
      'name': 'Abraham Chirwa',
      'userId': '30732',
      'nationalId': 'QQPPOO131',
      'synced': true,
      'missing': ['National ID', 'Signature'],
    },
    {
      'name': 'Ackim Tembo',
      'userId': '30684',
      'nationalId': 'SSDDYY061',
      'synced': false,
      'missing': ['National ID', 'Signature'],
    },
    {
      'name': 'Ackim',
      'userId': '30912',
      'nationalId': 'QQSSPP001',
      'synced': true,
      'missing': ['National ID', 'Signature'],
    },
    {
      'name': 'Adam',
      'userId': '30730',
      'nationalId': 'WWSSPP980',
      'synced': true,
      'missing': ['National ID', 'Signature'],
    },
    {
      'name': 'Adamson',
      'userId': '30707',
      'nationalId': 'SSPYDD890',
      'synced': false,
      'missing': ['National ID', 'Signature'],
    },
    {
      'name': 'Adris',
      'userId': '30730',
      'nationalId': 'WWSSPP980',
      'synced': true,
      'missing': ['National ID', 'Signature'],
    },
    {
      'name': 'Alex',
      'userId': '30730',
      'nationalId': 'WWSSPP980',
      'synced': true,
      'missing': ['National ID', 'Signature'],
    },
    {
      'name': 'Mike',
      'userId': '30730',
      'nationalId': 'WWSSPP980',
      'synced': true,
      'missing': ['National ID', 'Signature'],
    },
  ];

  List<Map<String, dynamic>> get _filtered => _beneficiaries
      .where((e) =>
          e['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e['nationalId'].toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4EA),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Scroll to top FAB ──
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: FloatingActionButton(
              heroTag: 'scroll_top',
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: Colors.white,
              elevation: 2,
              child: const Icon(Icons.vertical_align_top,
                  color: Colors.black54, size: 22),
            ),
          ),

          // ── Add User FAB ──
          FloatingActionButton.extended(
            heroTag: 'add_user',
            onPressed: () {},
            backgroundColor: const Color(0xFF4CAF50),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add User',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Green quarter-circle top-right ──
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(90),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.black87, size: 20),
                      ),
                      const Expanded(
                        child: Text(
                          'Beneficiary List',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.question_mark_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),

                // ── Search Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search by Name or National ID...',
                        hintStyle:
                            TextStyle(color: Colors.black38, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: Colors.black38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Stats Row ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatSummary(
                          value: '2,50,000',
                          label: 'TOTAL',
                          color: Colors.black87),
                      _divider(),
                      _StatSummary(
                          value: '1,34,567',
                          label: 'SYNCED',
                          color: Colors.black87),
                      _divider(),
                      _StatSummary(
                          value: '1,15,433',
                          label: 'OFFLINE',
                          color: Colors.black87),
                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: Container(
                      //     // padding: const EdgeInsets.all(6),
                      //     // decoration: BoxDecoration(
                      //     //   border: Border.all(color: Colors.black26),
                      //     //   borderRadius: BorderRadius.circular(6),
                      //     // ),
                      //     child: const Icon(Icons.sync,
                      //         size: 16, color: Colors.black54),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── List ──
                Expanded(
                  child: Stack(
                    children: [
                      ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _filtered[index];
                          return _BeneficiaryCard(
                            name: item['name'],
                            userId: item['userId'],
                            nationalId: item['nationalId'],
                            synced: item['synced'],
                            missing: List<String>.from(item['missing']),
                          );
                        },
                      ),
                      // ── Bottom records loaded indicator ──
                      Positioned(
                        bottom: 16,
                        left: 54,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                '8/100 New records loaded',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.black12,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatSummary extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatSummary({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color == Colors.black87 ? Colors.black54 : color,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BeneficiaryCard extends StatelessWidget {
  final String name;
  final String userId;
  final String nationalId;
  final bool synced;
  final List<String> missing;

  const _BeneficiaryCard({
    required this.name,
    required this.userId,
    required this.nationalId,
    required this.synced,
    required this.missing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: synced ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // ── Avatar ──
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: synced
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    synced
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    color: synced ? const Color(0xFF4CAF50) : Colors.black26,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // ── Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          _SyncBadge(synced: synced),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'USER ID: $userId',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'NATIONAL ID: $nationalId',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                          const Icon(Icons.sort,
                              size: 18, color: Colors.black38),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Missing tags ──
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    '• MISSING:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ...missing.map(
                    (tag) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE4EC),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SyncBadge extends StatelessWidget {
  final bool synced;
  const _SyncBadge({required this.synced});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: synced ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            synced ? Icons.check_circle_outline : Icons.sync,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            synced ? 'SYNCED' : 'NOT SYNCED',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
