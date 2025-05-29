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
        stage('TEST2: FAILING TESTS') {
            steps {
                script {
                    sh 'echo "==== TEST2: FAILING TESTS ===="'
                    def failingtestCommand = '''
                        sudo docker-compose exec -T gazebo bash -c '
                            set -e
                            source /opt/ros/galactic/setup.bash
                            source ~/ros2_ws/install/setup.bash
                            TEST_PASS=false colcon test --packages-select tortoisebot_waypoints --event-handler=console_direct+
                            colcon test-result --all
                        ' > failingtest_output.txt 2>&1
                    '''

                    def exitCode = sh(script: "${failingtestCommand}", returnStatus: true)

                    echo "===== TEST OUTPUT ====="
                    def testLog = readFile('failingtest_output.txt')
                    echo testLog

                    // Always archive the result
                    archiveArtifacts artifacts: 'failingtest_output.txt', allowEmptyArchive: true

                    // Optional: log a warning
                    if (exitCode != 0) {
                        echo "TEST2 failed with exit code ${exitCode} as expected"
                        echo "Continue the pipeline.."
                    }
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
