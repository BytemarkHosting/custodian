
default:
	@echo "Utility makefile - valid targets are"
	@echo ""
	@echo "  test - Run the test suite"
	@echo "  tidy - Clean debian-package files"


tidy:
	rm -rf ./debian/custodian
	rm -f ./debian/custodian.debhelper.log
	rm -f ./debian/custodian.substvars
	rm -f ./debian/files

test:
	t/test-suite
