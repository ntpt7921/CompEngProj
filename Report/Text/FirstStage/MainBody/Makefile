all: pdf latex-full

pdf:
	pandoc \
	-tpdf \
	--pdf-engine=xelatex \
	--defaults='build_config.yaml' \
	--metadata date="`date +%d/%m/%Y`" \
	--template "custom_template.latex" \
	-o output.pdf \

latex-full:
	pandoc \
	-tlatex \
	--defaults='build_config.yaml' \
	--metadata date="`date +%d/%m/%Y`" \
	--template "custom_template.latex" \
	-s \
	-o output.tex \

latex-bare:
	pandoc \
	-tlatex \
	--defaults='build_config.yaml' \
	--metadata date="`date +%d/%m/%Y`" \
	-o output.tex \

clean:
	rm -r output.*
