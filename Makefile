PWD=$(shell pwd)
LUAJIT_LIB=$(shell brew --cellar luajit)/2.0.3_1/lib
LUAJIT_INC=$(shell brew --cellar luajit)/2.0.3_1/include/luajit-2.0
NGINX_SRC=$(PWD)/lib/nginx
NGX_DEVEL_KIT=$(PWD)/lib/ngx_devel_kit
LUA_NGINX_MODULE=$(PWD)/lib/lua-nginx-module
PCRE_LIB=/usr/local/opt/pcre
NGINX=$(PWD)/nginx/sbin/nginx

start:
	$(NGINX) -c $(PWD)/nginx.conf

restart:
	$(NGINX) -c $(PWD)/nginx.conf -s reload

stop:
	$(NGINX) -s stop

status:
	ps aux | grep nginx

install:
	cd lib/nginx && ./configure --prefix=$(PWD)/nginx \
		--add-module=$(NGX_DEVEL_KIT) \
		--add-module=$(LUA_NGINX_MODULE) \
		--with-cc-opt="-O0 -I$(PCRE_LIB)/include" \
		--with-ld-opt="-L$(PCRE_LIB)/lib"
	make -C $(NGINX_SRC)
	make -C $(NGINX_SRC) install
