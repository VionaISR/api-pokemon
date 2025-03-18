pipeline {
    environment {
        registry = "vionaray/pokemon"
        gitUrl = 'https://labgit.mypoc.id:4443/devops/api-pikachu.git'
        gitBranch = 'development'
        registryCredential = 'dockerhub'
        apiDeployUrl = "http://10.111.13.27:8085/api/pokemon" 
        telegramChatId = "1102115298"
    }
    agent any

    stages {
        stage('Cloning Repo') {
            steps {
                script {
                    FAILED_STAGE = env.STAGE_NAME
                }
                sh "rm -rf *"
                git branch: gitBranch,
                    credentialsId: 'gitlab',
                    url: gitUrl
                script {
                    env.GIT_COMMIT_MSG = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
                }
            }
        }

        stage('Building Docker Image') {
            steps {
                script {
                    FAILED_STAGE = env.STAGE_NAME
                    dockerImages = docker.build("${registry}:${BUILD_NUMBER}", "-f Dockerfile .")
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                script {
                    FAILED_STAGE = env.STAGE_NAME
                    docker.withRegistry('', registryCredential) {
                        dockerImages.push()
                    }
                }
            }
        }

        stage('Deploy to Server') {
            steps {
                script {
                    FAILED_STAGE = env.STAGE_NAME
                }

                withCredentials([
                    sshUserPrivateKey(credentialsId: 'jenkins-ssh-key', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER'),
                    string(credentialsId: 'jenkins-server-host', variable: 'SSH_HOST'),
                    string(credentialsId: 'jenkins-server-path', variable: 'SSH_PATH')
                ]) {
                    sh "sed -i 's|latest|${BUILD_NUMBER}|g' docker-compose.yml"
                    sh '''
                        chmod 600 $SSH_KEY_FILE
                        scp -i $SSH_KEY_FILE -P 222 docker-compose.yml $SSH_USER@$SSH_HOST:$SSH_PATH
                    '''

                    sh '''
                        ssh -i $SSH_KEY_FILE $SSH_USER@$SSH_HOST -p 222 << EOF
                        cd $SSH_PATH
                        docker-compose down
                        docker-compose pull
                        docker-compose up -d
                        << EOF
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                FAILED_STAGE = FAILED_STAGE ?: 'Unknown'
                def message = "Jenkins Build: ${currentBuild.fullDisplayName}\nStatus: ${currentBuild.currentResult}\nStage: ${FAILED_STAGE}"

                withCredentials([string(credentialsId: 'telegram-bot-token', variable: 'TELEGRAM_TOKEN')]) {
                    sh """
                        curl -s -X POST https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage \
                        -d chat_id=${telegramChatId} \
                        -d text="${message}"
                    """
                }
            }
        }
    }
}
