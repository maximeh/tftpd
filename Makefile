basedir = $(shell pwd)
gopath = "$(basedir)/third_party:$(GOPATH)"
cover = $(COVER)

.PNONY: all test deps fmt clean check-gopath

all: check-gopath clean fmt deps test
	@echo "==> Compiling source code (no symbol table nor debug info)."
	@env GOPATH=$(gopath) go build -ldflags="-s" -v -o ./bin/tftpd ./tftpd

race: check-gopath clean fmt deps test
	@echo "==> Compiling source code with race detection enabled."
	@env GOPATH=$(gopath) go build -race -o ./bin/tftpd ./tftpd

test: check-gopath
	@echo "==> Running tests."
	@env GOPATH=$(gopath) go test $(cover) ./tftpd

deps: check-gopath
	@echo "==> Downloading dependencies."
	@env GOPATH=$(gopath) go get -d -v ./tftpd/...
	@echo "==> Removing SCM files from third_party."
	@find ./third_party -type d -name .git | xargs rm -rf
	@find ./third_party -type d -name .bzr | xargs rm -rf
	@find ./third_party -type d -name .hg | xargs rm -rf

fmt:
	@echo "==> Formatting source code."
	@gofmt -w ./tftpd

clean:
	@echo "==> Cleaning up previous builds."
	@rm -rf "$(GOPATH)/pkg" ./third_party/pkg ./bin

check-gopath:
ifndef GOPATH
	$(error GOPATH is undefined)
endif
