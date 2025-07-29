# Configuration Guide - Dino Runner V2

## 🔐 Fichiers sensibles - NE PAS COMMITER

Les fichiers suivants contiennent des informations sensibles et ne doivent **JAMAIS** être poussés vers GitHub :

### Firebase Configuration
- `google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)
- `firebase_app_id_file.json`

### API Keys et Secrets
- `.env`
- `config.json`
- `secrets.json`
- `keys.json`

### AdMob Configuration
- `admob_config.json`
- `admob_keys.json`

### Keystore Files
- `*.keystore`
- `*.jks`
- `key.properties`

## 📋 Configuration requise

### 1. Firebase Setup
1. Créez un projet Firebase
2. Téléchargez `google-services.json` pour Android
3. Téléchargez `GoogleService-Info.plist` pour iOS
4. Placez ces fichiers dans les dossiers appropriés

### 2. AdMob Setup
1. Créez un compte AdMob
2. Créez une application
3. Générez les IDs d'unités publicitaires
4. Configurez les IDs dans votre code

### 3. Variables d'environnement
Créez un fichier `.env` (non commité) avec :
```
FIREBASE_API_KEY=your_api_key_here
ADMOB_APP_ID=ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy
ADMOB_BANNER_ID=ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz
ADMOB_INTERSTITIAL_ID=ca-app-pub-xxxxxxxxxxxxxxxx/wwwwwwwwww
```

## 🚀 Déploiement

### Android
1. Configurez le keystore de signature
2. Ajoutez `key.properties` (non commité)
3. Configurez les permissions dans `AndroidManifest.xml`

### iOS
1. Configurez les certificats de signature
2. Ajoutez les capacités nécessaires
3. Configurez les permissions dans `Info.plist`

## 📝 Exemple de configuration

Voir `config.example.json` pour un exemple de structure de configuration.

## ⚠️ Sécurité

- **NE JAMAIS** commiter de vraies clés API
- **NE JAMAIS** partager de fichiers de configuration sensibles
- **TOUJOURS** utiliser des variables d'environnement pour les secrets
- **TOUJOURS** vérifier le `.gitignore` avant de commiter

## 🔍 Vérification

Avant de pousser vers GitHub, vérifiez que :
```bash
git status
```
Ne montre aucun fichier sensible dans les fichiers à commiter.

---

**Développé par Yacouba Santara** 