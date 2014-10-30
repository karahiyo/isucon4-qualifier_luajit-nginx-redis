
default:	build

clean:
	rm -rf Makefile objs

build:
	$(MAKE) -f objs/Makefile
	$(MAKE) -f objs/Makefile manpage

install:
	$(MAKE) -f objs/Makefile install

upgrade:
	/Users/yu_ke/workspace/ISUCON2014/isucon4_luajit+nginx/nginx/sbin/nginx -t

	kill -USR2 `cat /Users/yu_ke/workspace/ISUCON2014/isucon4_luajit+nginx/nginx/logs/nginx.pid`
	sleep 1
	test -f /Users/yu_ke/workspace/ISUCON2014/isucon4_luajit+nginx/nginx/logs/nginx.pid.oldbin

	kill -QUIT `cat /Users/yu_ke/workspace/ISUCON2014/isucon4_luajit+nginx/nginx/logs/nginx.pid.oldbin`
