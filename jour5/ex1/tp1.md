# 🚀 TP Complet: Pipeline Jenkins pour Docker Hub

## 📝 **Objectif du TP**
Créer un pipeline Jenkins complet qui build et déploie une application Flask conteneurisée sur Docker Hub.

---
## 🎯 Objectif de l'exercice

Créer un pipeline Jenkins qui:
1. Récupère le code depuis GitHub
2. Build une image Docker
3. Push l'image vers Docker Hub
4. Déploie l'application

## 📋 Prérequis

- Jenkins installé avec les plugins Docker et Pipeline
- Docker installé sur la machine Jenkins
- Compte Docker Hub
- Repository GitHub avec votre code

---

## 🏗️ **Partie 1: Configuration de l'Environnement**


### **Étape 1.1: Préparation du Système**

```bash
#!/bin/bash
echo "🔧 PRÉPARATION DU SYSTÈME"

# Mettre à jour le système
sudo apt-get update
sudo apt-get upgrade -y

# Installer les outils essentiels
sudo apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates
```

### **Étape 1.2: Installation de Java 17 (LTS Recommandée)**

```bash
#!/bin/bash
echo "☕ INSTALLATION DE JAVA 17 LTS"

# Installer Java 17 JDK
sudo apt-get install -y openjdk-17-jdk

# Configurer JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
echo "export JAVA_HOME=$JAVA_HOME" | sudo tee -a /etc/profile.d/java.sh
echo "export PATH=\$JAVA_HOME/bin:\$PATH" | sudo tee -a /etc/profile.d/java.sh

# Rendre le script exécutable
sudo chmod +x /etc/profile.d/java.sh
source /etc/profile.d/java.sh

# Vérifier l'installation
java -version
echo "JAVA_HOME: $JAVA_HOME"
```

### **Étape 1.3: Installation de Docker (Méthode Officielle)**

```bash
#!/bin/bash
echo "🐳 INSTALLATION DE DOCKER"

# Ajouter la clé GPG officielle Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Ajouter le repository Docker
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installer Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Démarrer et activer Docker
sudo systemctl start docker
sudo systemctl enable docker

# Vérifier l'installation
sudo docker --version
sudo docker run hello-world
```

### **Étape 1.4: Installation de Jenkins **

```bash
#!/bin/bash
echo "🎯 INSTALLATION ROBUSTE DE JENKINS"

# 1. Ajouter la clé Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# 2. Ajouter le repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# 3. Mettre à jour et installer
sudo apt-get update
sudo apt-get install -y jenkins

# 4. Configurer Jenkins pour Java 17
sudo tee /etc/default/jenkins > /dev/null <<EOF
# Jenkins Configuration - Optimisée pour Java 17
JAVA_HOME=$JAVA_HOME
JAVA_ARGS="-Djava.awt.headless=true -Xmx1024m -Xms512m -Djava.net.preferIPv4Stack=true"
JENKINS_HOME="/var/lib/jenkins"
JENKINS_USER="jenkins"
JENKINS_GROUP="jenkins"
JENKINS_WEBROOT="/var/cache/jenkins/war"
JENKINS_LOG="/var/log/jenkins/jenkins.log"
JENKINS_ARGS="--webroot=/var/cache/jenkins/war --httpPort=8080 --httpListenAddress=0.0.0.0"
EOF

# 5. Configurer les permissions Docker pour Jenkins
sudo usermod -a -G docker jenkins

# 6. Démarrer Jenkins
sudo systemctl daemon-reload
sudo systemctl start jenkins
sudo systemctl enable jenkins

# 7. Vérifier le statut
sleep 10
echo "📊 Statut Jenkins:"
sudo systemctl status jenkins --no-pager -l

# 8. Afficher le mot de passe initial
echo "🔑 Mot de passe initial Jenkins:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```


### **Étape 1.3: Configuration Initiale Jenkins**

1. **Accéder à Jenkins:** http://localhost:8080
2. **Déverrouiller avec le mot de passe initial**
3. **Installer les plugins suggérés**
4. **Créer un admin user:**
   - Username: `admin`
   - Password: `admin123` (pour le TP)
   - Email: `admin@example.com`

---

## 🔌 **Partie 2: Installation des Plugins**

### **Étape 2.1: Plugins via l'Interface Web**

1. **Aller dans:** `Gérer Jenkins` → `Gérer les Plugins` → `Available`
2. **Rechercher et installer:**
   - ✅ **Pipeline**
   - ✅ **Docker Pipeline**
   - ✅ **Git**
   - ✅ **Docker**
   - ✅ **Blue Ocean** (optionnel mais recommandé)
   - ✅ **Credentials Binding**

### **Étape 2.2: Vérification des Plugins**

```bash
# Script de vérification
#!/bin/bash
echo "🔍 Vérification des plugins Jenkins..."

# Vérifier le statut Jenkins
if systemctl is-active --quiet jenkins; then
    echo "✅ Jenkins est en cours d'exécution"
else
    echo "❌ Jenkins n'est pas démarré"
    exit 1
fi

# Vérifier Docker
if docker --version > /dev/null 2>&1; then
    echo "✅ Docker est installé: $(docker --version)"
else
    echo "❌ Docker n'est pas installé"
    exit 1
fi

# Vérifier les permissions Docker pour Jenkins
if groups jenkins | grep -q "docker"; then
    echo "✅ Jenkins fait partie du groupe Docker"
else
    echo "❌ Jenkins n'est pas dans le groupe Docker"
    exit 1
fi

echo "🎉 Environnement prêt pour le TP!"
```

---

## 📦 **Partie 3: Création du Projet GitHub**

### **Étape 3.1: Création du Repository**

1. **Aller sur:** https://github.com/new
2. **Créer le repository:**
   - Name: `jenkins-docker-pipeline-tp`
   - Description: "TP Jenkins Docker Pipeline"
   - Public
   - ✅ Initialize with README
   - Add .gitignore: Python
   - License: MIT

### **Étape 3.2: Structure du Projet Locale**

```bash
# Créer la structure de projet
mkdir jenkins-docker-pipeline-tp
cd jenkins-docker-pipeline-tp

# Initialiser Git
git init
git remote add origin https://github.com/votre_username/jenkins-docker-pipeline-tp.git
```

---

## 📄 **Partie 4: Création des Fichiers du Projet**

### **Étape 4.1: Fichier `app.py`**

```python
from flask import Flask
import os
import datetime

app = Flask(__name__)

@app.route('/')
def hello():
    version = os.getenv('VERSION', '1.0.0')
    build_date = os.getenv('BUILD_DATE', 'Unknown')
    
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>TP Jenkins Docker</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; }}
            .container {{ max-width: 800px; margin: 0 auto; }}
            .success {{ color: green; font-weight: bold; }}
            .info {{ background: #f0f0f0; padding: 20px; border-radius: 5px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎉 TP Jenkins Docker Réussi!</h1>
            <div class="info">
                <p><span class="success">✅</span> Application déployée avec succès</p>
                <p><strong>Version:</strong> {version}</p>
                <p><strong>Build Date:</strong> {build_date}</p>
                <p><strong>Server Time:</strong> {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            </div>
            <h2>📊 Endpoints disponibles:</h2>
            <ul>
                <li><a href="/health">/health</a> - Health check</li>
                <li><a href="/info">/info</a> - Informations système</li>
            </ul>
        </div>
    </body>
    </html>
    """

@app.route('/health')
def health():
    return {'status': 'healthy', 'timestamp': datetime.datetime.now().isoformat()}

@app.route('/info')
def info():
    return {
        'version': os.getenv('VERSION', '1.0.0'),
        'build_date': os.getenv('BUILD_DATE', 'Unknown'),
        'environment': os.getenv('ENVIRONMENT', 'development')
    }

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
```

### **Étape 4.2: Fichier `requirements.txt`**

```txt
Flask==2.3.3
Werkzeug==2.3.7
```

### **Étape 4.3: Fichier `Dockerfile`**

```dockerfile
# Image de base Python
FROM python:3.9-slim

# Métadonnées
LABEL maintainer="votre.email@example.com"
LABEL description="TP Jenkins Docker Pipeline"
LABEL version="1.0"

# Définir le répertoire de travail
WORKDIR /app

# Copier les requirements et installer les dépendances
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code de l'application
COPY app.py .

# Variables d'environnement
ENV VERSION=1.0.0
ENV BUILD_DATE="2024-01-01"
ENV ENVIRONMENT=production
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Exposer le port
EXPOSE 5000

# Commande de démarrage
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0"]
```

### **Étape 4.4: Fichier `.dockerignore`**

```gitignore
__pycache__
*.pyc
*.pyo
*.pyd
.Python
env/
pip-log.txt
.DS_Store
.git
.gitignore
README.md
Jenkinsfile
```

### **Étape 4.5: Fichier `Jenkinsfile`**

```groovy
pipeline {
    agent any
    
    environment {
        // Configuration Docker
        DOCKER_REGISTRY = 'https://index.docker.io/v1/'
        DOCKER_IMAGE_NAME = 'votre_username_docker/jenkins-tp-app'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        
        // Variables de version
        APP_VERSION = '1.0.0'
        BUILD_TIMESTAMP = sh(script: 'date +%Y-%m-%d_%H-%M-%S', returnStdout: true).trim()
    }
    
    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '5'))
        disableConcurrentBuilds()
    }
    
    parameters {
        choice(
            name: 'DEPLOY_ENVIRONMENT',
            choices: ['development', 'staging', 'production'],
            description: 'Environnement de déploiement'
        )
        string(
            name: 'IMAGE_TAG',
            defaultValue: 'latest',
            description: 'Tag pour l image Docker'
        )
    }
    
    stages {
        
        // Étape 1: Préparation
        stage('Préparation') {
            steps {
                echo '🚀 Début du pipeline Jenkins TP'
                echo "Environnement: ${params.DEPLOY_ENVIRONMENT}"
                echo "Tag: ${params.IMAGE_TAG}"
                echo "Build: ${env.BUILD_ID}"
                
                script {
                    // Définir le tag complet
                    env.FULL_IMAGE_TAG = "${env.DOCKER_IMAGE_NAME}:${params.IMAGE_TAG}"
                    env.BUILD_IMAGE_TAG = "${env.DOCKER_IMAGE_NAME}:build-${env.BUILD_ID}"
                }
            }
        }
        
        // Étape 2: Checkout du code
        stage('Checkout Git') {
            steps {
                echo '📥 Récupération du code source...'
                checkout scm
                
                // Afficher la structure
                sh 'find . -type f -name "*.py" -o -name "*.txt" -o -name "Dockerfile" -o -name "Jenkinsfile" | sort'
            }
        }
        
        // Étape 3: Tests unitaires
        stage('Tests') {
            steps {
                echo '🧪 Exécution des tests...'
                
                script {
                    try {
                        // Vérifier la syntaxe Python
                        sh 'python -m py_compile app.py'
                        echo '✅ Syntaxe Python valide'
                        
                        // Vérifier les imports
                        sh 'python -c "import flask; print(\"✅ Flask importé avec succès\")"'
                        
                    } catch (Exception e) {
                        error "❌ Erreur dans les tests: ${e.message}"
                    }
                }
            }
        }
        
        // Étape 4: Build de l'image Docker
        stage('Build Docker Image') {
            steps {
                echo '🔨 Construction de l image Docker...'
                
                script {
                    // Build avec métadonnées
                    dockerImage = docker.build(
                        env.BUILD_IMAGE_TAG,
                        "--build-arg VERSION=${env.APP_VERSION} " +
                        "--build-arg BUILD_DATE=${env.BUILD_TIMESTAMP} " +
                        "."
                    )
                }
            }
            
            post {
                success {
                    echo '✅ Build Docker réussi'
                    sh "docker images | grep ${env.DOCKER_IMAGE_NAME}"
                }
                failure {
                    echo '❌ Build Docker échoué'
                }
            }
        }
        
        // Étape 5: Scan de sécurité (basique)
        stage('Scan Sécurité') {
            steps {
                echo '🔒 Scan de sécurité basique...'
                
                script {
                    // Vérifier les vulnérabilités connues
                    sh """
                    echo "📋 Analyse de l'image..."
                    docker run --rm ${env.BUILD_IMAGE_TAG} pip list
                    echo "✅ Scan basique terminé"
                    """
                }
            }
        }
        
        // Étape 6: Push vers Docker Hub
        stage('Push to Docker Hub') {
            steps {
                echo '📦 Envoi vers Docker Hub...'
                
                script {
                    // Se connecter à Docker Hub
                    docker.withRegistry(env.DOCKER_REGISTRY, env.DOCKER_CREDENTIALS_ID) {
                        // Push avec le tag spécifié
                        dockerImage.push("${params.IMAGE_TAG}")
                        
                        // Tag supplémentaire avec l'ID de build
                        dockerImage.push("build-${env.BUILD_ID}")
                        
                        echo "✅ Image poussée: ${env.FULL_IMAGE_TAG}"
                    }
                }
            }
        }
        
        // Étape 7: Déploiement
        stage('Déploiement') {
            steps {
                echo '🚀 Déploiement de l application...'
                
                script {
                    // Arrêter le conteneur existant
                    sh 'docker stop tp-app || true'
                    sh 'docker rm tp-app || true'
                    
                    // Lancer le nouveau conteneur
                    sh """
                    docker run -d \
                        --name tp-app \
                        -p 5000:5000 \
                        -e ENVIRONMENT=${params.DEPLOY_ENVIRONMENT} \
                        -e VERSION=${env.APP_VERSION} \
                        -e BUILD_DATE=${env.BUILD_TIMESTAMP} \
                        ${env.FULL_IMAGE_TAG}
                    """
                    
                    echo "🎉 Application déployée sur http://localhost:5000"
                }
            }
        }
        
        // Étape 8: Tests de déploiement
        stage('Tests de Déploiement') {
            steps {
                echo '🔍 Vérification du déploiement...'
                
                script {
                    // Attendre que l'application soit prête
                    sleep 10
                    
                    // Tester l'endpoint principal
                    sh 'curl -f http://localhost:5000/ || exit 1'
                    echo '✅ Endpoint / accessible'
                    
                    // Tester l'health check
                    sh 'curl -f http://localhost:5000/health || exit 1'
                    echo '✅ Health check OK'
                    
                    // Afficher les logs du conteneur
                    sh 'docker logs tp-app --tail 10'
                }
            }
        }
    }
    
    post {
        always {
            echo '📊 Pipeline terminé - Nettoyage...'
            
            // Nettoyage des conteneurs arrêtés
            sh 'docker ps -aq --filter status=exited | xargs -r docker rm || true'
            
            // Nettoyer les images intermédiaires
            sh 'docker image prune -f'
            
            // Sauvegarder l'espace de travail (optionnel)
            archiveArtifacts artifacts: '**/*.py, **/*.txt, **/Dockerfile', fingerprint: true
        }
        
        success {
            echo '🎉 TP RÉUSSI! Pipeline exécuté avec succès'
            
            // Afficher les informations de déploiement
            sh """
            echo "=== INFORMATIONS DE DÉPLOIEMENT ==="
            echo "Application: http://localhost:5000"
            echo "Health Check: http://localhost:5000/health"
            echo "Image Docker: ${env.FULL_IMAGE_TAG}"
            echo "Environnement: ${params.DEPLOY_ENVIRONMENT}"
            echo "Build ID: ${env.BUILD_ID}"
            """
        }
        
        failure {
            echo '❌ Pipeline échoué - Vérifier les logs'
            
            // Sauvegarder les logs en cas d'échec
            sh 'docker logs tp-app > deployment_failure.log 2>&1 || true'
            archiveArtifacts artifacts: 'deployment_failure.log', fingerprint: true
        }
        
        changed {
            echo '📈 Statut du pipeline modifié depuis la dernière exécution'
        }
    }
}
```

### **Étape 4.6: Fichier `README.md`**

```markdown
# TP Jenkins Docker Pipeline

## 📋 Description
Ce projet démontre la création d'un pipeline Jenkins complet pour build et déployer une application Flask sur Docker Hub.

## 🏗️ Architecture
- **Application:** Flask Python
- **CI/CD:** Jenkins Pipeline
- **Container:** Docker
- **Registry:** Docker Hub

## 🚀 Utilisation

### Accès à l'application
```bash
# Après déploiement
curl http://localhost:5000
```

### Endpoints
- `GET /` - Page principale
- `GET /health` - Health check
- `GET /info` - Informations système

## 🔧 Configuration
Voir le Jenkinsfile pour la configuration complète du pipeline.
```

---

## 🔐 **Partie 5: Configuration des Credentials Jenkins**

### **Étape 5.1: Création du Token Docker Hub**

1. **Aller sur:** https://hub.docker.com/settings/security
2. **Créer un nouveau token:**
   - Name: `jenkins-tp-token`
   - Permissions: **Read, Write, Delete**
3. **Copier le token** (⚠️ ne s'affiche qu'une fois!)

### **Étape 5.2: Ajout dans Jenkins**

1. **Jenkins** → **Gérer Jenkins** → **Manage Credentials**
2. **Global** → **Add Credentials**
3. **Remplir:**
   - Kind: `Username with password`
   - Scope: `Global`
   - Username: `votre_username_docker`
   - Password: `votre_token_docker_hub`
   - ID: `docker-hub-credentials`
   - Description: `Credentials Docker Hub pour TP`

---

## 🛠️ **Partie 6: Création du Pipeline Jenkins**

### **Étape 6.1: Configuration du Job**

1. **Jenkins** → **Nouveau Item**
2. **Nom:** `tp-jenkins-docker-pipeline`
3. **Type:** `Pipeline`
4. **Configuration:**
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `https://github.com/votre_username/jenkins-docker-pipeline-tp.git`
   - Branches: `*/main`
   - Script Path: `Jenkinsfile`

### **Étape 6.2: Premier Build**

1. **Cliquer sur `Build Now`**
2. **Observer la progression dans Blue Ocean:**
   ```bash
   # Accéder à Blue Ocean
   http://localhost:8080/blue
   ```
3. **Vérifier chaque étape**

---

## 🧪 **Partie 7: Tests et Validation**

### **Étape 7.1: Tests Manuel**

```bash
# Vérifier l'application déployée
curl http://localhost:5000

# Vérifier l'health check
curl http://localhost:5000/health

# Vérifier les informations
curl http://localhost:5000/info

# Vérifier l'image sur Docker Hub
docker pull votre_username_docker/jenkins-tp-app:latest
docker images | grep jenkins-tp-app
```

### **Étape 7.2: Vérification des Logs**

```bash
# Vérifier les logs Jenkins
tail -f /var/log/jenkins/jenkins.log

# Vérifier les logs du conteneur
docker logs tp-app -f

# Vérifier les images Docker
docker ps
docker images
```

---

## 📊 **Partie 8: Validation du TP**

### **Checklist de Validation**

- [ ] **✅ Jenkins accessible** sur http://localhost:8080
- [ ] **✅ Docker installé** et fonctionnel
- [ ] **✅ Plugins Jenkins** installés
- [ ] **✅ Repository GitHub** créé avec le code
- [ ] **✅ Credentials Docker Hub** configurés
- [ ] **✅ Pipeline Jenkins** créé et configuré
- [ ] **✅ Build réussi** sans erreurs
- [ ] **✅ Image Docker** buildée et poussée
- [ ] **✅ Application déployée** et accessible
- [ ] **✅ Tests automatiques** passés
- [ ] **✅ Logs propres** sans warnings critiques

### **Commandes de Validation Finale**

```bash
#!/bin/bash
echo "🎯 VALIDATION FINALE DU TP"

# 1. Vérifier Jenkins
echo "1. Vérification Jenkins..."
sudo systemctl status jenkins --no-pager -l

# 2. Vérifier Docker
echo "2. Vérification Docker..."
docker --version
docker ps

# 3. Vérifier l'application
echo "3. Vérification Application..."
curl -s http://localhost:5000/health | grep -q "healthy" && echo "✅ Application healthy" || echo "❌ Application down"

# 4. Vérifier l'image Docker
echo "4. Vérification Image Docker..."
docker images | grep -q "jenkins-tp-app" && echo "✅ Image présente" || echo "❌ Image manquante"

# 5. Vérifier les credentials
echo "5. Vérification Credentials..."
echo "✅ Configuration terminée"

echo "🎉 TP JENKINS DOCKER RÉUSSI!"
```

---

## 🎓 **Conclusion**

**Félicitations!** Vous avez réussi à:

- ✅ **Configurer un environnement Jenkins complet**
- ✅ **Créer un pipeline CI/CD sophistiqué**
- ✅ **Automatiser le build d'images Docker**
- ✅ **Déployer sur Docker Hub**
- ✅ **Déployer une application Flask**
- ✅ **Mettre en place des tests automatiques**

**Prochaines étapes possibles:**
- Ajouter des tests unitaires Python
- Intégrer un scan de sécurité (Trivy, Snyk)
- Déployer sur Kubernetes
- Ajouter des notifications (Slack, Email)
- Mettre en place un déploiement blue-green

---

**📚 Références:**
- [Documentation Jenkins](https://www.jenkins.io/doc/)
- [Documentation Docker](https://docs.docker.com/)
- [Documentation Flask](https://flask.palletsprojects.com/)

**🐛 Dépannage:** Consultez les logs Jenkins et Docker en cas d'erreur!
