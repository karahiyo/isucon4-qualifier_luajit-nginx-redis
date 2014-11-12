PWD=$(shell pwd)
LUAJIT_DIR=$(PWD)/luajit
LUAJIT_LIB=$(LUAJIT_DIR)/lib
LUAJIT_INC=$(LUAJIT_DIR)/include/luajit-2.1
RESTY_MODULE=$(PWD)/lib/ngx_openresty
NGINX=$(PWD)/nginx/sbin/nginx

ENV=$(shell echo LUAJIT_LIB=$(LUAJIT_LIB) LUAJIT_INC=$(LUAJIT_INC))

start:
	$(NGINX) -c $(PWD)/nginx.conf

restart:
	$(NGINX) -c $(PWD)/nginx.conf -s reload

stop:
	$(NGINX) -c $(PWD)/nginx.conf -s stop

status:
	ps aux | grep nginx

install: setup
	cd lib/ngx_openresty && \
		./configure --prefix=$(PWD) \
		--with-cc-opt="-O0 -I$(PCRE_LIB)/include" \
		--with-ld-opt="-L$(PCRE_LIB)/lib" \
		--with-luajit  \
		--with-pcre \
		--with-debug \
		--without-http_geo_module \
		--without-http_empty_gif_module \
		--without-mail_pop3_module \
		--without-mail_imap_module \
		--without-mail_smtp_module \
		-j2
	make -C $(PWD)/lib/ngx_openresty
	make -C $(PWD)/lib/ngx_openresty install
	cp lib/libcjson.so $(LUAJIT_DIR)/lib

setup:
	test -d nginx || mkdir nginx
	test -d /tmp/isucon/logs || mkdir -p /tmp/isucon/logs
	test -d /tmp/isucon/run || mkdir -p /tmp/isucon/run
	test -d $(PWD)/db || mkdir $(PWD)/db

__clean:
	test -d $(PWD)/nginx || rm -rf $(PWD)/nginx
	test -d $(PWD)/luajit || rm -rf $(PWD)/luajit
	test -d $(PWD)/lualib || rm -rf $(PWD)/lualib
	test -d $(PWD)/bin || rm -rf $(PWD)/bin

start-redis:
	redis-server redis.conf

