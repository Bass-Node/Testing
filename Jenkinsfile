pipeline {
  agent {
    docker { image 'localhost:5000/test_gss' }
  }

  stages{
    stage('Hello') {
      steps {
        echo "Hello from GitHub"
      }
    }
  }
}
