# OBI Experiment
# James A. Overton <james@overton.ca>
#
# https://github.com/jamesaoverton/obi-experiment

# List all the automatically generated files
BUILD = glucose.ttl glucose.txt glucose-terms.txt glucose-ontology.txt glucose-individual.txt

# List other generated files that we don't need
JUNK = catalog-v001.xml

# Default target: make all generated files
all: $(BUILD)

# Clean all generated files
clean:
	rm -f $(BUILD) $(JUNK)

# Extract indented lines, then remove indent
glucose.txt: glucose.md
	cat $^ \
	| grep "^    " \
	| sed 's/^    //' \
	> $@

# Split on colons, trim leading whitespace, remove blank lines,
# remove 'type' and numbers, then sort uniquely
glucose-terms.txt: glucose.txt
	cat $^ \
	| tr : '\n' \
	| sed 's/^ *//' \
	| grep -v '^$$' \
	| grep -v 'type' \
	| grep -v '^[0-9]*$$' \
	| sort \
	| uniq \
	> $@

FINALDIGIT = -e '[0-9]$$'

# Extract lines that do not end in numerals
glucose-ontology.txt: glucose-terms.txt
	grep -v $(FINALDIGIT) $^ > $@

# Extract lines that end in numerals
glucose-individual.txt: glucose-terms.txt
	grep $(FINALDIGIT) $^ > $@

# Convert to Turtle format using the `replace` script
glucose.ttl: glucose.txt glucose.tsv prefixes.ttl
	python src/replace glucose.tsv glucose.txt \
	| cat prefixes.ttl - \
	> $@

