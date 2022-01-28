resource "random_string" "no_rum_password" {
  length           = 12
  special          = false #not using special characters to allow double click copy and paste from g-sheet
}

resource "random_string" "no_rum_prefix" {
  length    = 4
  lower     = true
  upper     = false
  number    = false
  special   = false
}

resource "aws_instance" "no_rum" {
  ami                    = data.aws_ami.latest-ubuntu.id
  instance_type          = var.rum_master_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.rum.id]

  root_block_device {
    volume_size = var.instance_disk_aws
  }

  tags = {
    Name = lower(join("_", ["${var.env}", "no-rum"]))
    Environment = lower(var.env)
    Role  = "No RUM"
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
      "helm install splunk-otel-collector --set=splunkObservability.realm=${var.realm} --set=splunkObservability.accessToken=${var.access_token} --set=clusterName=${random_string.no_rum_prefix.result}-no-rum --set=splunkObservability.logsEnabled=true --set=environment=${random_string.no_rum_prefix.result}-no-rum splunk-otel-collector-chart/splunk-otel-collector -f ~/workshop/k3s/otel-collector.yaml",

      # Deploy No RUM version of Online Boutique
      "sudo kubectl apply -f /home/ubuntu/workshop/apm/microservices-demo/k8s/deployment.yaml",
      
      ## Move and set permissions on message of the day
      "sudo mv /tmp/motd /etc/motd",
      "sudo chmod -x /etc/update-motd.d/*",

      ## Set Password for Ubuntu
      "echo ubuntu:${random_string.no_rum_password.result} | sudo chpasswd",
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

  output "no_rum_details" {
    value =  formatlist(
      "%s, %s, %s, %s", 
      random_string.no_rum_prefix.result,
      aws_instance.no_rum.*.tags.Name,
      aws_instance.no_rum.*.public_ip,
      random_string.no_rum_password.*.result,
    )
  }

  output "no_rum_online_boutique_details" {
    value = formatlist(
      "%s%s:%s", 
      "http://",
      aws_instance.no_rum.*.public_ip,
      "81",
    )
  }
