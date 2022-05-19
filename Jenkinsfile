pipeline {
  agent any
  stages {
    stage('Build') {
      steps {
        sh 'curl --proto \'=https\' --tlsv1.2 https://sh.rustup.rs -sSf -y | sh'
        sh 'cd circom && cargo build --release && cargo install --path circom'
      }
    }

    stage('Test') {
      steps {
        sh 'cd $HOME/workspace/ed25519-circom_gaurav-ci'
        sh '''npm run build --if-present
'''
        sh '''npm test
'''
        sh '''npm run test-scalarmul
'''
        sh '''npm run test-verify
'''
        sh '''npm run test-batch-verify
'''
        sh 'npm run lint'
      }
    }

  }
}