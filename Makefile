ROOT = $(shell pwd)

data/raw/haunted_places.json:
	cd shadowlands_crawler && \
	scrapy crawl shadowlands_places_spider \
	--output-format jsonlines \
	--output $(ROOT)/data/raw/haunted_places.json

data/interim/haunted_places.csv: data/raw/haunted_places.json
	jq --sort-keys '.' data/raw/haunted_places.json | \
	mlr --ijson --ocsv cat > \
		data/interim/haunted_places.csv

data/interim/location_cache.csv: data/interim/haunted_places.csv
	python scripts/haunted_places_geocoder.py \
		data/interim/haunted_places.csv \
		--cache-file data/interim/location_cache.csv | \
		slamdring --num-tasks 10 --no-repeat-request >> \
		data/interim/location_cache.csv

data/interim/city_cache.csv: data/interim/haunted_places.csv
	python scripts/haunted_cities_geocoder.py \
		data/interim/haunted_places.csv \
		--cache-file data/interim/city_cache.csv | \
		slamdring --num-tasks 10 --no-repeat-request >> \
		data/interim/city_cache.csv

data/processed/haunted_places.csv: data/interim/haunted_places.csv data/interim/location_cache.csv data/interim/city_cache.csv
	python scripts/process_haunted_places.py \
		data/interim/haunted_places.csv \
		data/interim/location_cache.csv \
		data/interim/city_cache.csv \
		--output-file data/processed/haunted_places.csv