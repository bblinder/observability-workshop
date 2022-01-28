resource "random_string" "rum_master_password" {
  length           = 12
  special          = false #not using special characters to allow double click copy and paste from g-sheet
}

resource "aws_instance" "rum_master" {
  ami                    = data.aws_ami.latest-ubuntu.id
  instance_type          = var.rum_master_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.rum.id]

  root_block_device {
    volume_size = var.instance_disk_aws
  }

  tags = {
    Name = lower(join("-", ["${var.env}", "rum-master"]))
    Environment = lower(var.env)
    Role  = "RUM Master"
  }

  provisioner "file" {
    source      = "${path.module}/motd"
    destination = "/tmp/motd"
  }

  provisioner "file" {
    source      = "${path.module}/profile"
    destination = "~/.profile"
  }

  provisioner "file" {
    source      = "${path.module}/shellinabox"
    destination = "~/.shellinabox"
  }

  provisioner "remote-exec" {
    inline = [
      ## Set Hostname
      "sudo sed -i 's/127.0.0.1.*/127.0.0.1 ${self.tags.Name}.local ${self.tags.Name} localhost/' /etc/hosts",
      "sudo hostnamectl set-hostname ${self.tags.Name}",

      # Download and Install the Latest Updates for the OS - NOTE the two entries of apt-get update are there by design
      "sudo apt-get update",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y unzip shellinabox lynx w3m",
    
      # Install K3s
      # "curl -sfL https://get.k3s.io | sh -",
      "curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE=\"644\" sh -s -",

      #Install Helm
      "curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash",

      # Install K9s (Kubernetes UI)
      "curl -s -OL https://github.com/derailed/k9s/releases/download/${var.k9sversion}/k9s_Linux_x86_64.tar.gz",
      "tar xfz k9s_Linux_x86_64.tar.gz",
      "sudo mv k9s /usr/local/bin/",

      # Download Workshop
      "export WSARCHIVE=$([ ${var.wsversion} = \"master\" ] && echo \"master\" || echo v${var.wsversion})",
      "curl -s -OL https://github.com/signalfx/observability-workshop/archive/$WSARCHIVE.zip",
      "unzip -qq $WSARCHIVE.zip -d /home/ubuntu/",
      "mv /home/ubuntu/observability-workshop-${var.wsversion} /home/ubuntu/workshop",

      # fix shellinabox port and ssl then restart
      "mv /tmp/shellinabox /etc/default/shellinabox",
      "sudo chown root:root /etc/default/shellinabox",
      "sudo service shellinabox restart",

      # Create kube config and set correct permissions on ubuntu user home directory
      "mkdir /home/ubuntu/.kube && sudo kubectl config view --raw > /home/ubuntu/.kube/config",
      "chmod 400 /home/ubuntu/.kube/config",
      "chown -R ubuntu:ubuntu /home/ubuntu",

      # fix shellinabox port and ssl then restart
      "mv /tmp/shellinabox /etc/default/shellinabox",
      "sudo chown root:root /etc/default/shellinabox",
      "sudo service shellinabox restart",

      # Deploy Agent using Helm
      "helm repo add splunk-otel-collector-chart https://signalfx.github.io/splunk-otel-collector-chart && helm repo update",
      "helm install splunk-otel-collector --set=splunkObservability.realm=${var.realm} --set=splunkObservability.accessToken=${var.access_token} --set=clusterName=${var.env} --set=splunkObservability.logsEnabled=true --set=environment=${var.env} splunk-otel-collector-chart/splunk-otel-collector -f ~/workshop/k3s/otel-collector.yaml",

      # Deploy RUM version of Online Boutique
      "sed -i '/^          - name: RUM_REALM/a\\            value: \"${var.realm}\"' /home/ubuntu/workshop/apm/microservices-demo/k8s/deployment.yaml",
      "sed -i '/^          - name: RUM_AUTH/a\\            value: \"${var.rum_token}\"' /home/ubuntu/workshop/apm/microservices-demo/k8s/deployment.yaml",
      "sed -i '/^          - name: RUM_APP_NAME/a\\            value: \"${var.env}-app\"' /home/ubuntu/workshop/apm/microservices-demo/k8s/deployment.yaml",
      "sed -i '/^          - name: RUM_ENVIRONMENT/a\\            value: \"${var.env}\"' /home/ubuntu/workshop/apm/microservices-demo/k8s/deployment.yaml",
      "sed -i '/^        - name: API_TOKEN_FAILURE_RATE/a\\          value: \"0.90\"' /home/ubuntu/workshop/apm/microservices-demo/k8s/deployment.yaml",
      "sed -i '/^        - name: ERROR_PAYMENT_SERVICE_DURATION_MILLIS/a\\          value: \"500\"' /home/ubuntu/workshop/apm/microservices-demo/k8s/deployment.yaml",
      
      # Update the front-end with one that has custom events 
      "sed -i 's~image: quay.io/signalfuse/microservices-demo-frontend:433c23881a~image: docker.io/harnit/shopdemo-frontend:2.1-customevents~' /home/ubuntu/workshop/apm/microservices-demo/k8s/deployment.yaml",
      
      # Apply the new deployment
      "sudo kubectl apply -f /home/ubuntu/workshop/apm/microservices-demo/k8s/deployment.yaml",
      
      ## Move and set permissions on message of the day
      "sudo mv /tmp/motd /etc/motd",
      "sudo chmod -x /etc/update-motd.d/*",

      ## Set Password for Ubuntu
      "echo ubuntu:${random_string.rum_master_password.result} | sudo chpasswd",
    ]
  }

  connection {
    host = self.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key_path)
    agent = "true"
  }
}

  output "rum_master_details" {
    value =  formatlist(
      "%s, %s, %s, %s",
      var.env,
      aws_instance.rum_master.*.tags.Name,
      aws_instance.rum_master.*.public_ip,
      random_string.rum_master_password.*.result,
    )
  }

  output "rum_online_boutique_details" {
    value = formatlist(
      "%s%s:%s", 
      "http://",
      aws_instance.rum_master.*.public_ip,
      "81",
    )
  }
