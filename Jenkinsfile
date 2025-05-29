pipeline {
    agent any
    stages {
        stage('BUILD DOCKER CONTAINER') {
            steps {
                sh 'echo "==== BUILD DOCKER CONTAINER ===="'
                sh '''
                    cd ~/ros2_ws/src/ros2_ci
                    ls -ah
                '''
            }
        }
    }
    post {
        always {
            echo '==== PIPELINE COMPLETED ===="'
            // Optional: Send test results via email or other notification
        }
    }
}
