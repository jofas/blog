svg:
	latex -shell-escape diagram.tex
	dvisvgm diagram.dvi --bbox=-72,-78,495,360 --font-format=woff2,autohint -Oall -o diagram.svg
	sed -i -e "0,/width='[^']*'/{s/width='[^']*'/width='100%'/}" -e "0,/height='[^']*'/{s/height='[^']*'/height='100%'/}" diagram.svg
