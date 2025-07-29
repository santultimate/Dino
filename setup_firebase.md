# 🔥 Configuration Firebase pour Dino Game V2

## Étape 1 : Créer un projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquez sur "Créer un projet"
3. Nommez votre projet : `dino-game-v2`
4. Désactivez Google Analytics pour l'instant
5. Cliquez sur "Créer le projet"

## Étape 2 : Ajouter l'application Android

1. Dans la console Firebase, cliquez sur l'icône Android
2. Package name : `com.example.dino_game_v2`
3. App nickname : `Dino Game V2`
4. Téléchargez `google-services.json`
5. Placez-le dans `android/app/google-services.json`

## Étape 3 : Ajouter l'application iOS

1. Dans la console Firebase, cliquez sur l'icône iOS
2. Bundle ID : `com.example.dinoGameV2`
3. App nickname : `Dino Game V2`
4. Téléchargez `GoogleService-Info.plist`
5. Placez-le dans `ios/Runner/GoogleService-Info.plist`

## Étape 4 : Activer Firestore Database

1. Dans la console Firebase, allez dans "Firestore Database"
2. Cliquez sur "Créer une base de données"
3. Choisissez "Mode test" pour commencer
4. Sélectionnez une région proche (ex: europe-west1)

## Étape 5 : Règles Firestore

Dans Firestore Database > Règles, utilisez :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permettre la lecture/écriture pour tous les utilisateurs
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

## Étape 6 : Tester la configuration

1. Lancez l'application : `flutter run`
2. Vérifiez les logs :
   - ✅ `🔥 Firebase initialized successfully`
   - ✅ `🔥 Firebase Firestore initialized successfully`

## Étape 7 : Activer les services avancés

Une fois que Firebase fonctionne, vous pouvez activer :

1. **Authentication** (optionnel)
2. **Analytics** (optionnel)
3. **Crashlytics** (optionnel)

## Dépannage

### Erreur "Firebase not initialized"
- Vérifiez que les fichiers de configuration sont au bon endroit
- Vérifiez que les package names correspondent

### Erreur "Permission denied"
- Vérifiez les règles Firestore
- Assurez-vous que Firestore est activé

### Erreur "Network error"
- Vérifiez votre connexion internet
- Vérifiez que les règles Firestore permettent l'accès 