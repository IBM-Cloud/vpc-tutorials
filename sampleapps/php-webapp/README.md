# About php-api-webapp

This sample app demonstrates a sample front end PHP API and web application interacting with backend APIs.
If you don't yet have an IBM Cloud account, sign up on the [registration](https://cloud.ibm.com/registration/) page.

# Pre-Requisites
  - PHP 7.4+
  - nodejs-graphql sample
  - Nginx

## Getting Started

- Clone the repo.

- Install all dependencies:

    ```sh
    apt update
    apt install php-fpm nginx -y
    ```
- Modify Nginx config

    ```sh
      vi /etc/nginx/sites-available/default
    ```
    add/modify the lines below
      - add: index.php in the line that reads:   index index.php index.html index.htm index.nginx-debian.html;
      - add: address of the load balancer or FIP in the line that reads: server_name _;
      - modify: line to remove comments as below:
              location ~ \.php$ {
                      include snippets/fastcgi-php.conf;
                      fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
      - add: add variable called LB_INTERNAL to point to the address of the private load balancer

    ```sh
      index index.php index.html index.htm index.nginx-debian.html;
      server_name frontendlb-us-east.lb.appdomain.cloud;
      location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
            fastcgi_param LB_INTERNAL backendlb-us-east.lb.appdomain.cloud;
    ```

` Restart the Nginx service
    ```sh
      service nginx start
    ```