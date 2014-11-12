
default:	build

clean:
	rm -rf Makefile objs

build:
	$(MAKE) -f objs/Makefile
	$(MAKE) -f objs/Makefile manpage

install:
	$(MAKE) -f objs/Makefile install

upgrade:
	/home/isucon/isucon4-qualifier_luajit-nginx-redis/nginx/sbin/nginx -t

	kill -USR2 `cat /home/isucon/isucon4-qualifier_luajit-nginx-redis/nginx/logs/nginx.pid`
	sleep 1
	test -f /home/isucon/isucon4-qualifier_luajit-nginx-redis/nginx/logs/nginx.pid.oldbin

	kill -QUIT `cat /home/isucon/isucon4-qualifier_luajit-nginx-redis/nginx/logs/nginx.pid.oldbin`
