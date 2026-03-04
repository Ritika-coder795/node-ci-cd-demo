
pipeline {
    agent any

    tools {
        nodejs 'node'  // Ensure Node.js is installed in Jenkins global tools
    }

    environment {
        DOCKER_IMAGE = "mritika/node-ci-cd-demo"
        DOCKER_TAG = "latest"
        SONAR_URL = "http://172.31.16.70:9000"   // Replace with your Sonar private IP
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
                timeout(time: 5, unit: 'MINUTES') {
                    // Fail build if HIGH/CRITICAL vulnerabilities found
                    sh '''
                    docker run --rm -v $PWD:/project -w /project aquasec/trivy:latest fs --severity HIGH,CRITICAL --exit-code 1 .
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'stage('SonarQube Analysis') {
    steps {
        withCredentials([string(credentialsId: 'sonar-node-ci-cd-demo', variable: 'SONAR_TOKEN')]) {
            sh '''
            docker run --rm \
              -e SONAR_HOST_URL="$SONAR_URL" \
              -e SONAR_LOGIN="$SONAR_TOKEN" \
              -v $(pwd):/usr/src \
              sonarsource/sonar-scanner-cli
            '''
        }
    }
}', variable: 'SONAR_TOKEN')]) {
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
                    // Fail build if HIGH/CRITICAL vulnerabilities found
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
            // Optional: clean up dangling Docker images to save space
            sh 'docker image prune -f || true'
        }
    }
}
