# **TP : Implémentation de GitHub Actions pour CI/CD**

## **Objectifs du TP**
À la fin de ce TP, vous serez capable de :
- Implémenter un workflow GitHub Actions pour CI/CD
- Expliquer les caractéristiques de base des workflows GitHub Actions
- Déployer une application web Azure via GitHub Actions

**Durée estimée :** 40 minutes

---

## **Exercice 1 : Importer eShopOnWeb dans votre dépôt GitHub**

### **Tâche 1 : Créer un dépôt public et importer eShopOnWeb**

1. **Ouvrez un navigateur** et allez sur [GitHub](https://github.com)
2. **Connectez-vous** avec votre compte GitHub
3. **Créez un nouveau dépôt** :
   - Cliquez sur **"New"** (Nouveau)
   - Ou allez directement sur [https://github.com/new/import](https://github.com/new/import)

4. **Configurez l'importation** :
   | Champ | Valeur |
   |-------|--------|
   | URL du dépôt source | `https://github.com/MicrosoftLearning/eShopOnWeb` |
   | Owner (Propriétaire) | Votre compte GitHub |
   | Repository Name (Nom du dépôt) | `eShopOnWeb` |
   | Privacy (Visibilité) | **Public** |

5. **Lancez l'importation** :
   - Cliquez sur **"Begin Import"** (Commencer l'importation)
   - Attendez que l'importation se termine

6. **Activez GitHub Actions** :
   - Allez dans **Settings** (Paramètres) de votre dépôt
   - Cliquez sur **Actions** → **General** (Général)
   - Sélectionnez **"Allow all actions and reusable workflows"**
   - Cliquez sur **"Save"** (Sauvegarder)

---

## **Exercice 2 : Configurer votre dépôt GitHub et l'accès Azure**

### **Tâche 1 : Créer un Service Principal Azure et le sauvegarder comme secret GitHub**

1. **Ouvrez le Portail Azure** :
   - Allez sur [https://portal.azure.com](https://portal.azure.com)
   - Connectez-vous avec votre compte

2. **Créez un groupe de ressources** :
   - Cherchez **"Resource Groups"** (Groupes de ressources)
   - Cliquez sur **"+ Create"** (Créer)
   - Nom : `rg-eshoponweb-NOM` (remplacez NOM par votre alias)
   - Cliquez sur **"Review + Create"** → **"Create"**

3. **Ouvrez Azure Cloud Shell** :
   - Cliquez sur l'icône Cloud Shell dans le portail
   - Choisissez **"Bash"** comme environnement

4. **Exécutez la commande suivante(demander aux formateurs)** (remplacez les valeurs) :
   ```bash
   az ad sp create-for-rbac --name GH-Action-eshoponweb --role contributor --scopes /subscriptions/ID-ABONNEMENT/resourceGroups/NOM-GROUPE-RESSOURCES --sdk-auth
   ```

   **Exemple** :
   ```bash
   az ad sp create-for-rbac --name GH-Action-eshoponweb --role contributor --scopes /subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-eshoponweb-alice --sdk-auth
   ```

5. **Copiez le résultat JSON** qui ressemble à :
   ```json
   {
     "clientId": "<GUID>",
     "clientSecret": "<GUID>",
     "subscriptionId": "<GUID>",
     "tenantId": "<GUID>",
     ...
   }
   ```

6. **Enregistrez le fournisseur App Service** (si pas déjà fait) :
   ```bash
   az provider register --namespace Microsoft.Web
   ```

7. **Ajoutez les credentials comme secret GitHub** :
   - Retournez sur votre dépôt GitHub
   - Allez dans **Settings** → **Secrets and variables** → **Actions**
   - Cliquez sur **"New repository secret"**
   - Nom : `AZURE_CREDENTIALS`
   - Secret : collez le JSON copié précédemment
   - Cliquez sur **"Add secret"**

---

### **Tâche 2 : Modifier et exécuter le workflow GitHub**

1. **Ouvrez le fichier de workflow** :
   - Dans votre dépôt GitHub, allez dans **Code**
   - Ouvrez le fichier : `.github/workflows/eshoponweb-cicd.yml`

2. **Décommentez la section `on`** :
   - Supprimez les `#` au début des lignes de la section `on`
   - Cette section définit les déclencheurs du workflow

3. **Modifiez la section `env`** :
   - `RESOURCE-GROUP` : utilisez le même nom que votre groupe de ressources
   - `LOCATION` : choisissez votre région Azure (ex: "francecentral", "westeurope")
   - `SUBSCRIPTION-ID` : votre ID d'abonnement Azure
   - `WEBAPP-NAME` : un nom unique pour votre application web

   **Exemple** :
   ```yaml
   env:
     RESOURCE-GROUP: 'rg-eshoponweb-alice'
     LOCATION: 'francecentral'
     SUBSCRIPTION-ID: '12345678-1234-1234-1234-123456789012'
     WEBAPP-NAME: 'eshoponweb-alice-123'
   ```

4. **Sauvegardez les changements** :
   - Cliquez sur **"Commit changes..."**
   - Laissez les valeurs par défaut
   - Cliquez sur **"Commit changes"**

5. **Le workflow démarre automatiquement** !

---

### **Tâche 3 : Examiner l'exécution du workflow**

1. **Surveillez l'exécution** :
   - Allez dans l'onglet **"Actions"** de votre dépôt
   - Cliquez sur l'exécution en cours

2. **Analysez les résultats** :
   - Observez les deux jobs : `buildandtest` et `deploy`
   - Cliquez sur chaque job pour voir les logs détaillés
   - Attendez la fin du workflow (✓ vert)

3. **Vérifiez le déploiement Azure** :
   - Retournez sur le **Portail Azure**
   - Ouvrez votre groupe de ressources
   - Vous devriez voir :
     - Un **App Service Plan**
     - Une **Web App**
   - Cliquez sur la Web App → **"Browse"** (Parcourir) pour voir le site déployé

---

### **Tâche 4 (OPTIONNELLE) : Ajouter une approbation manuelle avec GitHub Environments**

1. **Ouvrez à nouveau le fichier de workflow** :
   - `.github/workflows/eshoponweb-cicd.yml`
   - Notez la référence à l'environnement `Development` dans le job `deploy`

2. **Créez un environnement GitHub** :
   - Allez dans **Settings** → **Environments**
   - Cliquez sur **"New environment"**
   - Nom : `Development`
   - Cliquez sur **"Configure Environment"**

3. **Configurez les règles de protection** :
   - Cochez **"Required Reviewers"** (Relecteurs requis)
   - Sélectionnez votre compte GitHub comme relecteur
   - Cliquez sur **"Save protection rules"**

4. **Testez l'approbation manuelle** :
   - Allez dans **Actions**
   - Cliquez sur **"Run workflow"** → **"Run workflow"**
   - Surveillez l'exécution
   - Quand le job `deploy` arrive, **une approbation est requise**
   - Cliquez sur **"Review deployments"**
   - Sélectionnez `Development` → **"Approve and deploy"**

---

## **Nettoyage**

**[!IMPORTANT] N'oubliez pas de supprimer les ressources Azure pour éviter des frais inutiles :**

1. Dans le Portail Azure, allez dans votre groupe de ressources
2. Cliquez sur **"Delete resource group"** (Supprimer le groupe de ressources)
3. Confirmez la suppression

---

## **Questions de révision**

1. Quels sont les principaux composants d'un workflow GitHub Actions ?
2. Comment sécurise-t-on les credentials Azure dans GitHub Actions ?
3. Quels sont les avantages d'utiliser des environnements GitHub ?
4. Quelle est la différence entre les déclencheurs `push` et `workflow_dispatch` ?

---

**Félicitations !** Vous avez implémenté avec succès un pipeline CI/CD avec GitHub Actions pour déployer une application web Azure.
