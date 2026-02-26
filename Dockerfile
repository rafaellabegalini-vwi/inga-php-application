FROM php:8.4-cli

# Argumentos de build
ARG NODE_VERSION=20

# Diretório de trabalho
WORKDIR /var/www/html

# Dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Instalar o docker-php-extension-installer do mlocati
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Instalar extensões PHP recomendadas pelo Laravel
# BCMath, cURL, DOM, Fileinfo, Mbstring, PDO, Tokenizer, XML, ZIP, Intl
RUN install-php-extensions \
    bcmath \
    curl \
    dom \
    fileinfo \
    intl \
    mbstring \
    pdo \
    pdo_sqlite \
    tokenizer \
    xml \
    zip

# Instalar Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Instalar Node.js para build dos assets
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Copiar arquivos do projeto
COPY . .

# Instalar dependências PHP
RUN composer install --no-dev --optimize-autoloader --no-interaction \
    && touch database/database.sqlite \
    && php artisan migrate --force

# Instalar dependências Node e build dos assets
RUN npm ci && npm run build

# Expor porta 8000 (padrão do artisan serve)
EXPOSE 8000

# Servidor embutido do PHP (artisan serve)
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
