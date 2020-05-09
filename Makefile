.PHONY: build
build:
	dune build

.PHONY: test
test:
	dune exec src/test/test_tsort.exe

.PHONY: install
install:
	dune install

.PHONY: clean
clean:
	dune clean
