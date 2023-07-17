svg: svg-light svg-dark

svg-light:
	latex -shell-escape diagram-light.tex
	dvisvgm diagram-light.dvi --bbox=-72,-78,495,360 --font-format=woff2,autohint -Oall -o diagram-light.svg
	sed -i -e "0,/width='[^']*'/{s/width='[^']*'/width='100%'/}" -e "0,/height='[^']*'/{s/height='[^']*'/height='100%'/}" diagram-light.svg

svg-dark:
	latex -shell-escape diagram-dark.tex
	dvisvgm diagram-dark.dvi --bbox=-72,-78,495,360 --font-format=woff2,autohint -Oall -o diagram-dark.svg
	sed -i -e "0,/width='[^']*'/{s/width='[^']*'/width='100%'/}" -e "0,/height='[^']*'/{s/height='[^']*'/height='100%'/}" diagram-dark.svg
