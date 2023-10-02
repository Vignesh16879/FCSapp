#!/bin/bash

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python is not installed. Installing Python..."
    # You can use package manager specific commands, e.g., apt-get for Ubuntu, or brew for macOS
    # Replace the following line with the appropriate command for your system.
    sudo apt-get update
    sudo apt-get install -y python3
else
    echo "Python is already installed."
fi

# Check if venv module is available
if ! python3 -m venv --help &> /dev/null; then
    echo "python3-venv is not installed. Installing python3-venv..."
    sudo apt-get install -y python3-venv
else
    echo "python3-venv is already installed."
fi

# Create a Python virtual environment
if [ ! -d "venv" ]; then
    echo "Creating a Python virtual environment (venv)..."
    python3 -m venv venv
else
    echo "Python virtual environment (venv) already exists."
fi

# Activate the virtual environment
source venv/bin/activate

# Upgrade pip within the virtual environment
echo "Upgrading pip within the virtual environment..."
pip install --upgrade pip

# Install packages from requirements.txt if it exists
if [ -f "requirements.txt" ]; then
    echo "Installing packages from requirements.txt within the virtual environment..."
    pip install -r requirements.txt
else
    echo "requirements.txt not found. Skipping package installation."
fi

# Install and configure Apache as a reverse proxy
echo "Installing Apache and configuring it as a reverse proxy..."
sudo apt-get install -y apache2
sudo a2enmod proxy proxy_http
sudo systemctl restart apache2

# Create an Apache Virtual Host configuration
cat <<EOL | sudo tee /etc/apache2/sites-available/my_django_app.conf > /dev/null
<VirtualHost *:80>
    ServerName your_domain.com
    ServerAlias www.your_domain.com

    ProxyPass / http://127.0.0.1:8000/
    ProxyPassReverse / http://127.0.0.1:8000/
</VirtualHost>
EOL

# Enable the Apache Virtual Host configuration
sudo a2ensite my_django_app.conf
sudo systemctl reload apache2

# Allow incoming traffic on port 8000
echo "Allowing incoming traffic on port 8000..."
sudo ufw allow 8000/tcp

# Install and configure Nginx as a reverse proxy
echo "Installing Nginx and configuring it as a reverse proxy..."
sudo apt-get install -y nginx

# Create an Nginx server block configuration
cat <<EOL | sudo tee /etc/nginx/sites-available/my_django_app > /dev/null
server {
    listen 80;
    server_name your_domain.com www.your_domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOL

# Create a symbolic link to enable the Nginx server block
sudo ln -s /etc/nginx/sites-available/my_django_app /etc/nginx/sites-enabled/

# Test the Nginx configuration
sudo nginx -t

# If the test is successful, reload Nginx to apply the changes
sudo systemctl reload nginx

# Run 'python manage.py makemigrations main' and 'python manage.py makemigrations admin'
if [ -f "manage.py" ]; then
    echo "Running 'python manage.py makemigrations main' within the virtual environment..."
    python manage.py makemigrations main

    echo "Running 'python manage.py makemigrations admin' within the virtual environment..."
    python manage.py makemigrations admin

    echo "Running 'python manage.py migrate' within the virtual environment..."
    python manage.py migrate

    echo "Running 'python3 manage.py runserver_plus --cert-file certificate/foo.crt' within the virtual environment..."
    python3 manage.py runserver_plus --cert-file certificate/foo.crt
else
    echo "manage.py not found. Skipping 'makemigrations' and 'migrate' commands."
fi

echo "Installation complete. The virtual environment is activated, and both Apache and Nginx are configured as reverse proxies."
