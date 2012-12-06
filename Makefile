
default:
	@echo "Utility makefile - valid targets are"
	@echo ""
	@echo "  clean - Clean debian-package files"
	@echo "  docs  - Generate manpages."
	@echo "  test  - Run the test suite"


clean:
	rm -rf ./debian/custodian ./debian/custodian-bytemark
	rm -rf ./man
	rm -f ./debian/*.debhelper.log
	rm -f ./debian/*.substvars
	rm -f ./debian/files
	find . -name 'custodian-dequeue.log' -delete || true
	find . -name 'alerts.log' -delete || true

docs: ./man/custodian-dequeue.man ./man/custodian-enqueue.man ./man/custodian-queue.man ./man/multi-ping.man


man/%.man: ./bin/%
	        [ -d man ] || mkdir man
			        RUBYLIB=./lib ./$<  --manual | sed -e 's/^=\+$$//' | txt2man  -s 1 -t $(notdir $<) | sed -e 's/\\\\fB/\\fB/' > $@

test:
	t/test-suite
