pipeline {
    agent any
    stages {
        stage('BUILD DOCKER CONTAINER') {
            steps {
                sh 'echo "==== BUILD DOCKER CONTAINER ===="'
                sh '''
                    cd ~/ros2_ws/src/ros2_ci
                    sudo docker-compose build
                '''
            }
        }
        stage('START DOCKER CONTAINER') {
            steps {
                sh 'echo "==== START DOCKER CONTAINER ===="'
                sh 'sudo docker-compose up -d'
            }
        }
        stage('CHECK DOCKER CONTAINER') {
            steps {
                sh 'echo "==== CHECK DOCKER CONTAINER ===="'
                sh 'sudo docker-compose ps'
                echo 'Waiting for Gazebo to spin up...'
                sleep time: 10, unit: 'SECONDS'
            }
        }
        stage('TEST1: PASSING TESTS') {
            steps {
                script {
                    sh 'echo "==== TEST1: PASSING TESTS ===="'
                    def testCommand = '''
                        sudo docker-compose exec -T gazebo bash -c '
                            set -e
                            source /opt/ros/galactic/setup.bash
                            source ~/ros2_ws/install/setup.bash
                            colcon test --packages-select tortoisebot_waypoints --event-handler=console_direct+
                            colcon test-result --all
                        '
                    '''

                    // Run the command and capture both stdout and stderr
                    def testOutput = sh(script: "${testCommand}", returnStdout: true)

                    echo "===== TEST OUTPUT ====="
                    echo testOutput

                    writeFile file: 'passingtest_output.txt', text: testOutput
                    archiveArtifacts artifacts: 'passingtest_output.txt'
                }
            }
            post {
                always {
                    sh '''
                        if [ ! -s passingtest_output.txt ]; then
                            echo "Warning: Empty artifact"
                        fi
                    '''
                }
            }
        }
    }
    post {
        always {
            echo "==== CLEANUP DOCKER CONTAINER===="
            sh 'sudo docker-compose down'

            echo '==== PIPELINE COMPLETED ===='
            // Optional: Send test results via email or other notification
        }
    }
}
