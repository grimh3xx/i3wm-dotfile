# UndergroundI3
.PHONY: help lint test dry-run install doctor

help:
	@echo "make lint     shellcheck em tudo"
	@echo "make test     testes num \$$HOME temporário"
	@echo "make dry-run  mostra o que o 'install full' faria"
	@echo "make install  link do comando em ~/.local/bin/underground-i3"
	@echo "make doctor   confere a instalação"

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
