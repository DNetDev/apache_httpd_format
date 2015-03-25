# apache_httpd_format
Format reader/writer for Apache httpd configuration.

You will need to handle the directives, including the built in ones yourself. This is only a parser/emitter. Not a full blown reader as it hooks into a web server too heavily.

For more information about the format, take a look at: http://httpd.apache.org/docs/2.4/configuring.html and http://httpd.apache.org/docs/2.4/mod/core.html#ifdefine

## Example reader usage

```D
import dnetdev.apache_httpd_format;
ConfigFile myFile = parseConfigFileText(/* file here (as string) */);

myFile.apply((ref Directive value, Directive[] parents) {
	import std.stdio : writeln;
	writeln(parents.length, " ", value.name);
});
```

## License
MIT