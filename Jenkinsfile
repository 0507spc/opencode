pipeline {
  agent { label 'miniserver' }

  environment {
    REGISTRY_URL  = 'nexus.server.cranie.com'
    REGISTRY_REPO = 'docker'
    REMOTE_REPO   = 'https://github.com/0507spc/opencode.git'
    CODE_NAME     = 'opencode'
  }

  triggers {
    pollSCM('H 2 * * *')
  }

  options {
    timestamps()
  }

  stages {

    stage('Clone Repo') {
      steps {
        dir("${CODE_NAME}") {
          git url: "${REMOTE_REPO}", branch: 'main'
        }
      }
    }

    stage('Prepare Tags') {
      steps {
        dir("${CODE_NAME}") {
          script {
            env.GIT_HASH = sh(
              returnStdout: true,
              script: 'git rev-parse --short HEAD'
            ).trim()

            env.FULL_TAG = "${env.GIT_HASH}-${env.BUILD_NUMBER}"
          }
        }
      }
    }

    stage('Build Images') {
      steps {
        dir("${CODE_NAME}") {
          sh '''
            TAG=${CODE_NAME}-${CODE_NAME}:${FULL_TAG} docker compose build --no-cache
          '''
        }
      }
    }

    stage('Login to Nexus') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'nexus-docker-creds',
          usernameVariable: 'NEXUS_USER',
          passwordVariable: 'NEXUS_PASS'
        )]) {
          sh '''
            echo "$NEXUS_PASS" | docker login ${REGISTRY_URL} -u "$NEXUS_USER" --password-stdin
          '''
        }
      }
    }

    stage('Push Images') {
      steps {
        dir("${CODE_NAME}") {
          sh '''
            docker tag ${CODE_NAME}-${CODE_NAME} ${REGISTRY_URL}/${REGISTRY_REPO}/${CODE_NAME}:${FULL_TAG}
            docker push ${REGISTRY_URL}/${REGISTRY_REPO}/${CODE_NAME}:${FULL_TAG}
          '''
        }
      }
    }

    stage('Tag Latest') {
      steps {
        sh '''
          docker tag ${REGISTRY_URL}/${REGISTRY_REPO}/${CODE_NAME}:${FULL_TAG} ${REGISTRY_URL}/${REGISTRY_REPO}/${CODE_NAME}:latest
          docker push ${REGISTRY_URL}/${REGISTRY_REPO}/${CODE_NAME}:latest
        '''
      }
    }


    stage('Deploy') {
        steps {
            // SSH command to deploy
            sh 'ssh nas "cd /volume2/docker/${CODE_NAME} ; sudo docker compose pull ; sudo docker compose up -d"'
        }
    }



  
  }


    post {
    always {
      sh 'docker logout ${REGISTRY_URL} || true'
    }
    success {
      withCredentials([
        string(credentialsId: 'Pushover', variable: 'PUSHOVER_TOKEN'),
        string(credentialsId: 'Pushover-User', variable: 'PUSHOVER_USER')
      ]) {
        sh '''
          curl -s \
            --form-string "token=${PUSHOVER_TOKEN}" \
            --form-string "user=${PUSHOVER_USER}" \
            --form-string "message=Build succeeded for ${CODE_NAME}" \
            https://api.pushover.net/1/messages.json
        '''
      }
    }
    failure {
      withCredentials([
        string(credentialsId: 'Pushover', variable: 'PUSHOVER_TOKEN'),
        string(credentialsId: 'Pushover-User', variable: 'PUSHOVER_USER')
      ]) {
        sh '''
          curl -s \
            --form-string "token=${PUSHOVER_TOKEN}" \
            --form-string "user=${PUSHOVER_USER}" \
            --form-string "message=Build failed for ${CODE_NAME}" \
            https://api.pushover.net/1/messages.json
        '''
      }
    }
  }
}
