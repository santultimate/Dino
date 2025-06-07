import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/feature_card.dart';
import '../widgets/team_member_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d’ouvrir le lien : $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos du jeu'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.shade700,
                Colors.teal.shade400,
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec logo
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/dino_icon.png',
                    height: 100,
                    width: 100,
                    semanticLabel: 'Icône de Dino Runner',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Dino Runner',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Version 1.2.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Description
            Text(
              'Dino Runner est un jeu de course palpitant où vous incarnez un dinosaure courageux évitant des obstacles. '
              'Découvrez plusieurs modes de jeu, personnalisez votre Dino et défiez vos amis !',
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Features Grid
            Text(
              'Fonctionnalités principales',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: const [
                FeatureCard(
                  icon: Icons.games,
                  title: '4 Modes de jeu',
                  description: 'Infini, Contre-la-montre, Hardcore, Défi quotidien',
                ),
                FeatureCard(
                  icon: Icons.palette,
                  title: 'Personnalisation',
                  description: 'Skins, thèmes et accessoires',
                ),
                FeatureCard(
                  icon: Icons.leaderboard,
                  title: 'Classements',
                  description: 'Local et mondial',
                ),
                FeatureCard(
                  icon: Icons.group,
                  title: 'Multijoueur',
                  description: 'Mode écran partagé',
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Équipe de développement
            Text(
              'Notre équipe',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  TeamMemberCard(
                    name: 'Yacouba SANTARA',
                    role: 'Développeur',
                    imagePath: 'assets/images/team/yacou.jpg',
                  ),
                  TeamMemberCard(
                    name: 'ABBA SANTARA',
                    role: 'Designer',
                    imagePath: 'assets/images/team/abba.jpg',
                  ),
                  TeamMemberCard(
                    name: 'HAWA SANTARA',
                    role: 'Sound Designer',
                    imagePath: 'assets/images/team/hawa.jpg',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Liens et crédits
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crédits & Mentions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Développé avec Flutter'),
                      onTap: () => _launchURL(context, 'https://flutter.dev'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.music_note),
                      title: const Text('Musique par SoundCloud'),
                      onTap: () => _launchURL(context, 'https://soundcloud.com'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Politique de confidentialité'),
                      onTap: () => _launchURL(context, 'https://yacoubasanta@yahoo.fr/privacy'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Conditions d\'utilisation'),
                      onTap: () => _launchURL(context, 'https://yacoubasanta@yahoo.fr/terms'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Copyright
            Center(
              child: Text(
                '© 2023 Dino Runner Team. Tous droits réservés.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
