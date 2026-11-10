
node {

    // Application configuration
    def tag = '3.0'
    def dockerHubUser = ''
    def containerName = 'bankingapp'
    def httpPort = '8989'
    def imageName = ''

    // Make Homebrew tools available to Jenkins
    env.PATH = "/opt/homebrew/bin:/usr/local/bin:${env.PATH ?: ''}"

    // Stage 1: Prepare Environment
    stage('Prepare Environment') {

        echo 'Initializing Environment'

        withCredentials([usernamePassword(
            credentialsId: 'dockerHubAccount',
            usernameVariable: 'DOCKERHUB_USER',
            passwordVariable: 'DOCKERHUB_PASSWORD'
        )]) {
            dockerHubUser = env.DOCKERHUB_USER
        }

        imageName = "${dockerHubUser}/${containerName}:${tag}"

        env.IMAGE_NAME = imageName
        env.CONTAINER_NAME = containerName
        env.HTTP_PORT = httpPort

        echo "Docker image: ${imageName}"
    }

    // Stage 2: Code Checkout
    stage('Code Checkout') {

        echo 'Checking out source code from GitHub'

        checkout scm

        echo 'GitHub checkout completed'
    }

// Stage 3: Maven Build
stage('Maven Build') {

    echo 'Building Spring Boot application using Java 11'

    sh '''
        set -e

        export JAVA_HOME=$(/usr/libexec/java_home -v 11)
        export PATH="$JAVA_HOME/bin:/opt/homebrew/bin:/usr/bin:/bin"

        echo "========== JAVA VERSION =========="
        which java
        java -version

        echo "========== MAVEN VERSION =========="
        /opt/homebrew/bin/mvn -version

        echo "========== MAVEN BUILD =========="
        /opt/homebrew/bin/mvn -B clean package -DskipTests

        echo "========== BUILD SUCCESSFUL =========="
    '''
}

   
// Stage 4: Docker Image Build
stage('Docker Image Build') {

    echo 'Creating Docker image'

    sh '''
        docker build \
            --pull \
            --no-cache \
            -t kirthigaravi/bankingapp:3.0 .
    '''

    echo 'Docker image build completed'
}


// Stage 5: Publishing Image to DockerHub
stage('Publishing Image to DockerHub') {

    withCredentials([
        usernamePassword(
            credentialsId: 'dockerHubAccount',
            usernameVariable: 'DOCKERHUB_USER',
            passwordVariable: 'DOCKERHUB_PASSWORD'
        )
    ]) {

        sh '''
            echo "$DOCKERHUB_PASSWORD" | docker login \
                -u "$DOCKERHUB_USER" \
                --password-stdin

            docker push kirthigaravi/bankingapp:3.0

            docker logout
        '''
    }
}


    // Stage 6: Ansible Deployment to AWS EC2
    stage('Ansible Playbook Execution') {

        echo 'Deploying application to AWS EC2 using Ansible'

        withCredentials([sshUserPrivateKey(
            credentialsId: 'aws-ec2-ssh',
            keyFileVariable: 'EC2_SSH_KEY',
            usernameVariable: 'EC2_SSH_USER'
        )]) {

            sh '''
                set -e

                export ANSIBLE_HOST_KEY_CHECKING=False

                ansible-playbook \
                    -i inventory.yaml \
                    containerDeploy.yaml \
                    --private-key "$EC2_SSH_KEY" \
                    -u "$EC2_SSH_USER" \
                    -e "httpPort=$HTTP_PORT" \
                    -e "containerName=$CONTAINER_NAME" \
                    -e "dockerImageTag=$IMAGE_NAME"
            '''
        }

        echo 'AWS EC2 deployment completed'
    }
}
   
