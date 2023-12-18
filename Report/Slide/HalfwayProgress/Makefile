all: slide

slide:
	pandoc \
	-tbeamer \
	--pdf-engine=xelatex \
	--defaults='build_config.yaml' \
	--metadata date="`date +%d/%m/%Y`" \
	-o output.pdf \

clean:
	rm -r output.*
