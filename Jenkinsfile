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
        bat 'C:\\ProgramData\\Trivy\\trivy.exe convert --format table --severity HIGH,CRITICAL --exit-code 1 tmp/trivy-report.json'
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'tmp/**', allowEmptyArchive: true
    }
  }
}
