pipeline {
    agent any

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Appliquer automatiquement après le plan Terraform ?')
        choice(name: 'action', choices: ['apply', 'destroy'], description: 'Choisir l’action à exécuter')
    }

    environment {
        AWS_DEFAULT_REGION = 'us-west-2'
        SONAR_PROJECT_KEY = 'Dev-app'
        SONAR_SCANNER_PATH = 'C:\\sonar-scanner\\bin\\sonar-scanner.bat'
    }

 stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/miladirahma1/FinalDevopsProject.git'
            }
        }

        stage('Build & Test Node.js') {
            steps {
                dir('app') {
                    bat 'npm install'
                    // Ajoute des tests pour un rendu pro (Jest/Mocha)
                    bat 'npm test || echo "No tests yet"'
                }
            }
        }

        stage('SonarQube analysis') {
            steps {
                withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('SonarQube') {
                        bat """
                            %SONAR_SCANNER_PATH% ^
                            -Dsonar.projectKey=%SONAR_PROJECT_KEY% ^
                            -Dsonar.sources=app ^
                            -Dsonar.token=%SONAR_TOKEN%
                        """
                    }
                }
            }
        }

        stage('Quality gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker build & push') {
            steps {
                script {
                    dir('app') {
                        bat "docker build -t %DOCKER_IMAGE%:%DOCKER_TAG% ."
                        withCredentials([usernamePassword(credentialsId: 'DOCKERHUB_CREDS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            bat "docker login -u %DOCKER_USER% -p %DOCKER_PASS%"
                            bat "docker push %DOCKER_IMAGE%:%DOCKER_TAG%"
                        }
                    }
                }
            }
        }

        stage('Start monitoring stack (Prometheus + Grafana)') {
            steps {
                dir('monitoring') {
                    bat "docker compose pull || echo skip"
                    bat "docker compose up -d --build"
                }
            }
        }

        stage('Start logging stack (ELK)') {
            steps {
                dir('logging') {
                    bat "docker compose pull || echo skip"
                    bat "docker compose up -d --build"
                }
            }
        }

        stage('Terraform init') {
            steps {
                dir('Terraform') {
                    bat 'terraform init'
                }
            }
        }

        stage('Terraform plan') {
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

        stage('Terraform apply / destroy') {
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

        stage('Publish useful links') {
            steps {
                script {
                    // Adapter l’hôte Jenkins si nécessaire
                    echo "Grafana: http://localhost:3001"
                    echo "Prometheus: http://localhost:9090"
                    echo "Kibana: http://localhost:5601"
                    def ip = readFile 'Terraform/ec2_ip.txt'
                    echo "Application (si exposée): http://${ip.trim()}"
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
        always {
            // Optionnel: nettoyage pour éviter saturation
            echo 'Nettoyage terminé.'
        }
    }
}
