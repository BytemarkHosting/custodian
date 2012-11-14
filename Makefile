
default:
	@echo "Utility makefile - valid targets are"
	@echo ""
	@echo "  test - Run the test suite"
	@echo " clean - Clean debian-package files"


clean:
	rm -rf ./debian/custodian
	rm -f ./debian/custodian.debhelper.log
	rm -f ./debian/custodian.substvars
	rm -f ./debian/files

test:
	t/test-suite
