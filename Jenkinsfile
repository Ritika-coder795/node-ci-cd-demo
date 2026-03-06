pipeline {
    agent any

    tools {
        nodejs 'node'  // Ensure Node.js is installed in Jenkins global tools
    }

    environment {
        DOCKER_IMAGE = "mritika/node-ci-cd-demo"
        DOCKER_TAG = "latest"
        SONAR_URL = "http://107.20.60.100:9000"   // Fixed URL
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
                sh 'npm test -- --coverage' // Generate coverage for Sonar
            }
        }

        stage('Trivy File System Scan') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    sh '''
                    docker run --rm -v $PWD:/project -w /project aquasec/trivy:latest fs --severity HIGH,CRITICAL --exit-code 1 .
                    '''
                }
            }
        }

        stage('Sonar Scan') {
            steps {
                withCredentials([string(credentialsId: 'Sonar_Tken', variable: 'SONAR_TOKEN')]) {
                    sh """
                    docker run --rm \
                      -e SONAR_HOST_URL="$SONAR_URL" \
                      -e SONAR_LOGIN="$SONAR_TOKEN" \
                      -v \$(pwd):/usr/src \
                      sonarsource/sonar-scanner-cli \
                      -Dsonar.projectKey=node-ci-cd-demo \
                      -Dsonar.sources=. \
                      -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    sh 'docker build -t $DOCKER_IMAGE:$DOCKER_TAG .'
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    sh '''
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --exit-code 1 $DOCKER_IMAGE:$DOCKER_TAG
                    '''
                }
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
                timeout(time: 5, unit: 'MINUTES') {
                    sh 'docker push $DOCKER_IMAGE:$DOCKER_TAG'
                }
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
        always {
            sh 'docker image prune -f || true'
        }
    }
}
