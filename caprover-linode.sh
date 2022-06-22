#!/bin/bash
#
# Debian 10 w/basic setup, security, postfix gmail relay, openjdk8, Docker, Caprover
# Copyright (c) 2020 Native IT
#
# IMPORTANT: Once deployed, visit https://{host}:9000 to change the default admin password!
# 
# <UDF name="user1_name" label="User 1 account name" example="This is the account that you will be using to log in." />
# <UDF name="user1_password" label="User 1 password" />
# <UDF name="user1_group" label="Add'l group for user 1" default="" />
# <UDF name="user1_shell" label="Shell" oneof="/bin/zsh,/bin/bash" default="/bin/bash" />
#
# <UDF name="user1_sshkey" label="Public Key for user 1" default="" example="Recommended method of authentication. It is more secure than password log in." />
# <UDF name="sshd_port" label="SSH Listening Port" default="22" />
# <UDF name="domain" label="System domain name" default="example.tld" example="Domain w/out hostname" />
# <UDF name="fqdn" label="Fully Qualified Domain Name" />
# <UDF name="letsencrypt_email" label="E-mail address for Let's Encrypt" default="admin@example.tld" />
# <UDF name="tz" label="Time Zone" default="America/New_York" example="Example: America/New_York (see: http://bit.ly/TZlisting)" />
# <UDF name="relay_email" label="Gmail email including domain as relay" example="Email used to login into Gmail/GApps" />
# <UDF name="relay_password" label="Gmail account app-specific password" example="Email account password (app specific with 2factor auth)" />

# Setup "Unofficial Bash Strict Mode" -- http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -e # Exit immediately on error
set -u # Throw error on undefined variable
#set -x # Uncomment to enable debugging

exec &> /root/stackscript.log

set +u

source <ssinclude StackScriptID="1"> # StackScript Bash Library
#source ./linode-ss1.sh

source <ssinclude StackScriptID="691666"> # lib-system-utils
#source ./lib-system-utils.sh

source <ssinclude StackScriptID="691674"> # lib-system-debian
#source ./lib-system-debian.sh

set -u

# Set variables
IPADDR=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
NOTIFY_EMAIL=${LETSENCRYPT_EMAIL}

echo "###################################################################################"
echo "Please be Patient: Installation will start now....... It may take some time :)"
echo "###################################################################################"

###########################################################
# System setup
###########################################################

# Update repositories and system packages
system_update
debian_upgrade

# Set the hostname & add fully-qualified domain name (FQDN) in hosts file
system_primary_ip
system_primary_ipv6
system_set_hostname ${FQDN}

# Extend /etc/apt/sources.list
system_enable_extended_sources

# Set timezone
if [ -n $TZ ]
then
  timedatectl set-timezone $TZ
fi

# Setup /etc versioning
system_install_git
system_start_etc_dir_versioning ${LETSENCRYPT_EMAIL}

# Setup NTP
system_configure_ntp

###########################################################
# User & Security
###########################################################

# Install ZSH if selected during setup
if [ "${USER1_SHELL}" = "/bin/zsh" ]; then
    DEBIAN_FRONTEND=noninteractive apt-get -y install zplug zsh zsh zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel9k
fi
system_record_etc_dir_changes "Installed ZSH login shell for ${USER1_NAME}."

# Create user accounts
system_add_user "${USER1_NAME}" "${USER1_PASSWORD}" "${USER1_GROUP}" "${USER1_SHELL}"

if [ -z "${USER1_SSHKEY}" ]; then
  echo "A public key must be provided to provision SSH key pair authentication."
else
    user_add_pubkey "${USER1_NAME}" "${USER1_SSHKEY}"
fi
system_record_etc_dir_changes "Added sudo user account"

# Setup user profile enhancements (dir_color terminal output, screenfetch )
if [ "${USER1_SHELL}" = "/bin/bash" ]; then
    system_pimp_user_profiles "$USER1_NAME"
fi
system_record_etc_dir_changes "Added custom bash profile settings." 

# Configure SSHD
system_configure_sshd "${USER1_SSHKEY}" "${SSHD_PORT}"
system_record_etc_dir_changes "Configured SSH for key authentication and custom port." 

# Setup logcheck
system_security_logcheck
system_record_etc_dir_changes "Installed logcheck" 

# Setup fail2ban
system_security_fail2ban
system_record_etc_dir_changes "Installed fail2ban"

# Install UFW
system_security_ufw_install "${SSHD_PORT}"
system_record_etc_dir_changes "Installed UFW"

# Setup UFW
system_security_ufw_configure_advanced "${SSHD_PORT}"
system_record_etc_dir_changes "Setup UFW with ports for Docker, Portainer, Virtualmin, SSH"

###########################################################
# Software & Utilities
###########################################################

# Install basic system utilities
system_install_utils
system_install_java11
system_record_etc_dir_changes "Installed common utils"

# Install Postfix
if [ -z "${RELAY_EMAIL}" ]; then
  echo "Skipping Gmail relay setup"
else
postfix_install_gmail_relay
system_record_etc_dir_changes "Installed postfix gmail relay"
fi

# Install Docker + Docker Compose
DEBIAN_FRONTEND=noninteractive apt-get -y install docker docker-compose
system_record_etc_dir_changes "Installed Docker and Docker Compose"

# Install ctop: https://github.com/bcicen/ctop
DEBIAN_FRONTEND=noninteractive apt-get -y install ctop

# Install Caprover
IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')
cat << EOF > /tmp/caprover.json
    {"caproverIP": "$IPADDR", "caproverPassword": "${USER1_PASSWORD}", "caproverRootDomain": "${DOMAIN}", "newPassword": "${USER1_PASSWORD}", "certificateEmail": "${LETSENCRYPT_EMAIL}", "caproverName": "captain"}
EOF
docker run -p 80:80 -p 443:443 -p 3000:3000 -v /var/run/docker.sock:/var/run/docker.sock -v /captain:/captain caprover/caprover
npm install -g caprover
caprover serversetup -c /tmp/caprover.json

# Retain log after reboot
system_configure_persistent_journal
system_record_etc_dir_changes "Configure persistent journal"

# Send info message
cat > ~/setup_message <<EOD
Hi,

Your Linode VPS configuration is completed. You may access Caprover at https://$FQDN:3000.

EOD

mail -s "Your Linode VPS $FQDN is ready" "$NOTIFY_EMAIL" < ~/setup_message

# Wrap it up
automatic_security_updates
goodstuff
restart_services
restart_initd_services
all_set
stackscript_cleanup
