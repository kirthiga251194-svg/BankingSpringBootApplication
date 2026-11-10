
node {

    // Configure Docker PATH for Jenkins
    env.PATH = "/usr/local/bin:${env.PATH}"

    // Project configuration
    env.IMAGE_NAME = "bankingapp"
    env.CONTAINER_NAME = "bankingapp"
    env.HTTP_PORT = "8989"
    env.IMAGE_TAG = "${env.BUILD_NUMBER}"

    // Stage 1: Prepare Environment
    stage('Prepare Environment') {

        echo 'Initializing Environment'

        sh '''
            echo "Checking environment..."
            java -version
            docker --version
        '''
    }

    // Stage 2: Code Checkout
    stage('Code Checkout') {

        echo 'Checking out source code from GitHub'

        try {
            checkout scm
        }
        catch (Exception e) {
            echo "Exception occurred during Git Checkout: ${e}"
            currentBuild.result = "FAILURE"
            throw e
        }
    }

    // Stage 3: Maven Build
   

stage('Maven Build') {

    echo 'Building Spring Boot application using Java 11'

    sh '''
        set -e

        # Explicitly select Java 11
        export JAVA_HOME=$(/usr/libexec/java_home -v 11)
        export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:$PATH"

        echo "========== VERIFY JAVA =========="
        echo "JAVA_HOME=$JAVA_HOME"
        java -version

        echo "========== VERIFY MAVEN =========="
        mvn -version

        echo "========== BUILD APPLICATION =========="
        mvn -B clean package -DskipTests

        echo "========== BUILD COMPLETED =========="
    '''
}
    // Stage 4: Docker Image Build

 stage('Docker Image Build') {   
  sh '''
    docker build \
        --platform linux/amd64 \
        -t $IMAGE_NAME:$IMAGE_TAG \
        --pull \
        --no-cache .
 '''
      
    }

    // Stage 5: Publish Image to Docker Hub
    stage('Publishing Image to DockerHub') {

        echo 'Pushing Docker image to Docker Hub'

        withCredentials([
            usernamePassword(
                credentialsId: 'dockerHubAccount',
                usernameVariable: 'DOCKERHUB_USER',
                passwordVariable: 'DOCKERHUB_PASSWORD'
            )
        ]) {

            sh '''
                echo "$DOCKERHUB_PASSWORD" | docker login \
                    --username "$DOCKERHUB_USER" \
                    --password-stdin

                docker tag \
                    $IMAGE_NAME:$IMAGE_TAG \
                    $DOCKERHUB_USER/$IMAGE_NAME:$IMAGE_TAG

                docker push $DOCKERHUB_USER/$IMAGE_NAME:$IMAGE_TAG

                echo "Image push completed"

                docker logout
            '''
        }
    }

    // Stage 6: Ansible Playbook Execution
    stage('Ansible Playbook Execution') {

        echo 'Deploying application using Ansible'

        withCredentials([
            usernamePassword(
                credentialsId: 'dockerHubAccount',
                usernameVariable: 'DOCKERHUB_USER',
                passwordVariable: 'DOCKERHUB_PASSWORD'
            )
        ]) {

            sh '''
                export ANSIBLE_HOST_KEY_CHECKING=False

                test -f inventory.yaml
                test -f containerDeploy.yaml
                test -f /var/lib/jenkins/server.pem

                ansible-playbook \
                    -i inventory.yaml \
                    containerDeploy.yaml \
                    -e "httpPort=$HTTP_PORT" \
                    -e "containerName=$CONTAINER_NAME" \
                    -e "dockerImageTag=$DOCKERHUB_USER/$IMAGE_NAME:$IMAGE_TAG" \
                    -e "key_pair_path=/var/lib/jenkins/server.pem" \
                    --become
            '''
        }
    }

    echo 'BankPro CI/CD Pipeline Completed Successfully!'
}
