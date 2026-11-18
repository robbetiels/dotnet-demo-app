pipeline {
    agent any
    stages {
        stage('Build (staging)') {
            steps { sh 'docker build -t todoapp ./TodoApp' }
        }
        stage('Deploy (production)') {
            steps {
                withCredentials([string(credentialsId: 'todo-db-password', variable: 'DBPW')]) {
                    sshagent(['dmz010-deploy']) {
                        sh '''
                            docker save todoapp | ssh -o StrictHostKeyChecking=no vagrant@192.0.2.10 docker load
                            ssh -o StrictHostKeyChecking=no vagrant@192.0.2.10 "docker rm -f todoapp || true; docker run -d --restart always --name todoapp -p 127.0.0.1:8081:8080 -e ASPNETCORE_ENVIRONMENT=Development -e 'ConnectionStrings__TodoDb=Server=192.0.2.20;Port=3306;Database=appdb1;User=appuser1;Password=$DBPW;' todoapp"
                        '''
                    }
                }
            }
        }
    }
}
#change