# TP : Construction d'Images Container avec Dockerfiles

## Introduction
Créer une image container manuellement est possible, mais cela nécessite des processus manuels. Docker fournit une solution à ce problème : le Dockerfile. Dans ce TP, vous allez créer un Dockerfile pour construire une image et héberger un site web statique.

## Architecture du Projet

---

## 🐳 Installation de docker

### 1. Mettre à jour les paquets
```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Installer les dépendances
```bash
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

### 3. Ajouter la clé GPG officielle de Docker
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

### 4. Ajouter le repository Docker
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 5. Installer Docker Engine
```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## Étape 1 : Connexion et Configuration Initiale

### 1.1 Connexion au Serveur
```bash
# 🔐 Connexion SSH au serveur
ssh root@<PUBLIC_IP_ADDRESS>
```
créer cette structure:
<img width="684" height="261" alt="image" src="https://github.com/user-attachments/assets/07a46aa3-f951-41d8-a327-40e5f6dd60bf" />

Copier en local le dossier widget-factory-inc.

# 📁 Navigation dans le répertoire du projet
cd widget-factory-inc

# ✅ Vérification du contenu du répertoire
ls -la
```

---

## Étape 2 : Construction de la Première Version (0.1)

### 2.1 Création du Dockerfile Initial
```bash
# 📝 Création/édition du Dockerfile
vim Dockerfile
```

**Contenu du Dockerfile (Version 0.1) :**
```dockerfile
# 🐳 Image de base : Apache HTTP Server version 2.4
# FROM spécifie l'image parente qui sert de point de départ
FROM httpd:2.4

# 🔄 Mise à jour du système et nettoyage
# RUN exécute des commandes pendant la construction de l'image
# && enchaîne les commandes pour réduire le nombre de layers
# -y répond "yes" automatiquement aux prompts
# apt update : met à jour la liste des paquets disponibles
# apt upgrade : met à jour les paquets installés
# apt autoremove : supprime les paquets devenus inutiles
# apt clean : nettoie le cache des paquets téléchargés
# rm -rf /var/lib/apt/lists* : supprime les listes de paquets pour réduire la taille
RUN apt update -y && apt upgrade -y && apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists*

# 💡 NOTES :
# - Chaque instruction RUN crée un nouveau layer
# - Le chainage avec && réduit le nombre de layers
# - Le nettoyage réduit significativement la taille de l'image
```

### 2.2 Construction de l'Image Version 0.1
```bash
# 🏗️ Construction de l'image avec tag version 0.1
# -t : tag (nom:version) de l'image
# . : contexte de build (répertoire courant)
docker build -t widgetfactory:0.1 .

# ✅ Vérification de la construction
docker images | grep widgetfactory
```

### 2.3 Analyse des Layers et Taille
```bash
# 📊 Configuration des variables pour l'analyse
# showLayers : affiche les layers de l'image
# showSize : affiche la taille de l'image
export showLayers='{{ range .RootFS.Layers }}{{ println . }}{{end}}'
export showSize='{{ .Size }}'

# 🖼️ Liste de toutes les images
docker images

# 📏 Taille de l'image widgetfactory:0.1
docker inspect -f "$showSize" widgetfactory:0.1

# 🎨 Layers de l'image widgetfactory:0.1
docker inspect -f "$showLayers" widgetfactory:0.1

# 🔍 Comparaison avec l'image de base httpd:2.4
# récipérer l'image s'il n'existe pas en local
docker pull httpd:2.4
docker inspect -f "$showLayers" httpd:2.4

# 💡 OBSERVATION :
# Les layers de widgetfactory:0.1 incluent ceux de httpd:2.4 PLUS les nouvelles couches
# Chaque instruction dans le Dockerfile ajoute un layer
```

---

## Étape 3 : Version 0.2 - Suppression de la Page de Bienvenue

### 3.1 Modification du Dockerfile
```bash
# 📝 Édition du Dockerfile pour la version 0.2
vim Dockerfile
```

**Dockerfile mis à jour (Version 0.2) :**
```dockerfile
FROM httpd:2.4

# 🔄 Mise à jour et nettoyage du système
RUN apt update -y && apt upgrade -y && apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists*

# 🗑️ Suppression de la page d'accueil par défaut d'Apache
# rm -f : suppression forcée sans erreur si le fichier n'existe pas
# /usr/local/apache2/htdocs/index.html : page welcome d'Apache par défaut
RUN rm -f /usr/local/apache2/htdocs/index.html

# 💡 NOTES :
# - Cette instruction crée un nouveau layer
# - Le fichier est supprimé mais reste dans les layers précédents (utilisation d'espace)
# - En réalité, le fichier est "masqué" pour l'utilisateur final
```

### 3.2 Construction de l'Image Version 0.2
```bash
# 🏗️ Construction de la version 0.2
docker build -t widgetfactory:0.2 .

# ✅ Vérification des images
docker images | grep widgetfactory
```

### 3.3 Analyse Comparative
```bash
# 📏 Comparaison des tailles
echo "=== TAILLE VERSION 0.1 ==="
docker inspect -f "$showSize" widgetfactory:0.1

echo "=== TAILLE VERSION 0.2 ==="  
docker inspect -f "$showSize" widgetfactory:0.2

# 🎨 Comparaison des layers
echo "=== LAYERS VERSION 0.1 ==="
docker inspect -f "$showLayers" widgetfactory:0.1

echo "=== LAYERS VERSION 0.2 ==="
docker inspect -f "$showLayers" widgetfactory:0.2

# 🔍 Vérification du contenu du conteneur
# --rm : supprime le conteneur après utilisation
# -it : mode interactif avec terminal
# bash : shell pour explorer le conteneur
docker run --rm -it widgetfactory:0.2 bash

# 📁 Dans le conteneur, vérification du dossier htdocs
ls -la /usr/local/apache2/htdocs/

# 🚪 Sortie du conteneur
exit

# 💡 OBSERVATIONS :
# - La version 0.2 est légèrement plus grosse (nouveau layer)
# - Le fichier index.html a bien été supprimé du système de fichiers final
# - Mais il reste dans les layers précédents (optimisation possible)
```

---

## Étape 4 : Version 0.3 - Ajout du Site Web

### 4.1 Modification Finale du Dockerfile
```bash
# 📝 Édition finale du Dockerfile
vim Dockerfile
```

**Dockerfile Final (Version 0.3) :**
```dockerfile
FROM httpd:2.4

# 🔄 Mise à jour et nettoyage du système
RUN apt update -y && apt upgrade -y && apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists*

# 🗑️ Suppression de la page d'accueil par défaut
RUN rm -f /usr/local/apache2/htdocs/index.html

# 📁 Définition du répertoire de travail
# WORKDIR change le répertoire courant pour les instructions suivantes
# Toutes les commandes COPY/RUN suivantes s'exécuteront dans ce répertoire
WORKDIR /usr/local/apache2/htdocs

# 📦 Copie des fichiers du site web
# COPY ./web . : copie le contenu du dossier ./web local vers le répertoire courant (.) du conteneur
# ./web : source (dans le contexte de build)
# . : destination (dans l'image, soit /usr/local/apache2/htdocs grâce à WORKDIR)
COPY ./web .

# 💡 NOTES IMPORTANTES :
# - WORKDIR crée le répertoire s'il n'existe pas
# - COPY ajoute les fichiers avec leurs permissions
# - Le dossier ./web doit exister dans le contexte de build
# - Chaque fichier copié ajoute potentiellement un layer (optimisable avec .dockerignore)
```

### 4.2 Construction de l'Image Version 0.3
```bash
# 🏗️ Construction de la version finale
docker build -t widgetfactory:0.3 .

# ✅ Vérification de toutes les versions
docker images | grep widgetfactory
```

### 4.3 Analyse Détaillée de la Version Finale
```bash
# 📊 Comparaison complète des versions
echo "=== COMPARAISON DES TAILLES ==="
echo "Version 0.1 : $(docker inspect -f "$showSize" widgetfactory:0.1) octets"
echo "Version 0.2 : $(docker inspect -f "$showSize" widgetfactory:0.2) octets" 
echo "Version 0.3 : $(docker inspect -f "$showSize" widgetfactory:0.3) octets"

# 🎨 Analyse des layers
echo "=== LAYERS VERSION 0.3 ==="
docker inspect -f "$showLayers" widgetfactory:0.3

# 🔍 Inspection du contenu final
docker run --rm -it widgetfactory:0.3 bash

# 📁 Dans le conteneur :
ls -la /usr/local/apache2/htdocs/
# ➡️ Devrait montrer les fichiers de votre site web

# 🚪 Sortie
exit
```

---

## Étape 5 : Exécution et Test du Conteneur

### 5.1 Lancement du Conteneur Web
```bash
# 🚀 Exécution du conteneur en mode détaché
# --name web1 : nom du conteneur pour référence future
# -p 80:80 : mapping port hôte:conteneur (expose le port 80)
# -d : mode détaché (exécution en arrière-plan)
docker run --name web1 -p 80:80 -d widgetfactory:0.3

# ✅ Vérification du statut
docker ps

# 🔍 Test de la connexion HTTP
curl -I http://localhost

# 🌐 Alternative : téléchargement de la page d'accueil
wget -O test.html http://localhost

# 📖 Affichage du contenu
cat test.html
```

### 5.2 Gestion du Conteneur
```bash
# ⏹️ Arrêt du conteneur
docker stop web1

# ▶️ Redémarrage
docker start web1

# 🔧 Connexion au conteneur en cours d'exécution
docker exec -it web1 bash

# 📁 Vérification des fichiers dans le conteneur
ls -la /usr/local/apache2/htdocs/

# 🚪 Sortie
exit
```

### 5.3 Validation du Contenu
```bash
# 📥 Téléchargement de la page depuis le serveur
wget http://localhost -O downloaded_index.html

# 🔄 Comparaison avec les fichiers originaux
echo "=== COMPARAISON INDEX.HTML ==="
diff web/index.html downloaded_index.html

# 🧹 Nettoyage
rm test.html downloaded_index.html

# 💡 Si diff ne retourne rien : SUCCÈS ! Les fichiers sont identiques
```

---

## Étape 6 : Commandes Avancées d'Analyse

### 6.1 Inspection Détaillée des Images
```bash
# 🔍 Histoire de construction de chaque image
echo "=== HISTORIQUE WIDGETFACTORY:0.1 ==="
docker history widgetfactory:0.1

echo "=== HISTORIQUE WIDGETFACTORY:0.2 ==="
docker history widgetfactory:0.2

echo "=== HISTORIQUE WIDGETFACTORY:0.3 ==="
docker history widgetfactory:0.3

# 📊 Analyse de la taille des layers
docker history --no-trunc widgetfactory:0.3 | head -10
```

### 6.2 Optimisations Potentielles
```bash
# 💡 VERSION OPTIMISÉE (pour référence future)
cat > Dockerfile.optimized << 'EOF'
FROM httpd:2.4

# Combine toutes les opérations système en une seule instruction RUN
RUN apt update -y && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists* && \
    rm -f /usr/local/apache2/htdocs/index.html

WORKDIR /usr/local/apache2/htdocs

COPY ./web .

EOF

# 🏗️ Test de la version optimisée
docker build -t widgetfactory:optimized -f Dockerfile.optimized .
```

---

## 📚 Concepts Clés Expliqués

### **Layers Docker**
```
Image Finale = Base Image + Layer 1 + Layer 2 + ... + Layer N
```
- ✅ **Avantage** : Cache et réutilisation des layers
- ⚠️ **Attention** : Chaque instruction ajoute un layer permanent

### **Instructions Dockerfile**
| Instruction | Usage | Crée un Layer |
|-------------|-------|---------------|
| `FROM` | Image de base | ✅ |
| `RUN` | Exécution de commandes | ✅ |
| `COPY` | Copie de fichiers | ✅ |
| `WORKDIR` | Changement de répertoire | ❌ |
| `EXPOSE` | Documentation des ports | ❌ |

### **Bonnes Pratiques**
```dockerfile
# ✅ BON - Combine les RUN
RUN apt update && apt install -y package && apt clean

# ❌ MAUVAIS - Multiple RUN séparés  
RUN apt update
RUN apt install -y package
RUN apt clean
```

---

## 🧪 Validation Finale

### Test Complet de l'Application
```bash
# 🚀 Lancement final
docker run --name final-web -p 8080:80 -d widgetfactory:0.3

# ✅ Test fonctionnel
echo "=== TEST FONCTIONNEL ==="
if curl -s http://localhost:8080 | grep -q "widget"; then
    echo "✅ SUCCÈS : Site web fonctionnel et contenu correct"
else
    echo "❌ ÉCHEC : Problème avec le site web"
fi

# 🧹 Nettoyage final
docker stop final-web
docker rm final-web

# 📋 Résumé des images créées
echo "=== IMAGES CRÉÉES ==="
docker images --filter "reference=widgetfactory*"
```

## ✅ **Conclusion**

Vous avez réussi à :

1. ✅ **Créer un Dockerfile** étape par étape
2. ✅ **Comprendre les layers** Docker et leur impact sur la taille
3. ✅ **Construire et tagger** des images avec différentes versions
4. ✅ **Copier des fichiers** dans l'image avec COPY
5. ✅ **Configurer l'environnement** avec WORKDIR
6. ✅ **Exécuter et tester** un conteneur web
7. ✅ **Analyser et optimiser** les constructions Docker


Votre site web est maintenant conteneurisé et prêt pour le déploiement ! 🐳🚀



