PWD=$(shell pwd)
LUAJIT_LIB=$(shell brew --cellar luajit)/2.0.3_1/lib
LUAJIT_INC=$(shell brew --cellar luajit)/2.0.3_1/include/luajit-2.0
NGINX_SRC=$(PWD)/lib/nginx
NGX_DEVEL_KIT=$(PWD)/lib/ngx_devel_kit
LUA_NGINX_MODULE=$(PWD)/lib/lua-nginx-module
PCRE_LIB=$(shell brew --cellar pcre)/8.36

ENV=$(shell echo LUAJIT_LIB=$(LUAJIT_LIB) LUAJIT_INC=$(LUAJIT_INC))
NGINX=$(PWD)/nginx/sbin/nginx

start:
	$(ENV) && $(NGINX) -c $(PWD)/nginx/nginx.conf

restart:
	$(ENV) && $(NGINX) -c $(PWD)/nginx/nginx.conf -s reload

stop:
	$(ENV) && $(NGINX) -c $(PWD)/nginx/nginx.conf -s stop || pkill nginx

status:
	ps aux | grep nginx

install: setup
	$(ENV) && cd lib/nginx && ./configure --prefix=$(PWD)/nginx \
		--add-module=$(NGX_DEVEL_KIT) \
		--add-module=$(LUA_NGINX_MODULE) \
		--add-module=$(OPENRESTY_MODULE) \
		--with-cc-opt="-O0 -I$(PCRE_LIB)/include" \
		--with-ld-opt="-L$(PCRE_LIB)/lib"
	$(ENV) && make -C $(NGINX_SRC)
	$(ENV) && make -C $(NGINX_SRC) install

install-openresty: setup
	$(ENV) && cd lib/ngx_openresty && \
		./configure --prefix=$(PWD)/nginx \
		--with-cc-opt="-O0 -I$(PCRE_LIB)/include" \
		--with-ld-opt="-L$(PCRE_LIB)/lib" \
		--with-luajit  \
		-j2
	$(ENV) && make -C $(PWD)/lib/ngx_openresty
	$(ENV) && make -C $(PWD)/lib/ngx_openresty install

setup:
	test -d nginx || mkdir nginx

clean-all:
	test -d $(PWD)/nginx || rm -rf $(PWD)/nginx

redis-start:
	redis-server redis.conf

