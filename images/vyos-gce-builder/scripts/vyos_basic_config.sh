# Setup motd message
source /opt/vyatta/etc/functions/script-template
configure
set system login banner post-login "Built using https://github.com/albertogeniola/terraform-gce-vyos."

# Disable plain text password authentication
set service ssh disable-password-authentication

commit
save
exit
