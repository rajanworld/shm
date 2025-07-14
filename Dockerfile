# Stage 1: Composer
FROM composer:2.7 as vendor

WORKDIR /var/www/html
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# Stage 2: Node/Vite build
FROM node:18 as assets

WORKDIR /var/www/html
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 3: Laravel + PHP + Nginx
FROM php:8.2-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    nginx curl zip unzip git libpq-dev libonig-dev libxml2-dev libzip-dev libpng-dev \
    && docker-php-ext-install pdo pdo_pgsql mbstring zip bcmath gd

# Copy project files
COPY . /var/www/html
COPY --from=vendor /var/www/html/vendor /var/www/html/vendor
COPY --from=assets /var/www/html/public /var/www/html/public

# Permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Copy nginx config
COPY .docker/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Start php-fpm and nginx
CMD service php8.2-fpm start && nginx -g 'daemon off;'
