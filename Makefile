.PHONY: build
build:
	dune build

.PHONY: test-esy
test-esy:
	docker build -f Dockerfile.esy -t tsort-esy .

.PHONY: test
test:
	dune exec src/test/test_tsort.exe

.PHONY: test-complete
test-complete: test test-esy

.PHONY: install
install:
	dune install

.PHONY: clean
clean:
	dune clean
