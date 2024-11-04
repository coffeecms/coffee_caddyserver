# Coffee CMS - Coffee Caddyserver - https://blog.lowlevelforest.com/

Welcome to the Coffee Caddyserver repository! This bash script provides an automated way to install and manage Caddy server, MySQL, Postfix, and Dovecot on your Ubuntu server. With this script, you can easily set up a web server and email server with SSL support.

## Features

- **Automated Installation**: Installs Caddy server, MySQL, Postfix, and Dovecot with a single command.
- **Domain Management**: Add, list, or remove domains configured with Caddy server.
- **SSL Management**: Automatically install and renew Let's Encrypt SSL certificates for your domains.
- **Database Backup**: Backup all MySQL databases or specific domains' databases easily.
- **Swap Optimization**: Optimize swap space based on your server's RAM.
- **Email Server Setup**: Configure Postfix and Dovecot for email handling.

## Advantages

- **User-Friendly**: Simplifies the process of setting up a web server and email server.
- **Secure**: Automatically configures SSL certificates with Let's Encrypt, ensuring secure connections.
- **Efficient**: Saves time and effort in configuring services manually.
- **Comprehensive**: Manages web and email functionalities in one place.

## Getting Started

### Prerequisites

- A server running Ubuntu (18.04 or later).
- Root or sudo access to install packages and configure services.
- A registered domain name that points to your server's IP address.

### Installation Steps

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/coffeecms/coffee_caddyserver.git
   cd coffee_caddyserver
   ```

2. **Make the Script Executable**:

   ```bash
   chmod +x setup.sh
   ```

3. **Run the Script**:

   Run the script as root or using `sudo`:

   ```bash
   sudo ./setup.sh
   ```

   Follow the prompts to install Caddy, MySQL, Postfix, and Dovecot.

### Configuring Your Domain

1. **Add Domain**:

   After the installation is complete, from the script's main menu, select the option to add a domain. Enter your domain name (e.g., `example.com`) when prompted.

2. **Directory Structure**:

   The script will create a directory for your domain at `/var/www/example.com`. Ensure this directory is accessible and contains your website files.

3. **Set Up DNS Records**:

   To run a mail server, you need to configure DNS records for your domain. Here are the essential records:

   - **A Record**: Points your domain to your server's IP address.
     ```
     example.com    A    <your_server_ip>
     mail.example.com  A    <your_server_ip>
     ```

   - **MX Record**: Directs email to your mail server.
     ```
     example.com    MX    10 mail.example.com
     ```

   - **TXT Records**: For SPF, DKIM, and DMARC configurations (optional but recommended).
     ```
     example.com    TXT    "v=spf1 mx ~all"  # Basic SPF record
     ```

   You can manage these records through your domain registrar's DNS settings.

4. **Setting Up SSL**:

   After adding the domain, select the option to install SSL. This will configure Let's Encrypt SSL for your domain automatically. The script will handle the necessary Caddyfile configuration.

### Setting Up Mail Server with Postfix and Dovecot

1. **Configure Postfix**:

   Edit the Postfix configuration file `/etc/postfix/main.cf` to set up your domain and SMTP settings. Update the following parameters:

   ```bash
   myhostname = mail.example.com
   mydomain = example.com
   myorigin = /etc/mailname
   mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
   relayhost =
   inet_interfaces = all
   inet_protocols = all
   ```

   Ensure that `myhostname` is set to `mail.example.com` and `mydomain` is set to your actual domain.

2. **Configure Dovecot**:

   Edit the Dovecot configuration file `/etc/dovecot/dovecot.conf` to set up IMAP and mailbox locations. Add or update the following:

   ```bash
   mail_location = maildir:~/Maildir
   service imap {
       executable = imap imap-login
   }
   ```

3. **Create Mail User**:

   Create a user that will handle the email for your domain:

   ```bash
   sudo adduser mailuser
   ```

   Replace `mailuser` with your preferred username. This user will have a home directory where emails will be stored.

4. **Restart Services**:

   After editing the configuration files, restart Postfix and Dovecot:

   ```bash
   sudo systemctl restart postfix
   sudo systemctl restart dovecot
   ```

5. **Test Email Sending**:

   You can test sending an email using the command line. Install `mailutils` if not already installed:

   ```bash
   sudo apt install mailutils
   ```

   Then, send a test email:

   ```bash
   echo "Test email body" | mail -s "Test Subject" recipient@example.com
   ```

   Replace `recipient@example.com` with an email address where you can receive the email.

### Example Configuration

Here’s a simple example to illustrate the setup:

1. **Domain Name**: `example.com`
2. **DNS Records**:
   - A Record: `example.com` → `<your_server_ip>`
   - MX Record: `example.com` → `mail.example.com`
   - TXT Record: `example.com` → `"v=spf1 mx ~all"`
3. **Add Domain**: Select the option to add `example.com` in the script.
4. **Install SSL**: Choose the option to install SSL for `example.com`.
5. **Configure Postfix and Dovecot**:
   - Update `/etc/postfix/main.cf` and `/etc/dovecot/dovecot.conf` as specified.
6. **Create a Mail User**: 
   ```bash
   sudo adduser mailuser
   ```
7. **Test Email**: Send a test email to check if everything is working correctly.

## Conclusion

The Coffee Caddyserver script simplifies the process of setting up a web server and email server, providing a comprehensive solution for developers and system administrators. Follow the steps outlined above to get your server running smoothly.

For any issues or contributions, feel free to open an issue or pull request!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


### Additional Notes
- Ensure that the DNS settings are correct and propagated before testing the mail server.
- Adjust any specific configurations based on your actual environment and needs.
- You may want to add instructions for setting up SPF, DKIM, and DMARC for better email deliverability and security.
- Include any necessary troubleshooting tips or common issues encountered during the setup.