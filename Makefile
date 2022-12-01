# Makefile for Docker Nginx PHP Composer MySQL

include .env

# MySQL
MYSQL_DUMPS_DIR=data/dumps

help:
	@echo ""
	@echo "usage: make COMMAND"
	@echo ""
	@echo "Commands:"
	@echo "  apidoc              	Generate documentation of API"
	@echo "  code-sniff          	Check the API with PHP Code Sniffer (PSR2)"
	@echo "  clean               	Clean directories for reset"
	@echo "  composer-up         	Update PHP dependencies with composer"
	@echo "  docker-start        	Create and start containers"
	@echo "  docker-stop         	Stop and clear all services"
	@echo "  gen-certs           	Generate SSL certificates"
	@echo "  logs                	Follow log output"
	@echo "  mysql-dump          	Create backup of whole database"
	@echo "  mysql-restore       	Restore backup from whole database"
	@echo "  test                	Test application"
	@echo ""
	@echo "Laravel:"
	@echo "  cache-clear            Flush the application cache"
	@echo "  composer-install       Install composer dependencies"
	@echo "  composer-update        Update composer dependencies"
	@echo "  composer-outdated      Show outdated composer dependencies"
	@echo "  composer-autoload      PHP composer autoload command"
	@echo "  db-seed         		Seed the database with records"
	@echo "  migrate           		Generate SSL certificates"
	@echo "  migrate-fresh          Drop all tables and re-run all migrations"
	@echo "  migrate-install        Drop all tables and re-run all migrations"
	@echo "  migrate-refresh       	Reset and re-run all migrations"
	@echo "  migrate-reset       	Rollback all database migrations"
	@echo "  migrate-rollback       Rollback the last database migration"
	@echo "  migrate-status       	Rollback the last database migration"
	@echo "  npm-install            Install npm dependencies"
	@echo "  npm-update             Update npm dependencies"
	@echo "  npm-outdated           Show outdated npm dependencies"
	@echo "  queue-listen           Running the queue listener"
	@echo "  queue-work             Running the queue worker"
	@echo "  queue-restart          Restarting the queue workers"
	@echo "  storage-link           Create the symbolic links configured for the application"
	@echo "  storage-perm           Give permissions of the storage folder to the www-data"
	@echo "  storage-per-me         Give permissions of the storage folder to the current user"

init:
	@$(shell cp -n $(shell pwd)/web/app/composer.json.dist $(shell pwd)/web/app/composer.json 2> /dev/null)

apidoc:
	@docker-compose exec -T php ./app/vendor/bin/apigen generate app/src --destination app/doc
	@make resetOwner

clean:
	@rm -Rf data/mysql/*
	@rm -Rf $(MYSQL_DUMPS_DIR)/*
	@rm -Rf web/app/vendor
	@rm -Rf web/app/composer.lock
	@rm -Rf web/app/doc
	@rm -Rf web/app/report
	@rm -Rf etc/ssl/*

code-sniff:
	@echo "Checking the standard code..."
	@docker-compose exec -T php ./app/vendor/bin/phpcs -v --standard=PSR2 app/src

composer-up:
	@docker run --rm -v $(shell pwd)/web/app:/app composer update

docker-start: init
	docker-compose up -d

docker-stop:
	@docker-compose down -v
	@make clean

gen-certs:
	@docker run --rm -v $(shell pwd)/etc/ssl:/certificates -e "SERVER=$(NGINX_HOST)" jacoelho/generate-certificate

logs:
	@docker-compose logs -f

mysql-dump:
	@mkdir -p $(MYSQL_DUMPS_DIR)
	@docker exec $(shell docker-compose ps -q mysqldb) mysqldump --all-databases -u"$(MYSQL_ROOT_USER)" -p"$(MYSQL_ROOT_PASSWORD)" > $(MYSQL_DUMPS_DIR)/db.sql 2>/dev/null
	@make resetOwner

mysql-restore:
	@docker exec -i $(shell docker-compose ps -q mysqldb) mysql -u"$(MYSQL_ROOT_USER)" -p"$(MYSQL_ROOT_PASSWORD)" < $(MYSQL_DUMPS_DIR)/db.sql 2>/dev/null

test: code-sniff
	@docker-compose exec -T php ./app/vendor/bin/phpunit --colors=always --configuration ./app/
	@make resetOwner

resetOwner:
	@$(shell chown -Rf $(SUDO_USER):$(shell id -g -n $(SUDO_USER)) $(MYSQL_DUMPS_DIR) "$(shell pwd)/etc/ssl" "$(shell pwd)/web/app" 2> /dev/null)

.PHONY: clean test code-sniff init

#-----------------------------------------------------------
# Laravel
#-----------------------------------------------------------

# Flush the application cache
cache-clear:
	@docker-compose exec app php artisan cache:clear

# Install composer dependencies
composer-install:
	@docker-compose exec app composer install

# Update composer dependencies
composer-update:
	@docker-compose exec app composer update

# Show outdated composer dependencies
composer-outdated:
	@docker-compose exec app composer outdated

# PHP composer autoload command
composer-autoload:
	@docker-compose exec app composer dump-autoload

# Seed the database with records
db-seed:
	@docker-compose exec app php artisan db:seed

# Migrate the database
migrate:
	@docker-compose exec app php artisan migrate

# Drop all tables and re-run all migrations
migrate-fresh:
	@docker-compose exec app php artisan migrate:fresh

# Create the migration repository
migrate-install:
	@docker-compose exec app php artisan migrate:refresh

# Reset and re-run all migrations
migrate-refresh:
	@docker-compose exec app php artisan migrate:refresh

# Rollback all database migrations
migrate-reset:
	@docker-compose exec app php artisan migrate:reset

# Rollback the last database migration
migrate-rollback:
	@docker-compose exec app php artisan migrate:rollback

# Show the status of each migration
migrate-status:
	@docker-compose exec app php artisan migrate:status

# Install npm dependencies
npm-install:
	@docker-compose exec app npm install

# Update npm dependencies
npm-update:
	@docker-compose exec app npm update

# Show outdated npm dependencies
npm-outdated:
	@docker-compose exec app npm outdated

# Running the queue listener
queue-listen:
	@docker-compose exec app php artisan queue:listen

# Running the queue worker
queue-work:
	@docker-compose exec app php artisan queue:work

# Restart the queue process
queue-restart:
	@docker-compose exec app php artisan queue:restart

# Generate a symlink to the storage directory
storage-link:
	@docker-compose exec app php artisan storage:link --relative

# Give permissions of the storage folder to the www-data
storage-perm:
	sudo chmod -R 755 storage
	sudo chown -R www-data:www-data storage

# Give permissions of the storage folder to the current user
storage-perm-me:
	sudo chmod -R 755 storage
	sudo chown -R "$(shell id -u):$(shell id -g)" storage

# Give files ownership to the current user
own-me:
	sudo chown -R "$(shell id -u):$(shell id -g)" .