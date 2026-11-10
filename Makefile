# i3wm-dotfile
.PHONY: help lint test dry-run install doctor

help:
	@echo "make lint     shellcheck everything"
	@echo "make test     run the tests in a throwaway \$$HOME"
	@echo "make dry-run  show what 'install full' would do"
	@echo "make install  link the command into ~/.local/bin/underground-i3"
	@echo "make doctor   check the install"

lint:
	shellcheck -x underground-i3 lib/*.sh st/st-urls
	shellcheck -S warning dotfiles/.config/i3/scripts/*.sh dotfiles/.config/i3blocks/scripts/* \
		dotfiles/.config/fastfetch/logo.sh dotfiles/.config/lf/preview

test:
	bash tests/run.sh

dry-run:
	./underground-i3 --dry-run --yes install full

install:
	install -d $(HOME)/.local/bin
	ln -sfn $(CURDIR)/underground-i3 $(HOME)/.local/bin/underground-i3

doctor:
	./underground-i3 doctor
