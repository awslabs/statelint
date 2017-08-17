# Should be run from the root of the repository

ruby -I./lib bin/statelint test/has-dupes.json > /dev/null 2>&1

if [ $? -eq 0 ]; then
	echo "TEST FAILED: 0 returned for invalid JSON file"
	exit 1
fi

ruby -I./lib bin/statelint test/minimal-fail-state.json > /dev/null 2>&1

if [ $? -ne 0 ]; then
	echo "TEST FAILED: 0 not returned for valid JSON file"
	exit 1
fi

echo "Return value test successful"
