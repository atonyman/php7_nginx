#!/bin/sh

# Start different services based on the container role since this 
#  image is used for the queue etc also.
# Put composer bin in path of shell for things like craftable commands

echo 'export PATH="$PATH:/var/www/vendor/bin"' >> ~/.bashrc

case $CONTAINER_ROLE in
	laravel)
		# Lookf for flag to rebuild composer
		if [ "$REBUILD" = "1" ]
		then
			rm -rf /var/www/vendor
			rm /var/www/composer.lock
			composer install --working-dir="/var/www"  --no-interaction
			npm clean-install
			php artisan horizon:install
			php artisan craftable:install
		fi
		# run migrations if present
		php artisan migrate
		# Start npm, php-fpm and nginx
		npm run $NPM_ENV
		php-fpm -D &&  nginx -g "daemon off;"
		;;
	worker)
		# MAYBE NEED THIS php artisan queue:restart
		php artisan queue:work
		break
		;;
	cron)
		# env -o posix -c 'export -p' > /etc/cron.d/project_env.sh && chmod +x /etc/cron.d/project_env.sh && crontab /etc/cron.d/artisan-schedule-run && cron && tail -f > /dev/stdout
		# put the above in the docker-compose command override for this container, needd to escape differently in this .sh and is broken.
		echo "hello from cron"
		break
		;;
	horizon)
		php artisan horizon
		php artisan queue:restart
		;;
	*)
		# Start npm, php-fpm and nginx as a Default
		echo "!!!!!!!No CONTAINER_ROLE set!!!!!!!"
		npm run $NPM_ENV
		php-fpm -D &&  nginx -g "daemon off;"
		;;
esac

echo ".......Clearing caches, configs and routes......."

php artisan route:clear
php artisan config:clear
php artisan cache:clear
