#!/bin/bash

# Path to save domain and MySQL information
DOMAIN_INFO_FILE="domain_info.txt"

# Function to install Caddy, MySQL, Postfix, and Dovecot
install_services() {
    echo "Installing Caddy, MySQL, Postfix, and Dovecot..."
    # Install Caddy
    sudo apt update
    sudo apt install -y debian-keyring debian-archive-keyring
    sudo apt install -y apt-transport-https
    curl -fsSL https://deb.caddyserver.com/api/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/caddy.gpg
    echo "deb [signed-by=/usr/share/keyrings/caddy.gpg] https://deb.caddyserver.com/ubuntu/ focal main" | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt update
    sudo apt install -y caddy

    # Install MySQL
    sudo apt install -y mysql-server

    # Install Postfix and Dovecot
    sudo apt install -y postfix dovecot-core dovecot-imapd

    echo "Installation completed."
}

# Function to list domains
list_domains() {
    if [ -f "$DOMAIN_INFO_FILE" ]; then
        echo "List of configured domains:"
        cat "$DOMAIN_INFO_FILE"
    else
        echo "No domains configured."
    fi
}

# Function to add a domain
add_domain() {
    read -p "Enter domain name: " domain
    if grep -q "$domain" "$DOMAIN_INFO_FILE"; then
        echo "Domain is already configured."
        return
    fi

    # Create directory for the domain
    mkdir -p "/var/www/$domain"
    echo "Created directory for domain: /var/www/$domain"

    # Create random MySQL user account
    user="user_$(openssl rand -hex 4)"
    password="$(openssl rand -hex 12)"
    mysql -e "CREATE DATABASE ${domain//./_}; CREATE USER '$user'@'localhost' IDENTIFIED BY '$password'; GRANT ALL PRIVILEGES ON ${domain//./_}.* TO '$user'@'localhost'; FLUSH PRIVILEGES;"

    echo "$domain, /var/www/$domain, $user, $password" >> "$DOMAIN_INFO_FILE"
    echo "Added domain: $domain"
    echo "MySQL account: $user, Password: $password"
}

# Function to remove a domain
remove_domain() {
    read -p "Enter domain name to remove: " domain
    if ! grep -q "$domain" "$DOMAIN_INFO_FILE"; then
        echo "Domain does not exist."
        return
    fi

    # Remove Caddy configuration
    sed -i "/$domain/d" "$DOMAIN_INFO_FILE"

    # Remove MySQL database
    mysql -e "DROP DATABASE ${domain//./_};"
    mysql -e "DROP USER 'user_@'localhost';"

    echo "Removed domain: $domain"
}

# Function to backup all databases
backup_all_databases() {
    echo "Backing up all databases..."
    mysqldump --all-databases | gzip > "all_databases_$(date +%F).sql.gz"
    echo "Backup completed: all_databases_$(date +%F).sql.gz"
}

# Function to backup a website
backup_website() {
    list_domains
    read -p "Enter domain name to backup: " domain
    if ! grep -q "$domain" "$DOMAIN_INFO_FILE"; then
        echo "Domain does not exist."
        return
    fi

    # Compress the domain's directory
    tar -czf "${domain}_backup_$(date +%F).tar.gz" "/var/www/$domain"
    echo "Compressed directory: ${domain}_backup_$(date +%F).tar.gz"

    # Backup the domain's database
    db_name="${domain//./_}"
    mysqldump "$db_name" | gzip > "${db_name}_backup_$(date +%F).sql.gz"
    echo "Backup database: ${db_name}_backup_$(date +%F).sql.gz"
}

# Function to optimize swap
optimize_swap() {
    echo "Checking swap optimization..."
    # Get CPU and RAM info
    cpu_count=$(nproc)
    ram_size=$(free -m | awk '/^Mem:/{print $2}')
    swap_size=$((ram_size / 2))  # Assume swap = 0.5 * RAM
    sudo swapon --show || echo "No swap is currently enabled."
    
    echo "Will set swap size: ${swap_size}MB"
    # Set up swap
    sudo fallocate -l "${swap_size}M" /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
    echo "Swap has been set up."
}

# Function to install Let's Encrypt SSL for a domain
install_ssl() {
    list_domains
    read -p "Enter domain name to install SSL: " domain
    if ! grep -q "$domain" "$DOMAIN_INFO_FILE"; then
        echo "Domain does not exist."
        return
    fi

    # Configure SSL with Let's Encrypt
    sudo caddy reload
    echo "Installing SSL for domain: $domain"
    # Run Caddy with automatic SSL management
    sudo systemctl restart caddy
    echo "SSL installation completed for domain: $domain"
}

# Function to renew SSL for all domains
renew_ssl() {
    echo "Renewing SSL certificates for all domains..."
    sudo caddy reload
    echo "SSL renewal completed."
}

# Main menu
while true; do
    echo "Choose an option:"
    echo "1. Install Caddy server + MySQL + Postfix + Dovecot"
    echo "2. List domains"
    echo "3. Add domain"
    echo "4. Remove domain"
    echo "5. Backup all databases"
    echo "6. Backup website"
    echo "7. Optimize swap"
    echo "8. Install SSL Let's Encrypt for a domain"
    echo "9. Renew SSL for all domains"
    echo "0. Exit"
    read -p "Your choice: " choice

    case $choice in
        1) install_services ;;
        2) list_domains ;;
        3) add_domain ;;
        4) remove_domain ;;
        5) backup_all_databases ;;
        6) backup_website ;;
        7) optimize_swap ;;
        8) install_ssl ;;
        9) renew_ssl ;;
        0) exit ;;
        *) echo "Invalid choice." ;;
    esac
done
