import 'package:flutter/material.dart';
import '../auth_theme.dart';
import '../mock_data.dart';

class TemplateGamesScreen extends StatelessWidget {
  const TemplateGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve template games from parsed JSON data
    final templateSection = MockData.gamesData['template_games'] as Map<String, dynamic>? ?? {};
    final List<dynamic> gamesList = templateSection['games'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AuthTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Template Games',
          style: TextStyle(
            fontFamily: AuthTheme.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 20.0,
            color: AuthTheme.textDark,
          ),
        ),
      ),
      body: gamesList.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AuthTheme.primary),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.8,
              ),
              itemCount: gamesList.length,
              itemBuilder: (context, index) {
                final game = gamesList[index] as Map<String, dynamic>;
                final String title = game['title'] ?? 'Unknown';
                final String thumbnailUrl = game['thumbnailUrl'] ?? '';
                final String gameUrl = game['gameUrl'] ?? '';

                return _buildTemplateGameCard(context, title, thumbnailUrl, gameUrl);
              },
            ),
    );
  }

  Widget _buildTemplateGameCard(
    BuildContext context,
    String title,
    String thumbnailUrl,
    String gameUrl,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
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
            // Game Thumbnail (Network Image)
            Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to local test asset if offline or loading fails
                return Image.asset(
                  'assets/mockimages/FetchCard.png',
                  fit: BoxFit.cover,
                );
              },
            ),

            // Readability gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(20),
                    Colors.black.withAlpha(160),
                  ],
                ),
              ),
            ),

            // Play now centered overlay button
            Center(
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
                borderRadius: BorderRadius.circular(24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
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
                      Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18.0),
                      SizedBox(width: 4.0),
                      Text(
                        'Play now',
                        style: TextStyle(
                          fontFamily: AuthTheme.fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.0,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Title label at the bottom
            Positioned(
              bottom: 12.0,
              left: 12.0,
              right: 12.0,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: AuthTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.0,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
