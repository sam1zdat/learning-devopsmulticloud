# TP : Déploiement de conteneurs Docker sur Azure App Service avec GitHub Actions

## Objectif du TP
Apprendre à mettre en place un pipeline CI/CD avec GitHub Actions pour déployer automatiquement des conteneurs Docker sur Azure App Service.

## Prérequis
- Compte GitHub
- Compte Azure avec abonnement actif
- Connaissances de base en Docker et YAML
- Accès à Azure CLI

## Durée estimée
2-3 heures

---

## Partie 1 : Configuration de l'environnement Azure

### Étape 1.1 : Création d'un Resource Group (optionnel)
```bash
az group create --name rg-tp-docker-appservice --location francecentral
```

### Étape 1.2 : Création d'un Azure Container Registry (ACR)
```bash
az acr create --resource-group rg-tp-docker-appservice \
              --name acrtpdevops<votre-nom> \
              --sku Basic \
              --admin-enabled true
```

### Étape 1.3 : Création d'un App Service Plan
```bash
az appservice plan create --name asp-tp-docker \
                          --resource-group <votre-ressource-group> \
                          --sku B1 \
                          --is-linux
```

### Étape 1.4 : Création d'une Web App
```bash
az webapp create --name webapp-tp-<votre-nom> \
                 --resource-group rg-tp-docker-appservice \
                 --plan asp-tp-docker \
                 --deployment-container-image-name nginx:latest
```

---

## Partie 2 : Préparation du projet GitHub

### Étape 2.1 : Structure du projet
Créez un repository GitHub avec la structure suivante :

```
tp-docker-azure/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── Dockerfile
├── app/
│   └── index.html
└── README.md
```

### Étape 2.2 : Création des fichiers

**Dockerfile** :
```dockerfile
FROM nginx:alpine
COPY app/ /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**app/index.html** :
```html
<!DOCTYPE html>
<html>
<head>
    <title>TP Docker Azure</title>
</head>
<body>
    <h1>TP Réussi ! Déploiement Docker sur Azure App Service</h1>
    <p>Application déployée via GitHub Actions</p>
</body>
</html>
```

---

## Partie 3 : Configuration des secrets GitHub

### Étape 3.1 : Récupération des informations ACR
```bash
az acr credential show --name acrtpdevops<votre-nom> --query passwords[0].value
```

### Étape 3.2 : Ajout des secrets dans GitHub
Dans votre repository GitHub → Settings → Secrets and variables → Actions :

- `AZURE_CREDENTIALS` : Service Principal credentials (voir étape 3.3)
- `REGISTRY_USERNAME` : Nom de votre ACR
- `REGISTRY_PASSWORD` : Mot de passe ACR récupéré précédemment

### Étape 3.3 : Création d'un Service Principal
```bash
az ad sp create-for-rbac --name "sp-tp-github-actions" \
                         --role contributor \
                         --scopes /subscriptions/<votre-subscription-id> \
                         --sdk-auth
```

Copiez le résultat JSON complet dans le secret `AZURE_CREDENTIALS`.

---

## Partie 4 : Création du workflow GitHub Actions

**.github/workflows/deploy.yml** :
```yaml
name: Build and Deploy Docker to Azure App Service

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY_NAME: acrtpdevops<votre-nom>
  IMAGE_NAME: tp-docker-app
  RESOURCE_GROUP: rg-tp-docker-appservice
  WEBAPP_NAME: webapp-tp-<votre-nom>

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Log in to Azure Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY_NAME }}.azurecr.io
        username: ${{ secrets.REGISTRY_USERNAME }}
        password: ${{ secrets.REGISTRY_PASSWORD }}

    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: |
          ${{ env.REGISTRY_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:${{ github.sha }}
          ${{ env.REGISTRY_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:latest
        cache-from: type=gha
        cache-to: type=gha,mode=max

    - name: Log in to Azure
      uses: azure/login@v2
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Deploy to Azure App Service
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.WEBAPP_NAME }}
        resource-group: ${{ env.RESOURCE_GROUP }}
        images: '${{ env.REGISTRY_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:${{ github.sha }}'

    - name: Azure logout
      run: |
        az logout
```

---

## Partie 5 : Test du déploiement

### Étape 5.1 : Déclenchement du pipeline
1. Poussez votre code sur la branche main
2. Allez dans l'onglet "Actions" de votre repository GitHub
3. Surveillez l'exécution du workflow

### Étape 5.2 : Vérification du déploiement
```bash
az webapp show --name webapp-tp-<votre-nom> \
               --resource-group rg-tp-docker-appservice \
               --query state
```

### Étape 5.3 : Test de l'application
Ouvrez votre navigateur et allez sur :
```
https://webapp-tp-<votre-nom>.azurewebsites.net
```

---

## Partie 6 : Bonnes pratiques et optimisation

### Étape 6.1 : Ajout de tests de sécurité
Modifiez votre workflow pour inclure un scan de vulnérabilités :

```yaml
- name: Scan for vulnerabilities
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: '${{ env.REGISTRY_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:${{ github.sha }}'
    format: 'sarif'
    output: 'trivy-results.sarif'
```

### Étape 6.2 : Implementation d'environnements multiples
Créez un workflow pour la préproduction :

```yaml
deploy-to-staging:
  needs: build
  runs-on: ubuntu-latest
  environment: staging
  # ... étapes de déploiement similaires
```

---

## Validation du TP

### Critères de réussite
- [ ] Le workflow GitHub Actions s'exécute sans erreur
- [ ] L'image Docker est bien poussée dans ACR
- [ ] L'application est accessible via l'URL Azure
- [ ] Les modifications de code déclenchent un nouveau déploiement
- [ ] Les logs de déploiement sont accessibles

### Questions de réflexion
1. Quel est l'avantage d'utiliser ACR plutôt que Docker Hub ?
2. Comment pourriez-vous implémenter le blue-green deployment ?
3. Quelles stratégies de rollback pourriez-vous mettre en place ?

## Nettoyage des ressources
```bash
az group delete --name rg-tp-docker-appservice --yes --no-wait
```

---

Ce TP vous permet de maîtriser les concepts clés du déploiement continu de conteneurs Docker sur Azure avec GitHub Actions.
