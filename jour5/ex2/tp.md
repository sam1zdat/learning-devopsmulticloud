# TP: Déploiement d'une image Docker dans Kubernetes avec Jenkins

## Objectif du TP
Créer un pipeline Jenkins complet pour déployer automatiquement une application conteneurisée dans un cluster Kubernetes.

## Prérequis
- Cluster Kubernetes opérationnel
- Jenkins installé et configuré
- Accès à un registre Docker (Docker Hub, Azure Container Registry, etc.)
- Kubectl configuré
- Git installé

---

## Étape 1: Installation et Configuration des Outils

### 1.1 Installation de Jenkins

```bash
# Sur Ubuntu/Debian
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install jenkins openjdk-11-jdk

# Démarrer Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Obtenir le mot de passe initial
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 1.2 Installation des Plugins Jenkins

Dans l'interface Jenkins (http://localhost:8080), installer les plugins suivants :
- **Pipeline**
- **Kubernetes**
- **Docker Pipeline**
- **Git**
- **Blue Ocean** (optionnel)

### 1.3 Configuration des Credentials Jenkins

1. Aller dans **Gérer Jenkins** > **Gérer les identifiants**
2. Ajouter les credentials suivants :

**Type: Secret texte**
- ID: `dockerhub-password`
- Secret: [Votre mot de passe Docker Hub]

**Type: Username with password**
- ID: `dockerhub-credentials`
- Username: [Votre username Docker Hub]
- Password: [Votre mot de passe Docker Hub]

**Type: Secret file**
- ID: `kubeconfig`
- File: [Votre fichier ~/.kube/config]

### 1.4 Configuration de l'accès Kubernetes pour Jenkins

```bash
# Créer un namespace pour Jenkins
kubectl create namespace jenkins

# Créer un ServiceAccount pour Jenkins
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: jenkins
EOF

# Créer un ClusterRoleBinding
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-rbac
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: jenkins
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
```

---

## Étape 2: Préparation de l'Application

### 2.1 Structure du projet

```bash
mkdir my-app && cd my-app
mkdir k8s docker
```

### 2.2 Création du Dockerfile

```dockerfile
# docker/Dockerfile
FROM nginx:alpine
COPY html /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 2.3 Création du fichier HTML

```bash
mkdir html
cat > html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>My App</title>
</head>
<body>
    <h1>Hello from Kubernetes deployed by Jenkins!</h1>
    <p>Version: ${VERSION}</p>
</body>
</html>
EOF
```

### 2.4 Création des manifests Kubernetes

**k8s/deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: default
  labels:
    app: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: ${IMAGE_NAME}:${IMAGE_TAG}
        ports:
        - containerPort: 80
        env:
        - name: VERSION
          value: "${VERSION}"
---
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  namespace: default
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

**k8s/ingress.yaml** (optionnel)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: my-app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

---

## Étape 3: Création du Jenkinsfile

### 3.1 Pipeline Jenkins complet

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'votredockerhub/my-app'
        KUBE_NAMESPACE = 'default'
        GIT_REPO = 'https://github.com/votrerepo/my-app.git'
    }
    
    parameters {
        string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Tag de l\'image Docker')
        string(name: 'VERSION', defaultValue: '1.0.0', description: 'Version de l\'application')
        booleanParam(name: 'DEPLOY_TO_K8S', defaultValue: true, description: 'Déployer sur Kubernetes')
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: "${GIT_REPO}"
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    // Préparer le fichier HTML avec la version
                    sh """
                    sed 's/\\\${VERSION}/${params.VERSION}/' html/index.html > html/index_version.html
                    mv html/index_version.html html/index.html
                    """
                    
                    // Build de l'image
                    docker.build("${DOCKER_IMAGE}:${params.IMAGE_TAG}", "-f docker/Dockerfile .")
                }
            }
        }
        
        stage('Test Image') {
            steps {
                script {
                    // Lancer un conteneur de test
                    docker.image("${DOCKER_IMAGE}:${params.IMAGE_TAG}").withRun('-p 8080:80') { c ->
                        sh 'sleep 10'
                        sh 'curl -f http://localhost:8080 || exit 1'
                    }
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'dockerhub-credentials') {
                        docker.image("${DOCKER_IMAGE}:${params.IMAGE_TAG}").push()
                        
                        // Tag également comme latest si ce n'est pas déjà le cas
                        if (params.IMAGE_TAG != 'latest') {
                            docker.image("${DOCKER_IMAGE}:${params.IMAGE_TAG}").push('latest')
                        }
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                expression { params.DEPLOY_TO_K8S == true }
            }
            steps {
                script {
                    // Configuration de l'accès Kubernetes
                    withKubeConfig([credentialsId: 'kubeconfig', serverUrl: '']) {
                        
                        // Préparer les manifests avec les variables
                        sh """
                        export IMAGE_NAME=${DOCKER_IMAGE}
                        export IMAGE_TAG=${params.IMAGE_TAG}
                        export VERSION=${params.VERSION}
                        
                        envsubst < k8s/deployment.yaml > k8s/deployment-prepared.yaml
                        """
                        
                        // Appliquer les manifests
                        sh "kubectl apply -f k8s/deployment-prepared.yaml --namespace=${KUBE_NAMESPACE}"
                        
                        // Vérifier le déploiement
                        sh """
                        kubectl rollout status deployment/my-app --namespace=${KUBE_NAMESPACE} --timeout=300s
                        kubectl get pods,svc --namespace=${KUBE_NAMESPACE} -l app=my-app
                        """
                    }
                }
            }
        }
        
        stage('Smoke Test') {
            when {
                expression { params.DEPLOY_TO_K8S == true }
            }
            steps {
                script {
                    withKubeConfig([credentialsId: 'kubeconfig', serverUrl: '']) {
                        // Récupérer l'URL du service
                        def serviceUrl = sh(
                            script: "kubectl get svc my-app-service --namespace=${KUBE_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'",
                            returnStdout: true
                        ).trim()
                        
                        if (!serviceUrl) {
                            serviceUrl = sh(
                                script: "kubectl get svc my-app-service --namespace=${KUBE_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'",
                                returnStdout: true
                            ).trim()
                        }
                        
                        if (serviceUrl) {
                            // Test de l'application déployée
                            sh "curl -f http://${serviceUrl} || exit 1"
                            echo "Application déployée avec succès: http://${serviceUrl}"
                        } else {
                            echo "Service LoadBalancer non encore disponible"
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Nettoyage
            sh 'docker system prune -f || true'
            echo 'Build completed - see console output for details'
        }
        success {
            emailext (
                subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: "Le déploiement de ${DOCKER_IMAGE}:${params.IMAGE_TAG} a réussi.\n\nConsulter: ${env.BUILD_URL}",
                to: "admin@example.com"
            )
        }
        failure {
            emailext (
                subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: "Le déploiement de ${DOCKER_IMAGE}:${params.IMAGE_TAG} a échoué.\n\nConsulter: ${env.BUILD_URL}",
                to: "admin@example.com"
            )
        }
    }
}
```

---

## Étape 4: Configuration du Job Jenkins

### 4.1 Création du Pipeline

1. **Dans Jenkins**, cliquer sur **Nouveau Item**
2. **Nom**: `my-app-deployment`
3. **Type**: **Pipeline**
4. **Configuration** :

**Section Pipeline**
- Definition: **Pipeline script from SCM**
- SCM: **Git**
- Repository URL: [URL de votre dépôt Git]
- Credentials: [Ajouter vos credentials Git si nécessaire]
- Branch: `*/main`
- Script Path: `Jenkinsfile`

### 4.2 Configuration Avancée

**Build Triggers** (optionnel)
- ☑ GitHub hook trigger for GITScm polling
- ☑ Build periodically (ex: `H */4 * * *` pour toutes les 4 heures)

**Parameters** (déjà définis dans le Jenkinsfile)

---

## Étape 5: Premier Déploiement

### 5.1 Lancement manuel

1. Aller sur le job Jenkins
2. Cliquer sur **Build with Parameters**
3. Remplir les paramètres :
   - IMAGE_TAG: `v1.0.0`
   - VERSION: `1.0.0`
   - DEPLOY_TO_K8S: ☑ true
4. Cliquer sur **Build**

### 5.2 Surveillance du déploiement

```bash
# Vérifier les pods
kubectl get pods -l app=my-app

# Vérifier les services
kubectl get svc my-app-service

# Vérifier les logs
kubectl logs -l app=my-app --tail=50

# Vérifier le déploiement
kubectl get deployment my-app
```

---

## Étape 6: Tests et Validation

### 6.1 Test de l'application

```bash
# Obtenir l'URL du service
kubectl get svc my-app-service

# Tester avec curl
curl http://[IP_EXTERNE_DU_SERVICE]
```

### 6.2 Tests de regression

Ajouter cette étape au Jenkinsfile :

```groovy
stage('Integration Tests') {
    steps {
        script {
            withKubeConfig([credentialsId: 'kubeconfig', serverUrl: '']) {
                def serviceIp = sh(
                    script: "kubectl get svc my-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'",
                    returnStdout: true
                ).trim()
                
                // Tests d'intégration
                sh """
                curl -f http://${serviceIp} > test_output.html
                grep "Hello from Kubernetes" test_output.html
                grep "Version: ${params.VERSION}" test_output.html
                """
            }
        }
    }
}
```

---

## Étape 7: Nettoyage (optionnel)

### 7.1 Script de nettoyage

```bash
#!/bin/bash
# cleanup.sh

# Supprimer le déploiement
kubectl delete -f k8s/deployment.yaml

# Supprimer l'image Docker
docker rmi docker.io/votredockerhub/my-app:latest

# Nettoyer Jenkins workspace
rm -rf /var/lib/jenkins/workspace/my-app-deployment
```

---

## Dépannage Common

### Problèmes courants et solutions

1. **Erreur d'authentification Docker**
   - Vérifier les credentials dans Jenkins
   - Tester: `docker login`

2. **Accès Kubernetes refusé**
   - Vérifier le kubeconfig
   - Tester: `kubectl get nodes`

3. **Image pull errors**
   - Vérifier que l'image est bien pushée
   - Vérifier les secrets Docker dans Kubernetes

4. **Resources insuffisantes**
   - Vérifier les resources du cluster
   - Ajuster les requests/limits dans le deployment

---

## Bonnes Pratiques à Implémenter

1. **Sécurité**
   - Utiliser des secrets Kubernetes pour les credentials
   - Scanner les images avec Trivy/Clair
   - RBAC minimal pour Jenkins

2. **Monitoring**
   - Ajouter des probes de santé
   - Métriques et logs
   - Alerting sur les échecs

3. **Optimisation**
   - Cache des layers Docker
   - Build multi-stage
   - Resource limits
