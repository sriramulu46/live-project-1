


resource "aws_instance" "tf-vm-instance" {
  for_each = var.instances

  key_name      = "main"
  ami           = "ami-04a81a99f5ec58529"
  instance_type = each.value

  tags = {
    Name = each.key
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 30
  }

}




resource "null_resource" "ansible_controller" {
  for_each = var.instances

  connection {
    type        = "ssh"
    user        = "ubuntu"                          # Default user for Ubuntu instances
    host        = aws_instance.tf-vm-instance[each.key].public_ip
    private_key = file("c:/SRIRAM/Live-Project/main.pem")  # Ensure this path is correct
  }

  # Copy the ansible.sh file to the instance
  provisioner "file" {
    source      = each.key == "ansible-controller" ? "ansible.sh" : "empty.sh"
    destination = each.key == "ansible-controller" ? "/home/ubuntu/ansible.sh" : "/home/ubuntu/empty.sh"
  }

  # Execute the ansible.sh file if it's the ansible-controller
  provisioner "remote-exec" {
    inline = each.key == "ansible-controller" ? [
      "chmod +x /home/ubuntu/ansible.sh",             # Make the file executable
      "/home/ubuntu/ansible.sh"                        # Execute the file
    ] : []
  }
}
##=============Host name update========
resource "null_resource" "update_hostname" {
  for_each = var.instances

  connection {
    type        = "ssh"
    user        = "ubuntu"  # Adjust user as necessary
    host        = aws_instance.tf-vm-instance[each.key].public_ip
    private_key = file("c:/SRIRAM/Live-Project/main.pem")  # Path to your private key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${each.key}",  # Change the hostname
      # "sudo sed -i 's/127.0.0.1.*/127.0.0.1 ${each.key}/' /etc/hosts",  # Update /etc/hosts
      "sudo reboot"  # Reboot the instance to apply hostname change
    ]
  }
}
