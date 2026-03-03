pipeline {
    agent any

    tools {
        nodejs 'node'
    }

    environment {
        DOCKER_IMAGE = "mritika/node-ci-cd-demo"
        DOCKER_TAG = "latest"
        SONAR_URL = "http://172.31.16.70:9000"   // 🔁 Replace with your Sonar private IP
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: '5df4ccc9-6ad2-461c-8bb9-9532a0188a0d',
                    url: 'git@github.com:Ritika-coder795/node-ci-cd-demo.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'npm test'
            }
        }

        stage('Trivy File System Scan') {
            steps {
                sh 'trivy fs --severity HIGH,CRITICAL .'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                    sonar-scanner \
                      -Dsonar.projectKey=node-ci-cd-demo \
                      -Dsonar.sources=. \
                      -Dsonar.host.url=$SONAR_URL \
                      -Dsonar.login=$SONAR_TOKEN
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE:$DOCKER_TAG .'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL $DOCKER_IMAGE:$DOCKER_TAG'
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh 'docker push $DOCKER_IMAGE:$DOCKER_TAG'
            }
        }
    }

    post {
        success {
            echo 'Pipeline Successful 🚀'
        }
        failure {
            echo 'Pipeline Failed ❌'
        }
    }
}
