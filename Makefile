watch:
	$(MAKE) -C themes/anatole-zola watch & zola serve & npx tailwindcss -o public/blog.tailwind.css -i src/style.css --watch=always

release:
	$(MAKE) -C themes/anatole-zola release
	zola build
	npx tailwindcss -o public/blog.tailwind.css -i src/style.css --minify
