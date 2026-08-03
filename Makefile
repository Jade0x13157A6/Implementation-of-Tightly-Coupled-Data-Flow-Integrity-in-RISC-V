.PHONY: test clean

test:
	./scripts/run_verilator.sh

clean:
	rm -rf build
