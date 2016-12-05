export DESTDIR ?=
export BINDIR ?= /usr/bin

BASEDIR = $(shell pwd)
MYGOPATH = "$(BASEDIR)/third_party:$(GOPATH)"

.PNONY: all test deps fmt clean install check-gopath

all: check-gopath clean fmt deps test
	@echo "==> Compiling source code (no symbol table nor debug info)."
	@env GOPATH=$(MYGOPATH) go build -ldflags="-s" -v -o ./bin/tftpd ./tftpd

race: check-gopath clean fmt deps test
	@echo "==> Compiling source code with race detection enabled."
	@env GOPATH=$(MYGOPATH) go build -race -o ./bin/tftpd ./tftpd

test: check-gopath
	@echo "==> Running tests."
	@env GOPATH=$(MYGOPATH) go test $(COVER) ./tftpd

deps: check-gopath
	@echo "==> Downloading dependencies."
	@env GOPATH=$(MYGOPATH) go get -d -v ./tftpd/...
	@echo "==> Removing SCM files from third_party."
	@find ./third_party -type d -name .git | xargs rm -rf
	@find ./third_party -type d -name .bzr | xargs rm -rf
	@find ./third_party -type d -name .hg | xargs rm -rf

fmt:
	@echo "==> Formatting source code."
	@gofmt -w ./tftpd

clean:
	@echo "==> Cleaning up previous builds."
	@rm -rf "$(MYGOPATH)/pkg" ./third_party/pkg ./bin

install:
	@echo "==> Installing tftpd to $(DESTDIR)$(BINDIR)/tftpd."
	@mkdir -p $(DESTDIR)$(BINDIR)
	@cp ./bin/tftpd $(DESTDIR)$(BINDIR)/tftpd
	@sudo chown root:root $(DESTDIR)$(BINDIR)/tftpd
	@sudo chmod 04755 $(DESTDIR)$(BINDIR)/tftpd

check-gopath:
ifndef GOPATH
	$(error GOPATH is undefined)
endif
