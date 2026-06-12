import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth_theme.dart';
import '../mock_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Category order state to support dynamic prioritization
  List<String> _sectionOrder = ['Utilities', 'Downloaders', 'PDF Editors'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await MockData.loadLocalJsonData();
    if (mounted) {
      setState(() {});
    }
  }

  // Opens the prioritization sheet
  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Prioritize Categories',
                  style: TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 20.0,
                    color: AuthTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Select a category to show at the top of your list',
                  style: TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.0,
                    color: AuthTheme.textGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                _buildSortOption(
                  context,
                  label: 'Utilities First',
                  isActive: _sectionOrder.first == 'Utilities',
                  onTap: () {
                    setState(() {
                      _sectionOrder = ['Utilities', 'Downloaders', 'PDF Editors'];
                    });
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12.0),
                _buildSortOption(
                  context,
                  label: 'Downloaders First',
                  isActive: _sectionOrder.first == 'Downloaders',
                  onTap: () {
                    setState(() {
                      _sectionOrder = ['Downloaders', 'Utilities', 'PDF Editors'];
                    });
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12.0),
                _buildSortOption(
                  context,
                  label: 'PDF Editors First',
                  isActive: _sectionOrder.first == 'PDF Editors',
                  onTap: () {
                    setState(() {
                      _sectionOrder = ['PDF Editors', 'Utilities', 'Downloaders'];
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: isActive ? AuthTheme.primary.withAlpha(20) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isActive ? AuthTheme.primary : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AuthTheme.fontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 15.0,
                color: isActive ? AuthTheme.primary : AuthTheme.textDark,
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle_rounded,
                color: AuthTheme.primary,
                size: 20.0,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!MockData.isJsonLoaded) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AuthTheme.primary),
        ),
      );
    }

    final homeData = MockData.config['home'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top-Attached Hero Card (Touches Top, Left, and Right edges)
            _buildHeroCard(context),
            const SizedBox(height: 24.0),

            // Padded Body Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Template Games Section
                  const Text(
                    'Template Games',
                    style: TextStyle(
                      fontFamily: AuthTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 18.0,
                      color: AuthTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  _buildTemplateGamesCard(context),
                  const SizedBox(height: 24.0),

                  // Native Ad Unit Placeholder with Test IDs
                  _buildNativeAdPlaceholder(),
                  const SizedBox(height: 24.0),

                  // Featured Web Games Scroll
                  _buildWebGamesSection(context),
                  const SizedBox(height: 24.0),

                  // Dynamically Ordered Categories
                  ..._buildCategories(context, homeData),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final List<dynamic> games = MockData.gamesData['games'] ?? [];
    final latestGame = games.firstWhere(
      (g) => g['isLatest'] == true,
      orElse: () => null,
    );

    final String gameTitle = latestGame != null ? latestGame['title'] : 'Flap Flap Adventure';
    final String gameUrl = latestGame != null ? latestGame['gameUrl'] : 'https://earnest-zabaione-4d0288.netlify.app/';
    final String thumbnailUrl = latestGame != null ? latestGame['thumbnailUrl'] : '';

    return Container(
      height: 240.0 + statusBarHeight,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24.0),
          bottomRight: Radius.circular(24.0),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Dynamic image loading with fallback
            thumbnailUrl.isNotEmpty
                ? Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/mockimages/FetchCard.png',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    'assets/mockimages/FetchCard.png',
                    fit: BoxFit.cover,
                  ),
            
            // "Latest" tag overlay at the top left corner (adjusted to clear status bar)
            Positioned(
              top: statusBarHeight + 16.0,
              left: 16.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withAlpha(100),
                      blurRadius: 6.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Latest',
                  style: TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Bottom-centered button overlay matching the mockup design
            Positioned(
              bottom: 24.0,
              left: 0,
              right: 0,
              child: Center(
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/webview',
                      arguments: {
                        'gameUrl': gameUrl,
                        'gameTitle': gameTitle,
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D85DC),
                      borderRadius: BorderRadius.circular(30.0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5D85DC).withAlpha(100),
                          blurRadius: 10.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Play now',
                          style: TextStyle(
                            fontFamily: AuthTheme.fontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.0,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16.0,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateGamesCard(BuildContext context) {
    final templateSection = MockData.gamesData['template_games'] as Map<String, dynamic>? ?? {};
    final String templateThumbnail = templateSection['thumbnailUrl'] ?? '';

    return Container(
      height: 140.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Dynamic image loading with fallback
            templateThumbnail.isNotEmpty
                ? Image.network(
                    templateThumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/mockimages/FetchCard.png',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    'assets/mockimages/FetchCard.png',
                    fit: BoxFit.cover,
                  ),
            // Dark gradient overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(20),
                    Colors.black.withAlpha(140),
                  ],
                ),
              ),
            ),
            // Centered Explore Now Button
            Center(
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/template-games');
                },
                borderRadius: BorderRadius.circular(24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore Now',
                        style: TextStyle(
                          fontFamily: AuthTheme.fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.0,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 6.0),
                      Icon(Icons.explore_outlined, size: 16.0, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeAdPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: const Text(
                  'Ad',
                  style: TextStyle(
                    fontFamily: AuthTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.0,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              const Text(
                'WebX Sponsor Test Ad',
                style: TextStyle(
                  fontFamily: AuthTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.0,
                  color: AuthTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Enjoy high speed tools, unlimited downlods, and direct web play. Try WebX Premium for free!',
            style: TextStyle(
              fontFamily: AuthTheme.fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 12.0,
              color: AuthTheme.textGrey,
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AuthTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              minimumSize: const Size(double.infinity, 36.0),
              elevation: 0,
            ),
            child: const Text(
              'Explore Premium',
              style: TextStyle(
                fontFamily: AuthTheme.fontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 12.0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebGamesSection(BuildContext context) {
    final List<dynamic> games = MockData.gamesData['games'] ?? [];
    // Filter out the game that isLatest == true
    final featuredGames = games.where((g) => g['isLatest'] != true).toList();

    if (featuredGames.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(title: 'Featured Games'),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 120.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featuredGames.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final game = featuredGames[index] as Map<String, dynamic>;
              final String title = game['title'] ?? 'Game';
              final String thumbnailUrl = game['thumbnailUrl'] ?? '';
              final String gameUrl = game['gameUrl'] ?? '';
              final int plays = game['plays'] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/webview',
                      arguments: {
                        'gameUrl': gameUrl,
                        'gameTitle': title,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(16.0),
                  child: SizedBox(
                    width: 100.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Thumbnail
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(15),
                                  blurRadius: 4.0,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.0),
                              child: Image.network(
                                thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/mockimages/FetchCard.png',
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: AuthTheme.fontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.0,
                            color: AuthTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2.0),
                        // Plays count
                        Text(
                          '${plays >= 1000 ? "${(plays/1000).toStringAsFixed(1)}K" : plays} plays',
                          style: const TextStyle(
                            fontFamily: AuthTheme.fontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 10.0,
                            color: AuthTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCategories(BuildContext context, Map<String, dynamic> data) {
    final List<Widget> list = [];

    for (int i = 0; i < _sectionOrder.length; i++) {
      final section = _sectionOrder[i];
      if (i > 0) list.add(const SizedBox(height: 24.0));

      final isFirst = i == 0;

      if (section == 'Utilities') {
        list.add(_buildSectionHeader(
          title: data['utilitiesHeading'],
          showSort: isFirst,
          onSortPressed: isFirst ? () => _showSortBottomSheet(context) : null,
        ));
        list.add(const SizedBox(height: 12.0));
        list.add(_buildHorizontalList(MockData.mockUtilities));
      } else if (section == 'Downloaders') {
        list.add(_buildSectionHeader(
          title: data['downloadersHeading'],
          showSort: isFirst,
          onSortPressed: isFirst ? () => _showSortBottomSheet(context) : null,
        ));
        list.add(const SizedBox(height: 12.0));
        list.add(_buildHorizontalList(MockData.mockDownloaders));
      } else if (section == 'PDF Editors') {
        list.add(_buildSectionHeader(
          title: data['pdfEditorsHeading'],
          showSort: isFirst,
          onSortPressed: isFirst ? () => _showSortBottomSheet(context) : null,
        ));
        list.add(const SizedBox(height: 12.0));
        list.add(_buildHorizontalList(MockData.mockPdfEditors));
      }
    }

    return list;
  }

  Widget _buildSectionHeader({
    required String title,
    bool showSort = false,
    VoidCallback? onSortPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: AuthTheme.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 18.0,
            color: AuthTheme.textDark,
          ),
        ),
        if (showSort)
          GestureDetector(
            onTap: onSortPressed,
            child: SvgPicture.asset(
              'assets/vectors/sort.svg',
              width: 18.0,
              height: 18.0,
              colorFilter: const ColorFilter.mode(AuthTheme.textDark, BlendMode.srcIn),
              placeholderBuilder: (context) => const Icon(
                Icons.tune_rounded,
                size: 18.0,
                color: AuthTheme.textDark,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontalList(List<Map<String, String>> items) {
    return SizedBox(
      height: 104.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening ${item['title']}...')),
                );
              },
              borderRadius: BorderRadius.circular(16.0),
              child: Container(
                width: 96.0,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon Container
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: AuthTheme.greyBg,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/vectors/${item['icon']}',
                          width: 20.0,
                          height: 20.0,
                          colorFilter: const ColorFilter.mode(AuthTheme.textDark, BlendMode.srcIn),
                          placeholderBuilder: (context) => const Icon(
                            Icons.extension_rounded,
                            size: 20.0,
                            color: AuthTheme.textDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    // Title Text
                    Expanded(
                      child: Text(
                        item['title']!,
                        style: const TextStyle(
                          fontFamily: AuthTheme.fontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 11.0,
                          color: AuthTheme.textDark,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
