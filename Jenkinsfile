pipeline {
  agent any
  stages {
    stage('Test') {
      steps {
        sh '''dir=`echo $JOB_NAME | sed \'s/\\//_/g\'`
cd /var/lib/jenkins/workspace/$dir
#docker build -t circomtest . 
#docker rmi circomtest:latest
#echo "Tested Successfully"
'''
      }
    }

    stage('postBuild') {
      steps {
        sh 'echo $BUILD_STATUS'
      }
    }

  }
}