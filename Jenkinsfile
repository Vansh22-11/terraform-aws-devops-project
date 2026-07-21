pipeline {

    agent {
        label 'dynamic-agent'
    }

    parameters {

    choice(
        name: 'DEPLOYMENT_MODE',
        choices: [
            'Update Infrastructure',
            'Destroy and Rebuild'
        ],
        description: 'Choose Terraform Deployment Mode'
    )

}

    environment {

        AWS_DEFAULT_REGION = 'eu-north-1'
        TF_IN_AUTOMATION   = 'true'

    }

    options {

        timestamps()
        ansiColor('xterm')

    }

    stages {

        stage('Checkout Source') {

            steps {

                echo "========== CHECKOUT SOURCE =========="
                checkout scm

            }

        }

        stage('Verify Tools') {

            steps {

                sh '''
                echo "========== VERIFY TOOL VERSIONS =========="

                echo ""
                echo "Terraform Version:"
                terraform version

                echo ""
                echo "AWS CLI Version:"
                aws --version

                echo ""
                echo "Git Version:"
                git --version

                echo ""
                echo "Java Version:"
                java -version

                echo ""
                echo "Current Directory:"
                pwd

                echo ""
                echo "Project Files:"
                ls -la
                '''

            }

        }

        stage('Terraform Init') {

            steps {

                echo "========== TERRAFORM INIT =========="

                sh '''
                terraform init -reconfigure
                '''

            }

        }

        stage('Terraform Destroy') {

            when {
                expression { params.DEPLOYMENT_MODE == 'Destroy and Rebuild' }
            }

            steps {

                echo "========== TERRAFORM DESTROY =========="

                sh '''
                terraform destroy -auto-approve
                '''

            }

        }

        stage('Terraform Validate') {

            steps {

                echo "========== TERRAFORM VALIDATE =========="

                sh '''
                terraform validate
                '''

            }

        }

        stage('Terraform Plan') {

            steps {

                echo "========== TERRAFORM PLAN =========="

                sh '''
                terraform plan -out=tfplan
                '''

            }

        }

        stage('Terraform Apply') {

            steps {

                echo "========== TERRAFORM APPLY =========="

                sh '''
                terraform apply -auto-approve tfplan
                '''

            }

        }

        stage('Terraform Outputs') {

            steps {

                echo "========== TERRAFORM OUTPUT =========="

                sh '''
                terraform output
                '''

            }

        }

        stage('Architecture Summary') {

            steps {

                echo "========== AWS TERRAFORM ARCHITECTURE =========="

                sh '''
                echo ""
                echo "=============================================="
                echo "          AWS TERRAFORM ARCHITECTURE"
                echo "=============================================="

                echo ""
                echo "VPC ID"
                terraform output -raw vpc_id

                echo ""
                echo "Public Subnet ID"
                terraform output -raw public_subnet_id

                echo ""
                echo "Private Subnet ID"
                terraform output -raw private_subnet_id

                echo ""
                echo "Security Group ID"
                terraform output -raw security_group_id

                echo ""
                echo "IAM Instance Profile"
                terraform output -raw instance_profile_name

                echo ""
                echo "EC2 Instance ID"
                terraform output -raw ec2_instance_id

                echo ""
                echo "EC2 Public IP"
                terraform output -raw ec2_public_ip

                echo ""
                echo "EC2 Private IP"
                terraform output -raw ec2_private_ip

                echo ""
                echo "S3 Backend Bucket"
                echo "terraform-state-vansh-2026"

                echo ""
                echo "Project Backup Bucket"
                echo "jenkins-backup-vansh-2026"

                echo ""
                echo "AWS Region"
                echo "$AWS_DEFAULT_REGION"

                echo ""
                echo "=============================================="
                echo "Infrastructure Successfully Provisioned"
                echo "=============================================="
                '''

            }

        }

        stage('Upload Project To S3') {

            steps {

                echo "========== UPLOADING PROJECT TO S3 =========="

                sh '''
                aws s3 cp . s3://jenkins-backup-vansh-2026/terraform-project/ \
                --recursive \
                --exclude ".git/*" \
                --exclude ".terraform/*"
                '''

            }

        }

    }

    post {

        always {

            echo "======================================"
            echo "Pipeline Finished"
            echo "======================================"

        }

        success {

            script {
                    if (params.DEPLOYMENT_MODE == 'Destroy and Rebuild') {

                        echo "Infrastructure Destroyed Successfully"
                        echo "Infrastructure Recreated Successfully"

                    } else {

                        echo "Infrastructure Updated Successfully"

                    }
                       echo "Project Uploaded To S3 Successfully"
 
                    }

                echo "Dynamic Agent Will Be Automatically Terminated By Jenkins EC2 Plugin"

                }

        failure {

            echo "Pipeline Failed"

        }

    }

}