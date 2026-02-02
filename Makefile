# kcl-ccm Makefile
# Install kcl-ccm to /usr/local/bin (or PREFIX/bin)

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

.PHONY: install uninstall test help

install:
	install -d "$(BINDIR)"
	install -m 755 01_scripts/kcl-ccm "$(BINDIR)/kcl-ccm"

uninstall:
	rm -f "$(BINDIR)/kcl-ccm"

test:
	./01_scripts/kcl-ccm --manifest-root ./02_example/kcl --output-kustomize ./02_example/kcl --output-runtime-config ./02_example/crossplane --namespace default
	@echo "Generated files:"
	@ls -la 02_example/kcl/kustomization.yaml 02_example/crossplane/runtime-config.yaml

help:
	@echo "kcl-ccm Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make install   - Install kcl-ccm to $(BINDIR)"
	@echo "  make uninstall - Remove kcl-ccm from $(BINDIR)"
	@echo "  make test      - Run kcl-ccm on 02_example/kcl"
	@echo "  make help      - Show this help"
