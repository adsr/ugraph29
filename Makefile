prefix?=/usr/local

ugraph29_cflags:=-std=c99 -Wall -Wextra -pedantic -g -O0 $(CFLAGS)
ugraph29_h:=ugraph29.h
ugraph29_o:=ugraph29.o
ugraph29_so_version_abi:=1
ugraph29_so_version_minor_patch:=0.0
ugraph29_so:=libugraph29.so
ugraph29_so_x:=$(ugraph29_so).$(ugraph29_so_version_abi)
ugraph29_so_x_y_z:=$(ugraph29_so_x).$(ugraph29_so_version_minor_patch)
ugraph29_ld_soname:=soname
ugraph29_a:=libugraph29.a
ugraph29_test:=ugraph29_test

ifeq ($(shell $(CC) -dumpmachine | grep -q apple && echo 1), 1)
    ugraph29_so:=libugraph29.dylib
    ugraph29_so_x:=libugraph29.$(ugraph29_so_version_abi).dylib
    ugraph29_so_x_y_z:=libugraph29.$(ugraph29_so_version_abi).$(ugraph29_so_version_minor_patch).dylib
    ugraph29_ld_soname:=install_name
endif

all: $(ugraph29_so) $(ugraph29_so_x) $(ugraph29_a) $(ugraph29_test)

$(ugraph29_o): $(ugraph29_h)
	$(CC) -DUGRAPH29_IMPL -fPIC -xc -c $(ugraph29_cflags) $(ugraph29_h) -o $@

$(ugraph29_so_x_y_z): $(ugraph29_o)
	$(CC) -shared -Wl,-$(ugraph29_ld_soname),$(ugraph29_so_x) $(ugraph29_o) -o $@

$(ugraph29_so_x): $(ugraph29_so_x_y_z)
	ln -sf $(ugraph29_so_x_y_z) $@

$(ugraph29_so): $(ugraph29_so_x_y_z)
	ln -sf $(ugraph29_so_x_y_z) $@

$(ugraph29_a): $(ugraph29_o)
	$(AR) rcs $@ $(ugraph29_o)

$(ugraph29_test): $(ugraph29_h) test.c
	$(CC) -DUGRAPH29_IMPL $(ugraph29_cflags) -I. test.c -o $@

test: $(ugraph29_test)
	./$(ugraph29_test)

codegen:
	awk -vg=0 'g==0{print} /BEGIN codegen/{g=1; system("./codegen.php")} /END codegen/{g=0; print} g==1{next}' ugraph29.h >ugraph29.h.tmp && mv -vf ugraph29.h.tmp ugraph29.h

format:
	clang-format -i ugraph29.h

install:
	$(MAKE) install_h

lib:
	$(MAKE) $(ugraph29_a)
	$(MAKE) $(ugraph29_so)

install_lib:
	$(MAKE) install_a
	$(MAKE) install_so

install_h: $(ugraph29_h)
	install -d $(DESTDIR)$(prefix)/include
	install -p -m 644 $(ugraph29_h) $(DESTDIR)$(prefix)/include/$(ugraph29_h)

install_a: $(ugraph29_a)
	install -d $(DESTDIR)$(prefix)/lib
	install -p -m 644 $(ugraph29_a) $(DESTDIR)$(prefix)/lib/$(ugraph29_a)

install_so: $(ugraph29_so_x_y_z)
	install -d $(DESTDIR)$(prefix)/lib
	install -p -m 755 $(ugraph29_so_x_y_z) $(DESTDIR)$(prefix)/lib/$(ugraph29_so_x_y_z)
	ln -sf $(ugraph29_so_x_y_z) $(DESTDIR)$(prefix)/lib/$(ugraph29_so_x)
	ln -sf $(ugraph29_so_x_y_z) $(DESTDIR)$(prefix)/lib/$(ugraph29_so)

clean:
	rm -f $(ugraph29_o) $(ugraph29_a) $(ugraph29_so) $(ugraph29_so_x) $(ugraph29_so_x_y_z) $(ugraph29_test)

.PHONY: all test codegen format install lib install_lib install_h install_a install_so clean
