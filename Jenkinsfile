pipeline {
    agent any

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Appliquer automatiquement après le plan Terraform ?')
        choice(name: 'action', choices: ['apply', 'destroy'], description: 'Choisir l’action à exécuter')
    }

    environment {
        AWS_DEFAULT_REGION = 'us-west-2'
        SONAR_PROJECT_KEY = 'FinalDevopsProject'
        SONAR_SCANNER_PATH = 'C:\\sonar-scanner\\bin\\sonar-scanner.bat'
        SONAR_HOST_URL = 'http://localhost:9000'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/miladirh123/FinalDevopsProject.git'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('Terraform') {
                    bat 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('Terraform') {
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        bat """
                            terraform plan ^
                            -var="aws_access_key=%AWS_ACCESS_KEY_ID%" ^
                            -var="aws_secret_key=%AWS_SECRET_ACCESS_KEY%" ^
                            -out=tfplan
                        """
                        bat 'terraform show -no-color tfplan > tfplan.txt'
                    }
                }
            }
        }

        stage('Terraform Apply / Destroy') {
            steps {
                dir('Terraform') {
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        script {
                            if (params.action == 'apply') {
                                if (!params.autoApprove) {
                                    def plan = readFile 'tfplan.txt'
                                    input message: "Souhaitez-vous appliquer ce plan Terraform ?",
                                    parameters: [text(name: 'Plan', description: 'Veuillez examiner le plan Terraform', defaultValue: plan)]
                                }
                                bat 'terraform apply -input=false tfplan'
                            } else if (params.action == 'destroy') {
                                bat """
                                    terraform destroy ^
                                    -var="aws_access_key=%AWS_ACCESS_KEY_ID%" ^
                                    -var="aws_secret_key=%AWS_SECRET_ACCESS_KEY%" ^
                                    --auto-approve
                                """
                            } else {
                                error "Action invalide. Choisissez 'apply' ou 'destroy'."
                            }
                        }
                    }
                }
            }
        }

        stage('Afficher IP EC2') {
            steps {
                dir('Terraform') {
                    bat 'terraform output public_ip'
                }
            }
        }

        stage('Sauvegarder IP EC2') {
            steps {
                dir('Terraform') {
                    bat 'terraform output -raw public_ip > ec2_ip.txt'
                }
            }
        }

        // ----------------- SonarQube -----------------
        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    bat """
                        %SONAR_SCANNER_PATH% ^
                        -Dsonar.projectKey=%SONAR_PROJECT_KEY% ^
                        -Dsonar.sources=. ^
                        -Dsonar.host.url=%SONAR_HOST_URL% ^
                        -Dsonar.login=%SONAR_TOKEN%
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline exécuté avec succès !'
        }
        failure {
            echo '❌ Échec du pipeline. Vérifiez les logs.'
        }
    }
}
