ifeq ($(CC),cc)
CC = clang
endif

TESTS=main\
main2

ifeq ($(CC),gcc)
CFLAGS = -fprofile-arcs -ftest-coverage
LDFLAGS = -lgcov
COVERAGE_FILES=$(patsubst %,%.gcda,$(TESTS))
define generate_coverage
coverage.info: $(COVERAGE_FILES)
	lcov --capture --directory . --output-file $$@
endef

else ifeq ($(CC),clang)
CFLAGS = -fprofile-instr-generate -fcoverage-mapping
LDFLAGS = -fprofile-instr-generate -fcoverage-mapping
COVERAGE_FILES=$(patsubst %,%.profraw,$(TESTS))
define generate_coverage
coverage.info: $(COVERAGE_FILES)
	llvm-profdata merge -output=merge.profdata $$^
	llvm-cov export --format=lcov -instr-profile=merge.profdata $(addprefix -object , $(TESTS)) > $$@
endef
else
$(error "Unsupported compiler")
endif

ALL: clean lcov-report

$(eval $(call generate_coverage))

lcov-report: coverage.info
	genhtml -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(TESTS): %: %.o
	$(CC) $^ $(LDFLAGS) -o $@

%.gcda: %
	./$<
%.profraw: %
	LLVM_PROFILE_FILE=$@ ./$<

clean:
	rm -rvf $(EXE) *.o *.gcno *.gcda *.profraw *.profdata coverage.info lcov-report/
