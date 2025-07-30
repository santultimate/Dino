import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/team_member_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec logo
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dino Game V2',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Description du jeu
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'À propos du jeu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Dino Game V2 est une version moderne et améliorée du célèbre jeu de dinosaure. '
                      'Avec des graphismes améliorés, des modes de jeu variés et des fonctionnalités '
                      'innovantes, ce jeu offre une expérience de jeu unique et engageante.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Fonctionnalités principales
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fonctionnalités principales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.games,
                      title: '4 modes de jeu',
                      description:
                          'Infini, Contre la montre, Défi quotidien, Hardcore',
                    ),
                    _FeatureItem(
                      icon: Icons.shopping_cart,
                      title: 'Boutique intégrée',
                      description:
                          'Achetez des skins et des power-ups avec vos pièces',
                    ),
                    _FeatureItem(
                      icon: Icons.leaderboard,
                      title: 'Classements',
                      description: 'Comparez vos scores avec d\'autres joueurs',
                    ),
                    _FeatureItem(
                      icon: Icons.music_note,
                      title: 'Audio immersif',
                      description: 'Effets sonores et musique de fond',
                    ),
                    _FeatureItem(
                      icon: Icons.settings,
                      title: 'Personnalisation',
                      description: 'Paramètres adaptés à vos préférences',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Équipe de développement
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Équipe de développement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TeamMemberCard(
                            name: 'Yacouba Santara',
                            role: 'Lead Developer',
                            imagePath: 'assets/images/app_icon.png',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Liens importants
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Liens importants',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LinkItem(
                      icon: Icons.privacy_tip,
                      title: 'Politique de confidentialité',
                      onTap: () => _launchPrivacyPolicy(),
                    ),
                    _LinkItem(
                      icon: Icons.description,
                      title: 'Conditions d\'utilisation',
                      onTap: () => _launchTermsOfService(),
                    ),
                    _LinkItem(
                      icon: Icons.bug_report,
                      title: 'Signaler un bug',
                      onTap: () => _launchBugReport(),
                    ),
                    _LinkItem(
                      icon: Icons.feedback,
                      title: 'Donner un avis',
                      onTap: () => _launchFeedback(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Informations techniques
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations techniques',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• Développé avec Flutter\n'
                      '• Moteur de jeu Flame\n'
                      '• Base de données Firebase\n'
                      '• Publicités Google Mobile Ads\n'
                      '• Compatible iOS et Android',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Copyright
            Center(
              child: Text(
                '© 2024 Dino Game V2. Tous droits réservés.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPrivacyPolicy() async {
    const url = 'https://santultimate.github.io/Dino_Game/privacy_policy.html';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchTermsOfService() async {
    const url =
        'https://santultimate.github.io/Dino_Game/terms_of_service.html';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchBugReport() async {
    const url = 'https://github.com/santultimate/Dino_Game/issues';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchFeedback() async {
    const url =
        'mailto:feedback@dinogame.com?subject=Feedback%20Dino%20Game%20V2';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LinkItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
