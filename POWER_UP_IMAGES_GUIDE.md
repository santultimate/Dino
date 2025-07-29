# 🎮 Guide des Images de Power-ups pour le Dino

## 📁 Structure des Images

Pour que le dino change d'apparence selon le power-up actif, vous devez créer les images suivantes dans le dossier `assets/images/` :

### 🏃‍♂️ **Power-up Speed Boost (Vert)**
```
dino_speed_1.png    # Frame 1 de course
dino_speed_2.png    # Frame 2 de course  
dino_speed_3.png    # Frame 3 de course
dino_speed_4.png    # Frame 4 de course
dino_speed_jump.png # Saut
dino_speed_duck.png # Accroupi
```

### 🛡️ **Power-up Shield (Bleu)**
```
dino_shield_1.png    # Frame 1 de course
dino_shield_2.png    # Frame 2 de course
dino_shield_3.png    # Frame 3 de course
dino_shield_4.png    # Frame 4 de course
dino_shield_jump.png # Saut
dino_shield_duck.png # Accroupi
```

### ❤️ **Power-up Health Boost (Violet)**
```
dino_health_1.png    # Frame 1 de course
dino_health_2.png    # Frame 2 de course
dino_health_3.png    # Frame 3 de course
dino_health_4.png    # Frame 4 de course
dino_health_jump.png # Saut
dino_health_duck.png # Accroupi
```

### 💰 **Power-up Double Coins (Doré)**
```
dino_coins_1.png    # Frame 1 de course
dino_coins_2.png    # Frame 2 de course
dino_coins_3.png    # Frame 3 de course
dino_coins_4.png    # Frame 4 de course
dino_coins_jump.png # Saut
dino_coins_duck.png # Accroupi
```

### 🔥 **Power-up Damage Boost (Rouge)**
```
dino_damage_1.png    # Frame 1 de course
dino_damage_2.png    # Frame 2 de course
dino_damage_3.png    # Frame 3 de course
dino_damage_4.png    # Frame 4 de course
dino_damage_jump.png # Saut
dino_damage_duck.png # Accroupi
```

## 🎨 Suggestions de Design

### **Speed Boost (Vert)**
- Dino avec des éclairs verts
- Traînée de vitesse
- Effet de mouvement flou

### **Shield (Bleu)**
- Dino avec un bouclier bleu
- Aura protectrice
- Effet de cristal

### **Health Boost (Violet)**
- Dino avec des cœurs violets
- Aura de guérison
- Effet de régénération

### **Double Coins (Doré)**
- Dino avec des pièces dorées
- Effet de richesse
- Particules dorées

### **Damage Boost (Rouge)**
- Dino avec des flammes rouges
- Effet de puissance
- Aura de destruction

## 📋 Instructions

1. **Créez les images** selon les noms exacts ci-dessus
2. **Placez-les** dans le dossier `assets/images/`
3. **Ajoutez-les** au `pubspec.yaml` si nécessaire
4. **Testez** en jouant et en collectant des power-ups

## ⚠️ Notes Importantes

- **Taille recommandée** : 80x80 pixels (comme les images actuelles)
- **Format** : PNG avec transparence
- **Fallback** : Si une image n'existe pas, le système utilisera automatiquement les images par défaut
- **Performance** : Les images sont chargées à la demande

## 🔧 Test

Une fois les images créées, testez en :
1. Lançant le jeu
2. Collectant un power-up
3. Vérifiant que le dino change d'apparence
4. Vérifiant que l'effet disparaît à la fin du power-up 