
default:	build

clean:
	rm -rf Makefile objs

build:
	$(MAKE) -f objs/Makefile
	$(MAKE) -f objs/Makefile manpage

install:
	$(MAKE) -f objs/Makefile install

upgrade:
	/home/vagrant/isucon/isucon4-qualifier_luajit-nginx/nginx/sbin/nginx -t

	kill -USR2 `cat /home/vagrant/isucon/isucon4-qualifier_luajit-nginx/nginx/logs/nginx.pid`
	sleep 1
	test -f /home/vagrant/isucon/isucon4-qualifier_luajit-nginx/nginx/logs/nginx.pid.oldbin

	kill -QUIT `cat /home/vagrant/isucon/isucon4-qualifier_luajit-nginx/nginx/logs/nginx.pid.oldbin`
