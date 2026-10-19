
pipeline {
    agent any

    tools {
        nodejs 'NodeJS-22'
    }

    options {
        timestamps()
        timeout(time: 20, unit: 'MINUTES')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Tests') {
            steps {
                sh 'npm test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'

                    withSonarQubeEnv('SonarQube-Local') {
                        sh """
                            "${scannerHome}/bin/sonar-scanner"
                        """
                    }
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

        stage('Trivy Security Scan') {
            steps {
                sh '''
                    trivy fs \
                      --server http://trivy:4954 \
                      --scanners vuln \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      --format json \
                      --output trivy-report.json \
                      .
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.json',
                                     allowEmptyArchive: true
                }
            }
        }
	        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eu

                    echo "Construyendo imagen con BuildKit..."

                    buildctl --addr tcp://buildkit:1234 build \
                      --frontend dockerfile.v0 \
                      --local context=. \
                      --local dockerfile=. \
                      --opt filename=Dockerfile \
                      --output type=docker,name=app-demo:ci,dest=app-demo-ci.tar

                    echo "Imagen construida correctamente"
                    ls -lh app-demo-ci.tar
                '''
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    set -eu

                    echo "Analizando imagen Docker con Trivy..."

                    trivy image \
                      --input app-demo-ci.tar \
                      --scanners vuln \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      --format json \
                      --output trivy-image-report.json

                    echo "Imagen aprobada: sin vulnerabilidades HIGH ni CRITICAL"
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-image-report.json',
                                     allowEmptyArchive: true
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completado correctamente'
        }

        failure {
            echo 'Pipeline fallido: revisar logs'
        }
    }
}

