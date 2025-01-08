compress:
	find data -name '*.csv' -print | xargs bzip2
