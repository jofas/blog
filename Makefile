watch:
	$(MAKE) -C themes/anatole-zola watch
	zola serve

release:
	$(MAKE) -C themes/anatole-zola release
	zola build
