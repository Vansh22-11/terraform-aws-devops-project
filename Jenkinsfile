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
        ANSIBLE_DIR = "ansible"
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
                echo "========== AWS INFRASTRUCTURE SUMMARY =========="

                sh '''
                echo ""
                echo "=============================================================="
                echo "                AWS TERRAFORM INFRASTRUCTURE"
                echo "=============================================================="

                echo ""
                echo "AWS ACCOUNT"
                aws sts get-caller-identity

                echo ""
                echo "--------------------------------------------------------------"
                echo "NETWORK"
                echo "--------------------------------------------------------------"

                echo "VPC ID              : $(terraform output -raw vpc_id)"
                echo "Public Subnet       : $(terraform output -raw public_subnet_id)"
                echo "Private Subnet      : $(terraform output -raw private_subnet_id)"
                echo "Security Group      : $(terraform output -raw security_group_id)"

                echo ""
                echo "--------------------------------------------------------------"
                echo "EC2 INSTANCE"
                echo "--------------------------------------------------------------"

                INSTANCE_ID=$(terraform output -raw ec2_instance_id)

                aws ec2 describe-instances \
                --instance-ids $INSTANCE_ID \
                --query 'Reservations[0].Instances[0].[
                    InstanceId,
                    InstanceType,
                    State.Name,
                    Placement.AvailabilityZone,
                    PublicIpAddress,
                    PrivateIpAddress,
                    KeyName,
                    PlatformDetails,
                    VpcId,
                    SubnetId,
                    ImageId
                ]' \
                --output table

                echo ""
                echo "--------------------------------------------------------------"
                echo "SECURITY GROUP RULES"
                echo "--------------------------------------------------------------"

                SG=$(terraform output -raw security_group_id)

                aws ec2 describe-security-groups \
                --group-ids $SG \
                --query 'SecurityGroups[0].IpPermissions[*].[FromPort,ToPort,IpProtocol,IpRanges[*].CidrIp]' \
                --output table

                echo ""
                echo "--------------------------------------------------------------"
                echo "IAM"
                echo "--------------------------------------------------------------"

                echo "Instance Profile : $(terraform output -raw instance_profile_name)"

                echo ""
                echo "--------------------------------------------------------------"
                echo "S3"
                echo "--------------------------------------------------------------"

                echo "Terraform Bucket : terraform-state-vansh-2026"
                echo "Backup Bucket    : jenkins-backup-vansh-2026"

                echo ""
                echo "--------------------------------------------------------------"
                echo "REGION"
                echo "--------------------------------------------------------------"

                echo "AWS Region : eu-north-1"

                echo ""
                echo "--------------------------------------------------------------"
                echo "TERRAFORM OUTPUTS"
                echo "--------------------------------------------------------------"

                terraform output

                echo ""
                echo "=============================================================="
                echo "Infrastructure Provisioned Successfully"
                echo "=============================================================="
                '''
            }
        }

        stage('Generate Ansible Inventory') {

            when {
                anyOf {
                expression { params.DEPLOYMENT_MODE == 'Update Infrastructure' }
                expression { params.DEPLOYMENT_MODE == 'Destroy and Rebuild' }
                }
            }

            steps {

                echo "========== GENERATE ANSIBLE INVENTORY =========="

                script {

                env.EC2_PUBLIC_IP = sh(
                    script: "terraform output -raw ec2_public_ip",
                    returnStdout: true
                ).trim()

                sh """
                cat > ansible/inventory/hosts <<EOF
                [terraform_servers]
                ${env.EC2_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/dynamic-agent-key-pair.pem
                EOF
                """

                echo "Inventory Created Successfully"
                echo "Target Host : ${env.EC2_PUBLIC_IP}"
                }
            }

        }

        stage('Display Inventory') {

            when {
                anyOf {
                    expression { params.DEPLOYMENT_MODE == 'Update Infrastructure' }
                    expression { params.DEPLOYMENT_MODE == 'Destroy and Rebuild' }
                }
            }

            steps {

                echo "========== INVENTORY =========="

                sh '''
                cat ansible/inventory/hosts
                '''
            }
        }

        stage('Run Ansible Playbook') {

            when {
                anyOf {
                    expression { params.DEPLOYMENT_MODE == 'Update Infrastructure' }
                    expression { params.DEPLOYMENT_MODE == 'Destroy and Rebuild' }
                }
            }

            steps {

                echo "========== RUNNING ANSIBLE =========="

                sh '''
                cd ansible

                pwd
                ls -la
                ls -R

                export ANSIBLE_CONFIG=$PWD/ansible.cfg

                ansible-config dump | grep ROLE

                ansible-playbook -i inventory/hosts playbooks/site.yml
                '''
            }
        }
        
        stage('Verify Java & Docker') {

            when {
                anyOf {
                    expression { params.DEPLOYMENT_MODE == 'Update Infrastructure' }
                    expression { params.DEPLOYMENT_MODE == 'Destroy and Rebuild' }
                }
            }

            steps {

                echo "========== VERIFYING SOFTWARE =========="

                sh '''
                cd ansible

                ansible -i inventory/hosts terraform_servers -m shell -a "java -version"
                
                ansible -i inventory/hosts terraform_servers -m shell -a "docker --version"

                ansible -i inventory/hosts terraform_servers -m shell -a "docker ps"
                
                ansible -i inventory/hosts terraform_servers -m shell -a "systemctl is-active docker"                
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