pipeline {
  agent any

  options {
    skipDefaultCheckout(true)
    disableConcurrentBuilds()
    timeout(time: 45, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  environment {
    CI = 'true'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Check container tools') {
      steps {
        bat '"C:\\Users\\saiku\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe" version'
        bat 'C:\\ProgramData\\Trivy\\trivy.exe --version'
      }
    }

    stage('Install dependencies') {
      steps {
        bat 'npm.cmd ci'
      }
    }

    stage('Lint and formatting') {
      steps {
        bat 'npm.cmd run lint-check'
      }
    }

    stage('Unit tests') {
      steps {
        bat 'npm.cmd test'
      }
    }

    stage('Browser tests') {
      environment {
        PORT = '8081'
        BASE_URL = 'http://localhost:8081'
      }
      steps {
        bat 'npm.cmd run test:e2e:replay'
      }
    }

    stage('Build container image') {
      steps {
        bat '"C:\\Users\\saiku\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe" build --tag hackathon-starter:%BUILD_NUMBER% .'
      }
    }

    stage('Trivy vulnerability scan') {
      steps {
        bat 'if not exist tmp mkdir tmp'
        bat 'C:\\ProgramData\\Trivy\\trivy.exe image --scanners vuln --format json --output tmp/trivy-report.json hackathon-starter:%BUILD_NUMBER%'
        bat 'C:\\ProgramData\\Trivy\\trivy.exe convert --scanners vuln --format table --severity HIGH,CRITICAL --exit-code 1 tmp/trivy-report.json'
      }
    }

    stage('Publish image to GHCR') {
      steps {
        script {
          env.IMAGE_TAG = bat(
            script: '@git rev-parse --short=12 HEAD',
            returnStdout: true
          ).trim()

          withCredentials([
            usernamePassword(
              credentialsId: 'ghcr-push',
              usernameVariable: 'GHCR_USERNAME',
              passwordVariable: 'GHCR_TOKEN'
            )
          ]) {
            try {
              bat '''
@echo off
echo %GHCR_TOKEN% | "C:\\Users\\saiku\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe" login ghcr.io --username %GHCR_USERNAME% --password-stdin
if errorlevel 1 exit /b %ERRORLEVEL%

"C:\\Users\\saiku\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe" tag hackathon-starter:%BUILD_NUMBER% ghcr.io/saikumarkandlagunta/hackathon-starter:%IMAGE_TAG%
if errorlevel 1 exit /b %ERRORLEVEL%

"C:\\Users\\saiku\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe" push ghcr.io/saikumarkandlagunta/hackathon-starter:%IMAGE_TAG%
if errorlevel 1 exit /b %ERRORLEVEL%
'''
            } finally {
              bat '"C:\\Users\\saiku\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe" logout ghcr.io'
            }
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'tmp/**', allowEmptyArchive: true
    }
  }
}
