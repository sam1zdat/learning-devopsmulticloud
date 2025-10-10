# TP : Jenkins Multi-Branch Pipeline - Simulation et Configuration

## Objectifs du TP
- Comprendre le concept de Multi-Branch Pipeline
- Configurer un pipeline multi-branches sans installation
- Analyser les stratégies de gestion par branche
- Évaluer les avantages pour le CI/CD

---

## Partie 1 : Théorie et Concepts (45 minutes)

### Exercice 1.1 : Compréhension du Multi-Branch Pipeline
**Durée** : 20 minutes

**Questions** :
1. Expliquez en quoi le Multi-Branch Pipeline diffère d'un pipeline standard
2. Listez 3 avantages principaux de cette approche
3. Décrivez le processus de découverte automatique des branches

### Exercice 1.2 : Cas d'usage
**Durée** : 25 minutes

**Scénario** : Une équipe de 5 développeurs travaille sur un projet avec :
- 1 branche main
- 1 branche develop  
- 3 branches feature
- 2 branches hotfix

**Travail** :
- Proposez une stratégie de pipeline pour chaque type de branche
- Identifiez les étapes communes et spécifiques

---

## Partie 2 : Conception de Jenkinsfile (2 heures)

### Exercice 2.1 : Structure de base Multi-Branch
**Durée** : 45 minutes

**Objectif** : Créer un Jenkinsfile de base compatible multi-branches

```groovy
// Jenkinsfile à créer
pipeline {
    agent any
    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }
    
    parameters {
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Exécuter les tests')
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'staging', 'prod'], description: 'Environnement de déploiement')
    }
    
    stages {
        stage('Initialisation') {
            steps {
                script {
                    echo "Branche: ${env.BRANCH_NAME}"
                    echo "URL du dépôt: ${env.GIT_URL}"
                    echo "Commit: ${env.GIT_COMMIT}"
                }
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        // À COMPLÉTER - Exercice 2.2
    }
    
    post {
        always {
            echo "Pipeline terminé pour la branche: ${env.BRANCH_NAME}"
        }
        success {
            emailext (
                subject: "SUCCESS: Pipeline ${env.JOB_NAME} - ${env.BRANCH_NAME}",
                body: "Build ${env.BUILD_URL} réussi",
                to: 'devops@company.com'
            )
        }
        failure {
            emailext (
                subject: "FAILED: Pipeline ${env.JOB_NAME} - ${env.BRANCH_NAME}", 
                body: "Build ${env.BUILD_URL} échoué",
                to: 'devops@company.com'
            )
        }
    }
}
```

### Exercice 2.2 : Stratégies conditionnelles par branche
**Durée** : 45 minutes

**Objectif** : Ajouter des étapes conditionnelles selon le type de branche

```groovy
// À intégrer dans le Jenkinsfile précédent
stages {
    // ... étapes précédentes ...
    
    stage('Build') {
        steps {
            script {
                echo "Construction en cours..."
                // Simulation build
                sh 'echo "Building application..."'
                
                if (env.BRANCH_NAME == 'main') {
                    echo "Build de production avec optimisation"
                    sh 'echo "mvn clean package -Pproduction -DskipTests"'
                } else if (env.BRANCH_NAME == 'develop') {
                    echo "Build de développement"
                    sh 'echo "mvn clean package -Pdevelopment -DskipTests"'
                } else {
                    echo "Build standard"
                    sh 'echo "mvn clean compile -DskipTests"'
                }
            }
        }
    }
    
    stage('Tests Unitaires') {
        when {
            expression { 
                return params.RUN_TESTS && 
                !env.BRANCH_NAME.startsWith('hotfix/')
            }
        }
        steps {
            script {
                echo "Exécution des tests unitaires"
                sh 'echo "mvn test"'
                // Simulation résultats
                sh 'echo "Tests unitaires: 85% de couverture"'
            }
        }
        post {
            always {
                junit '**/target/surefire-reports/*.xml'
            }
        }
    }
    
    stage('Tests d\'Intégration') {
        when {
            anyOf {
                branch 'main'
                branch 'develop'
                expression { env.BRANCH_NAME.startsWith('release/') }
            }
        }
        steps {
            script {
                echo "Exécution des tests d'intégration"
                sh 'echo "mvn verify -Pintegration-tests"'
            }
        }
    }
    
    stage('Analyse de Code') {
        when {
            not { branch 'main' }
        }
        steps {
            script {
                echo "Analyse de qualité de code"
                sh 'echo "sonar-scanner -Dsonar.projectVersion=${env.BRANCH_NAME}"'
            }
        }
    }
    
    stage('Déploiement') {
        when {
            anyOf {
                branch 'main'
                branch 'develop'
                expression { env.BRANCH_NAME.startsWith('release/') }
            }
        }
        steps {
            script {
                def environment = 'dev'
                if (env.BRANCH_NAME == 'main') {
                    environment = 'prod'
                } else if (env.BRANCH_NAME == 'develop') {
                    environment = 'staging'
                }
                
                echo "Déploiement vers l'environnement: ${environment}"
                sh "echo 'docker build -t myapp:${env.BRANCH_NAME} .'"
                sh "echo 'kubectl set image deployment/myapp myapp=myapp:${env.BRANCH_NAME}'"
            }
        }
    }
}
```

### Exercice 2.3 : Pipeline parallèle avancé
**Durée** : 30 minutes

**Objectif** : Optimiser les performances avec l'exécution parallèle

```groovy
// Remplacer les stages de tests par cette version parallèle
stage('Quality Gates') {
    when {
        expression { params.RUN_TESTS }
    }
    parallel {
        stage('Tests Unitaires') {
            steps {
                script {
                    echo "Tests unitaires en cours..."
                    sh 'echo "mvn test -Dtest=UnitTest*"'
                    // Simulation timing différent selon la branche
                    if (env.BRANCH_NAME == 'main') {
                        sh 'sleep 30'  // Tests plus complets
                    } else {
                        sh 'sleep 10'  // Tests rapides
                    }
                }
            }
        }
        
        stage('Tests d\'Intégration') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    echo "Tests d'intégration en cours..."
                    sh 'echo "mvn test -Dtest=IntegrationTest*"'
                    sh 'sleep 20'
                }
            }
        }
        
        stage('Analyse Statique') {
            when {
                not { branch 'main' }
            }
            steps {
                script {
                    echo "Analyse statique du code..."
                    sh 'echo "mvn checkstyle:checkstyle"'
                    sh 'echo "mvn pmd:pmd"'
                    sh 'sleep 15'
                }
            }
        }
    }
    
    post {
        always {
            // Consolidation des rapports
            junit '**/target/surefire-reports/*.xml'
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: false,
                keepAll: true,
                reportDir: 'target/site',
                reportFiles: 'checkstyle.html,pmd.html',
                reportName: 'Code Analysis Report'
            ])
        }
    }
}
```

---

## Partie 3 : Stratégies de Gestion (1 heure)

### Exercice 3.1 : Configuration de la découverte
**Durée** : 30 minutes

**Objectif** : Définir les règles de découverte des branches

```groovy
// jenkinsfile avec propriétés de découverte
def properties {
    [
        pipelineTriggers([
            [
                $class: 'SCMTrigger',
                scmpoll_spec: 'H/5 * * * *'
            ]
        ]),
        
        // Stratégie de découverte des branches
        [
            $class: 'BranchDiscoveryTrait',
            strategyId: '3'
        ],
        
        // Filtrage des branches
        [
            $class: 'RegexFilterTrait',
            regex: '(main|develop|feature/.*|release/.*|hotfix/.*)'
        ],
        
        // Stratégie de suppression des branches
        [
            $class: 'PruneStaleBranchTrait',
            daysToKeep: '3',
            numToKeep: '5'
        ]
    ]
}

pipeline {
    // ... configuration existante ...
    
    triggers {
        // Déclencheur par webhook
        bitbucketPush()
    }
    
    // Configuration spécifique par type de branche
    options {
        skipDefaultCheckout(false)
        
        // Rétention différente selon les branches
        buildDiscarder(
            logRotator(
                daysToKeepStr: env.BRANCH_NAME == 'main' ? '30' : '7',
                numToKeepStr: env.BRANCH_NAME == 'main' ? '50' : '10'
            )
        )
    }
}
```

### Exercice 3.2 : Gestion des notifications
**Durée** : 30 minutes

**Objectif** : Configurer des notifications adaptées à chaque branche

```groovy
// Ajouter dans la section post du pipeline
post {
    always {
        script {
            // Nettoyage des ressources
            sh 'echo "Nettoyage des ressources temporaires..."'
            
            // Rapport de statut
            def duration = currentBuild.durationString
            def summary = """
            📊 RAPPORT DE PIPELINE
            ======================
            Branche: ${env.BRANCH_NAME}
            Statut: ${currentBuild.currentResult}
            Durée: ${duration}
            URL: ${env.BUILD_URL}
            Commit: ${env.GIT_COMMIT.take(8)}
            """
            
            echo summary
        }
    }
    
    changed {
        script {
            // Notification seulement en cas de changement de statut
            if (currentBuild.currentResult == 'SUCCESS' && currentBuild.previousBuild?.result == 'FAILURE') {
                echo "✅ Pipeline restauré après échec"
            }
        }
    }
    
    success {
        script {
            def recipients = 'devops@company.com'
            
            // Personnalisation selon la branche
            switch(env.BRANCH_NAME) {
                case 'main':
                    recipients = 'devops@company.com,production-team@company.com'
                    break
                case 'develop':
                    recipients = 'devops@company.com,qa-team@company.com'
                    break
                default:
                    // Pour les branches feature, notifier seulement l'auteur
                    recipients = 'devops@company.com'
            }
            
            emailext (
                subject: "✅ SUCCÈS: ${env.JOB_NAME} [${env.BRANCH_NAME}] - Build #${env.BUILD_NUMBER}",
                body: """
                Le pipeline s'est terminé avec succès!
                
                Détails:
                - Branche: ${env.BRANCH_NAME}
                - Commit: ${env.GIT_COMMIT}
                - Durée: ${currentBuild.durationString}
                - Console: ${env.BUILD_URL}
                
                Bonne continuation!
                """,
                to: recipients
            )
        }
    }
    
    failure {
        script {
            def recipients = 'devops@company.com,oncall-team@company.com'
            
            // Notification urgente pour la branche main
            if (env.BRANCH_NAME == 'main') {
                recipients = 'devops@company.com,oncall-team@company.com,cto@company.com'
            }
            
            emailext (
                subject: "🚨 ÉCHEC: ${env.JOB_NAME} [${env.BRANCH_NAME}] - Build #${env.BUILD_NUMBER}",
                body: """
                Le pipeline a échoué et nécessite une attention immédiate!
                
                Détails:
                - Branche: ${env.BRANCH_NAME}
                - Commit: ${env.GIT_COMMIT}
                - Étape en échec: ${currentBuild.result}
                - Console: ${env.BUILD_URL}
                
                Action requise!
                """,
                to: recipients
            )
        }
    }
    
    unstable {
        // Gestion spécifique pour l'état unstable (tests qui échouent)
        script {
            echo "⚠️ Pipeline unstable - certains tests ont échoué"
            
            // Pour les branches de développement, on peut accepter l'unstable
            if (env.BRANCH_NAME != 'main') {
                echo "Accepté pour les branches de développement"
            }
        }
    }
}
```

---

## Partie 4 : Simulation et Analyse (1 heure 15 minutes)

### Exercice 4.1 : Scénarios de test
**Durée** : 45 minutes

**Objectif** : Simuler l'exécution sur différentes branches

**Scénario 1 : Branche Feature**
```
Branche: feature/nouvelle-fonctionnalite
Attendus:
- Build standard
- Tests unitaires
- Analyse de code
- Pas de déploiement
- Notification à l'équipe dev
```

**Scénario 2 : Branche Develop**
```
Branche: develop  
Attendus:
- Build développement
- Tests unitaires + intégration
- Déploiement staging
- Notification équipe QA
```

**Scénario 3 : Branche Main**
```
Branche: main
Attendus:
- Build production
- Tous les tests
- Déploiement production
- Notification équipe production
- Rétention longue des builds
```

**Travail** :
Pour chaque scénario, complétez le tableau :
| Étape | Configurée ? | Condition | Actions |
|-------|-------------|-----------|---------|
| Build | ✅ | Toujours | Adapté à la branche |
| Tests unitaires | ✅ | RUN_TESTS=true | ... |

### Exercice 4.2 : Analyse des avantages
**Durée** : 30 minutes

**Questions** :

1. **Efficacité** :
   - Combien de pipelines manuels seraient nécessaires sans Multi-Branch ?
   - Estimez le temps gagné sur la gestion des nouvelles branches

2. **Cohérence** :
   - Comment assurez-vous que toutes les branches suivent les mêmes standards ?
   - Quels mécanismes garantissent la qualité du code ?

3. **Flexibilité** :
   - Comment adaptez-vous le comportement sans dupliquer le Jenkinsfile ?
   - Quelles stratégies utilisez-vous pour les branches temporaires ?

4. **Maintenabilité** :
   - Comment gérez-vous l'évolution du Jenkinsfile sur toutes les branches ?
   - Quelle est votre stratégie pour les rétro-compatibilités ?

---

## Livrables attendus

### 1. Jenkinsfile complet
- Structure multi-branches fonctionnelle
- Stratégies conditionnelles par type de branche
- Gestion des notifications adaptée
- Configuration de la découverte

### 2. Documentation des stratégies
Tableau récapitulatif des comportements par branche :

| Type branche | Build | Tests | Analyse | Déploiement | Notification |
|-------------|-------|-------|---------|-------------|-------------|
| main | Production | Complets | ✅ | Production | Équipe prod |
| develop | Staging | Intégration | ✅ | Staging | Équipe QA |
| feature/.* | Standard | Unitaires | ✅ | ❌ | Auteur |
| hotfix/.* | Standard | Unitaires | ❌ | Staging | Urgent |

### 3. Analyse d'optimisation
- Identification des goulots d'étranglement
- Proposition d'améliorations de performance
- Stratégie de gestion des branches obsolètes

## Critères d'évaluation

- **Compréhension (30%)** : Maîtrise des concepts Multi-Branch Pipeline
- **Configuration (40%)** : Qualité du Jenkinsfile et des stratégies
- **Analyse (30%)** : Pertinence des scénarios et des optimisations

---

Ce TP permet de maîtriser les concepts des Multi-Branch Pipelines sans nécessiter d'installation Jenkins, en se concentrant sur la conception et la stratégie.
