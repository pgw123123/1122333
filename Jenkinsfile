pipeline {
    agent any

    tools {
        maven "M3"
        jdk   "JDK21"
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-token')
        AWS_CREDENTIALS_NAME = credentials('project10')
        REGION = "ap-northeast-2"
        GIT_CREDENTIALS = credentials('git-key')
    }

    stages {
        stage('Git Clone') {
            steps {
                git url: 'https://github.com/pgw123123/spring-petclinic.git',
                    branch: 'main', 
                    credentialsId: 'git-key'
            }
        }

        stage('Maven Build') {
            steps {
                echo 'Maven Build'
                sh 'mvn -Dmaven.test.failure.ignore=true clean package'
            }
        }

        stage('Docker Image Build') {
            steps {
                echo 'Docker Image Build'
                dir("${env.WORKSPACE}") {
                    sh """
                    docker build -t spring-petclinic:$BUILD_NUMBER .
                    docker tag spring-petclinic:$BUILD_NUMBER gw9965/spring-petclinic:latest
                    """
                }
            }
        }

        stage('Docker Image Push') {
            steps {
                echo 'Docker Image Push'
                dir("${env.WORKSPACE}") {
                    sh """
                    echo \$DOCKERHUB_CREDENTIALS_PSW | docker login -u \$DOCKERHUB_CREDENTIALS_USR --password-stdin
                    docker push gw9965/spring-petclinic:latest
                    """
                }
            }
        }

        stage('Docker Image Remove') {
            steps {
                echo 'Docker Image Remove'
                dir("${env.WORKSPACE}") {
                    sh """
                    docker rmi gw9965/spring-petclinic:latest || true
                    docker rmi spring-petclinic:${BUILD_NUMBER} || true
                    """
                }
            }
        }

        stage('Upload S3') {
            steps {
                echo 'Upload S3'
                dir("${env.WORKSPACE}") {
                    sh 'zip -r script.zip ./script appspec.yml'
                    withAWS(region:"${REGION}", credentials: 'project10') {
                        s3Upload(file:"script.zip", bucket: "team4-codedeploy-project-bucket")
                    }
                    sh 'rm -rf script.zip'
                }
            }
        }

        stage('CodeDeploy Deployment') {
            steps {
                echo "Create Codedeploy group and deployment"
                withAWS(region:"${REGION}", credentials: 'project10') {
                    sh """
                    aws deploy create-deployment-group \
                    --application-name team4-codedeploy \
                    --auto-scaling-groups team4-asg \
                    --deployment-group-name team4-codedeploy-group \
                    --deployment-config-name CodeDeployDefault.OneAtATime \
                    --service-role-arn arn:aws:iam::491085389788:role/team4-jenkins-ssm-role || echo 'Deployment group already exists'
                    
                    aws deploy create-deployment \
                    --application-name team4-codedeploy \
                    --deployment-config-name CodeDeployDefault.OneAtATime \
                    --deployment-group-name team4-codedeploy-group \
                    --s3-location bucket=team4-codedeploy-project-bucket,bundleType=zip,key=script.zip
                    """
                }
                sleep(10)
            }
        }
    }
}
