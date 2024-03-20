# Enabling Password based SSH

  sudo nano /etc/ssh/sshd_config

  Set 'PasswordAuthentication Yes'

Save the file & restart SSH

  sudo systemctl restart ssh
