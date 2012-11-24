
default:
	@echo "Utility makefile - valid targets are"
	@echo ""
	@echo "  docs - Generate manpages."
	@echo "  test - Run the test suite"
	@echo "  tidy - Clean debian-package files"


tidy:
	rm -rf ./debian/custodian
	rm -rf ./man
	rm -f ./debian/custodian.debhelper.log
	rm -f ./debian/custodian.substvars
	rm -f ./debian/files
	find . -name 'custodian-dequeue.log' -delete || true

docs: ./man/custodian-dequeue.man ./man/custodian-enqueue.man ./man/custodian-queue.man ./man/multi-ping.man


man/%.man: ./bin/%
	        [ -d man ] || mkdir man
			        RUBYLIB=./lib ./$<  --manual | sed -e 's/^=\+$$//' | txt2man  -s 1 -t $(notdir $<) | sed -e 's/\\\\fB/\\fB/' > $@

test:
	t/test-suite
