import 'package:flutter/material.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;

// --- ADDITIONAL PALETTE ---
const Color kSlate100 = Color(0xFFF1F5F9); // Added missing color
const Color kSlate200 = Color(0xFFE2E8F0);
const Color kSlate400 = Color(0xFF94A3B8);
const Color kSlate500 = Color(0xFF64748B);
const Color kSlate900 = Color(0xFF0F172A);
const Color kEmeraldColor = Color(0xFF10B981);

// --- MOCK DATA ---
final List<Map<String, dynamic>> kShortsData = [
  {
    'id': 's1',
    'title': "5 Signs of Diabetes",
    'views': "1.2M",
    'platform': "youtube",
    'thumbnail':
        "https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&q=80",
  },
  {
    'id': 's2',
    'title': "Instant Migraine Relief",
    'views': "850K",
    'platform': "instagram",
    'thumbnail':
        "https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=400&q=80",
  },
  {
    'id': 's3',
    'title': "Foods for Heart",
    'views': "2.1M",
    'platform': "youtube",
    'thumbnail':
        "https://images.unsplash.com/photo-1505576399279-565b52d4ac71?w=400&q=80",
  },
  {
    'id': 's4',
    'title': "Correct Posture Hack",
    'views': "500K",
    'platform': "instagram",
    'thumbnail':
        "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400&q=80",
  },
  {
    'id': 's5',
    'title': "Why you feel tired",
    'views': "3M",
    'platform': "youtube",
    'thumbnail':
        "https://images.unsplash.com/photo-1486218119243-13883505764c?w=400&q=80",
  },
];

final List<Map<String, dynamic>> kMainFeedData = [
  {
    'id': 1,
    'type': 'video',
    'platform': 'youtube',
    'category': 'Cardiology',
    'title': "Understanding High Blood Pressure: A Complete Guide",
    'desc':
        "Dr. Sharma explains the root causes of hypertension and how to manage it naturally.",
    'meta': "12:45 mins",
    'date': "2 days ago",
    'thumbnail':
        "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800&q=80",
  },
  {
    'id': 2,
    'type': 'article',
    'category': 'Nutrition',
    'title': "The Ultimate Diet Plan for a Healthy Gut",
    'desc':
        "Gut health is linked to your immune system, mood, and mental health. Here is what you should eat.",
    'meta': "5 min read",
    'date': "4 hours ago",
    'thumbnail':
        "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80",
  },
  {
    'id': 3,
    'type': 'video',
    'platform': 'youtube',
    'category': 'Mental Health',
    'title': "Anxiety vs Panic Attacks: Knowing the Difference",
    'desc':
        "Learn the subtle differences between general anxiety and acute panic episodes.",
    'meta': "8:00 mins",
    'date': "1 week ago",
    'thumbnail':
        "https://images.unsplash.com/photo-1493836512294-502baa1986e2?w=800&q=80",
  },
  {
    'id': 4,
    'type': 'video',
    'platform': 'youtube',
    'category': 'Pediatrics',
    'title': "Vaccination Schedule for Newborns (2025 Updated)",
    'desc':
        "Keep track of your baby's immunization chart with this simple explainer video.",
    'meta': "8:20 mins",
    'date': "3 days ago",
    'thumbnail':
        "https://images.unsplash.com/photo-1628103133618-9710f69f2e3c?w=800&q=80",
  },
  {
    'id': 5,
    'type': 'article',
    'category': 'Fitness',
    'title': "Yoga Asanas for Back Pain Relief",
    'desc':
        "Simple stretches you can do at your desk to prevent chronic back issues.",
    'meta': "4 min read",
    'date': "Just now",
    'thumbnail':
        "https://images.unsplash.com/photo-1544367563-12123d8965cd?w=800&q=80",
  },
];

// --- MAIN SCREEN ---
class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  String _activeTab = 'All';
  final String _searchQuery = '';

  // Filtering Logic
  List<Map<String, dynamic>> get _filteredFeed {
    return kMainFeedData.where((item) {
      final bool matchesTab = _activeTab == 'All'
          ? true
          : _activeTab == 'Videos'
          ? item['type'] == 'video'
          : _activeTab == 'Articles'
          ? item['type'] == 'article'
          : item['category'] == _activeTab;

      final bool matchesSearch = item['title']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      return matchesTab && matchesSearch;
    }).toList();
  }

  void _openVideoModal(Map<String, dynamic> video) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (_) => VideoModal(initialVideo: video, playlist: _filteredFeed),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- THEME DETECTION ---
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kDarkBg : kLightBg;
    final primaryTextColor = isDarkMode ? Colors.white : kSlate900;
    final borderColor = isDarkMode ? Colors.white12 : kSlate200;
    final emptyStateBg = isDarkMode ? kDarkCard : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. HEADER (Back Button & Title)
            SliverAppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              pinned: true,
              floating: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: primaryTextColor),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Know Diseases",
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: false,
            ),

            // 2. Trending Shorts Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Trending Shorts",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Shorts Rail
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: kShortsData.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) =>
                      ShortsCard(item: kShortsData[index]),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // 4. Filter Tabs
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  children:
                      [
                            'All',
                            'Videos',
                            'Articles',
                            'Cardiology',
                            'Nutrition',
                            'Fitness',
                          ]
                          .map(
                            (tab) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChip(
                                label: tab,
                                isSelected: _activeTab == tab,
                                onTap: () => setState(() => _activeTab = tab),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 5. Main Feed Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              sliver: _filteredFeed.isNotEmpty
                  ? SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            mainAxisExtent: 340,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = _filteredFeed[index];
                        return ContentCard(
                          item: item,
                          onPlay: () => _openVideoModal(item),
                        );
                      }, childCount: _filteredFeed.length),
                    )
                  : SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: emptyStateBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Text(
                          "No content found matching filters.",
                          style: TextStyle(
                            color: isDarkMode ? Colors.white54 : kSlate400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET: SHORTS CARD ---
class ShortsCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const ShortsCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(item['thumbnail'], fit: BoxFit.cover),

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.5, 1.0],
              ),
            ),
          ),

          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(
                item['platform'] == 'youtube'
                    ? Icons.play_circle_fill
                    : Icons.camera_alt,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),

          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.play_arrow,
                      color: Colors.white70,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['views'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['title'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(onTap: () {}),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: CONTENT CARD (Feed) ---
class ContentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onPlay;

  const ContentCard({super.key, required this.item, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    // --- THEME DETECTION ---
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDarkMode ? kDarkCard : kLightCard;
    final borderColor = isDarkMode ? Colors.white12 : kSlate100;
    final titleColor = isDarkMode ? Colors.white : kSlate900;
    final descColor = isDarkMode ? Colors.white60 : kSlate500;
    final metaBg = isDarkMode
        ? Colors.black.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.9);
    final metaText = isDarkMode ? Colors.white : kSlate900;
    final iconColor = isDarkMode ? Colors.white54 : kSlate400;

    final bool isVideo = item['type'] == 'video';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDarkMode
            ? [] // No shadow in dark mode looks cleaner
            : [
                BoxShadow(
                  color: kSlate200.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: isVideo ? onPlay : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(item['thumbnail'], fit: BoxFit.cover),

                  // Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isVideo ? Colors.pinkAccent : kEmeraldColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        isVideo ? 'VIDEO' : 'ARTICLE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Meta Time
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: metaBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['meta'],
                        style: TextStyle(
                          color: isVideo ? Colors.white : metaText,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (isVideo)
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: kSlate900,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item['category'].toString().toUpperCase(),
                          style: const TextStyle(
                            color: kPrimaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item['date'],
                        style: TextStyle(
                          color: descColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  InkWell(
                    onTap: isVideo ? onPlay : null,
                    child: Text(
                      item['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Expanded(
                    child: Text(
                      item['desc'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: descColor),
                    ),
                  ),

                  Divider(height: 24, thickness: 0.5, color: borderColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isVideo ? Icons.smart_display : Icons.menu_book,
                            size: 16,
                            color: isVideo ? Colors.redAccent : kEmeraldColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isVideo ? "YouTube" : "Read",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: descColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _IconBtn(
                            icon: Icons.favorite_border,
                            color: iconColor,
                          ),
                          const SizedBox(width: 8),
                          _IconBtn(
                            icon: Icons.share_outlined,
                            color: iconColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: VIDEO MODAL ---
class VideoModal extends StatefulWidget {
  final Map<String, dynamic> initialVideo;
  final List<Map<String, dynamic>> playlist;

  const VideoModal({
    super.key,
    required this.initialVideo,
    required this.playlist,
  });

  @override
  State<VideoModal> createState() => _VideoModalState();
}

class _VideoModalState extends State<VideoModal> {
  late Map<String, dynamic> currentVideo;

  @override
  void initState() {
    super.initState();
    currentVideo = widget.initialVideo;
  }

  void _next() {
    final idx = widget.playlist.indexOf(currentVideo);
    if (idx < widget.playlist.length - 1) {
      setState(() => currentVideo = widget.playlist[idx + 1]);
    }
  }

  void _prev() {
    final idx = widget.playlist.indexOf(currentVideo);
    if (idx > 0) {
      setState(() => currentVideo = widget.playlist[idx - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.playlist.indexOf(currentVideo);
    final hasPrev = idx > 0;
    final hasNext = idx < widget.playlist.length - 1;

    // Use specific dark theme for immersive video experience, matching kDarkCard
    const modalBg = kDarkCard;
    const modalText = Colors.white;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: modalBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentVideo['title'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.black,
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_circle_filled,
                                    size: 64,
                                    color: Colors.red.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Playing: ${currentVideo['title']}",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Positioned.fill(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  hasPrev
                                      ? IconButton(
                                          onPressed: _prev,
                                          icon: const Icon(
                                            Icons.chevron_left,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        )
                                      : const SizedBox(),
                                  hasNext
                                      ? IconButton(
                                          onPressed: _next,
                                          icon: const Icon(
                                            Icons.chevron_right,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        )
                                      : const SizedBox(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentVideo['title'],
                                  style: const TextStyle(
                                    color: modalText,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentVideo['desc'],
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text("Share"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (hasPrev)
                Positioned(
                  left: 20,
                  child: _NavCircleBtn(icon: Icons.chevron_left, onTap: _prev),
                ),
              if (hasNext)
                Positioned(
                  right: 20,
                  child: _NavCircleBtn(icon: Icons.chevron_right, onTap: _next),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HELPER WIDGETS ---

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- THEME DETECTION ---
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDarkMode ? kDarkCard : Colors.white;
    final defaultBorder = isDarkMode ? Colors.white12 : kSlate200;
    final defaultText = isDarkMode ? Colors.white70 : kSlate500;

    // Selected state uses Primary Color
    final bgColor = isSelected ? kPrimaryColor : defaultBg;
    final borderColor = isSelected ? kPrimaryColor : defaultBorder;
    final textColor = isSelected ? Colors.white : defaultText;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBtn({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _NavCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavCircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
          color: Colors.black45,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
