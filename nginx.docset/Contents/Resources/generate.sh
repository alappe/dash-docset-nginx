#!/bin/sh
# Never read this… but it works :-/
DOC_BASE="http://nginx.org/en/docs/";
DOC_DB="docSet.dsidx";
rm -rvf Documents;
mkdir -p Documents/http;
rm -vf ${DOC_DB};
curl -sS -o "tmp_index.html" "$DOC_BASE";
grep "http/ngx_" tmp_index.html | \
	gsed -r "s#^.a href=\"(.*)\">#curl -sS -o 'Documents\/\1' ${DOC_BASE}\1#g" | \
	sh
echo "CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);" | sqlite3 ${DOC_DB};
echo "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);" | sqlite3 ${DOC_DB};
grep "http/ngx_" tmp_index.html | \
	gsed -r "s#^.a href=\"(http/ngx_http_)(\w+)(_module.html)\">#INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (\"\2\", \"Module\", \"\1\2\3\");#g" | sqlite3 ${DOC_DB};
 
for file in $(ls Documents/http/*.html); do
	FILENAME=$(echo ${file} | gsed 's#^Documents/##g');
	echo "FILENAME=${FILENAME}";
	grep -E 'a name="[a-zA-Z_]+">.*class="directive' "$file" | \
		gsed -r "s#^.*name=\"(\w+)\"></a>.*class=\"directive\".*#INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (\"\1\", \"Directive\", \"${FILENAME}\#\1\");#g" | \
		sqlite3 ${DOC_DB};
done
