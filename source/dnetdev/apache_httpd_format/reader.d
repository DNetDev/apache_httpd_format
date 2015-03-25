/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 Richard Andrew Cattermole
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module dnetdev.apache_httpd_format.reader;
import dnetdev.apache_httpd_format.defs;

ConfigFile parseConfigFileText(string text) {
	import std.algorithm : startsWith, count;
	import std.string : strip, toLower;

	ConfigFile ret;
	size_t realLineCount;
	size_t offset;

	ret.length = text.count('\n'); // block allocate. One instance per line.

	Directive*[] parents;

	while (offset < text.length) {
		string readLine() {
			string ret;
			bool gotDash;
			bool gotNewLine;

			for(; offset < text.length; offset++) {
				if (text[offset] == '\n' || text[offset] == '\r') {
					if (gotDash) {
					} else {
						if (ret.length == 0)
							continue;
						else
							break;
					}

					gotNewLine = true;
				} else if (text[offset] == '\\') {
					ret ~= '\\';
					gotDash = true;
					gotNewLine = false;
				} else {
					if (gotDash && gotNewLine)
						ret.length--;

					ret ~= text[offset];

					gotDash = false;
					gotNewLine = false;
				}
			}

			return ret;
		}

		string line = readLine().strip;

		Directive* getNext() {
			if (parents.length > 0) {
				auto ret = new Directive();
				parents[$-1].childValues ~= ret;
				return ret;
			} else {
				realLineCount++;
				return &ret[realLineCount-1];
			}
		}

		string unescape(string text) {
			bool gotDash;
			string ret;

			foreach(const c; text) {
				if (c == '\\' && !gotDash) {
					gotDash = true;
					ret ~= c;
				} else if (gotDash && (c == '\'' || c == '"' || c == '?' || c == '\\')) {
					ret.length--;
					ret ~= c;
					gotDash = false;
				} else if (gotDash && c == '0') {
					ret.length--;
					ret ~= '\0';
					gotDash = false;
				} else if (gotDash && c == 'a') {
					ret.length--;
					ret ~= '\a';
					gotDash = false;
				} else if (gotDash && c == 'b') {
					ret.length--;
					ret ~= '\b';
					gotDash = false;
				} else if (gotDash && c == 'f') {
					ret.length--;
					ret ~= '\f';
					gotDash = false;
				} else if (gotDash && c == 'n') {
					ret.length--;
					ret ~= '\n';
					gotDash = false;
				} else if (gotDash && c == 'r') {
					ret.length--;
					ret ~= '\r';
					gotDash = false;
				} else if (gotDash && c == 't') {
					ret.length--;
					ret ~= '\t';
					gotDash = false;
				} else if (gotDash && c == 'v') {
					ret.length--;
					ret ~= '\v';
					gotDash = false;
				} else {
					gotDash = false;
					ret ~= c;
				}
			}

			return ret;
		}

		string[] splitSmart(string text) {
			string[] ret;
			string t;

			bool isQuoted;
			bool wasQuoted;
			bool wasDash;

			foreach(const c; text) {
				if (c == '"' && !wasDash) {
					isQuoted = !isQuoted;

					if (isQuoted)
						wasQuoted = true;
				} else if (c == ' ' && !isQuoted) {
					isQuoted = false;

					if (wasQuoted)
						ret ~= unescape(t);
					else
						ret ~= t;

					t = null;

					wasQuoted = false;
				} else {
					t ~= c;
				}

				if (c == '\\')
					wasDash = true;
				else
					wasDash = false;
			}

			if (t.length > 0) {
				if (wasQuoted) {
					ret ~= unescape(t);
				} else
					ret ~= t;
			}

			return ret;
		}

		if (line.length == 0 || line.startsWith("#")) {
			// no processing required
		} else if (line.startsWith("</")) {
			if (parents.length > 0) {
				assert(parents[$-1].name == splitSmart(line)[0][2 .. $-1].toLower);

				parents.length--;
			} else {
				assert(0);
			}
		} else if (line.startsWith("<")) {
			// internal need to parse special
			auto v = getNext();
			auto values = splitSmart(line);
			assert(values.length > 0);
			
			v.isInternal = true;

			v.name = values[0][1 .. $].toLower;
			if (values.length > 2)
				v.arguments = values[1 .. $] ~ values[$-1][0 .. $-1];
			else if (values.length > 1)
				v.arguments = [values[1][0 .. $-1]];

			parents ~= v;
		} else {
			// parse dumb (string split)
			auto v = getNext();
			auto values = splitSmart(line);
			assert(values.length > 0);

			//v.isInternal = false; // is initiated as false anyway.
			v.name = values[0].toLower;
			v.arguments = values[1 .. $];
		}
	}

	ret.length = realLineCount;
	return ret;
}

unittest {
	ConfigFile cf = parseConfigFileText("""
#
# This is the header for the unittest
#

# listen on some port

Listen 80

# load some modules

LoadModule name modules/mod.so

# check for module

<IfModule unixd_module>

# load some module specific data

User daemon
    Group daemon

</IfModule>

ServerAdmin admin@example.com

#ServerName www.example.com:80

# A specified directory!
<Directory />
# set some info

\tAllowOverride none
  Require all denied
</Directory>

DocumentRoot \"c:/server/htdocs\"

# global settings

<Files \".ht*\">
    Require all denied
</Files>

Include configs/something.conf
Include configs/another.md

LongCode here \\
yup

EncodeTest \"something \\\\ another \"
""");

	assert(cf.length == 11);
	test(cf, 0, false, "listen", "80");
	test(cf, 1, false, "loadmodule", "name", "modules/mod.so");

	test(cf, 2, true, "ifmodule", "unixd_module");
	assert(cf[2].childValues.length == 2);
	test(cf, 2, 0, false, "user", "daemon");
	test(cf, 2, 1, false, "group", "daemon");

	test(cf, 3, false, "serveradmin", "admin@example.com");

	test(cf, 4, true, "directory", "/");
	assert(cf[4].childValues.length == 2);
	test(cf, 4, 0, false, "allowoverride", "none");
	test(cf, 4, 1, false, "require", "all", "denied");

	test(cf, 5, false, "documentroot", "c:/server/htdocs");

	test(cf, 6, true, "files", ".ht*");
	assert(cf[6].childValues.length == 1);
	test(cf, 6, 0, false, "require", "all", "denied");

	test(cf, 7, false, "include", "configs/something.conf");
	test(cf, 8, false, "include", "configs/another.md");
	test(cf, 9, false, "longcode", "here", "yup");
	test(cf, 10, false, "encodetest", "something \\ another ");
}

private {
	void test(ConfigFile ctx, size_t i, bool isInternal, string name, string[] arguments...) {
		assert(ctx.length > i);
		assert(ctx[i].isInternal == isInternal);
		assert(ctx[i].name == name);
		assert(ctx[i].arguments.length == arguments.length);

		foreach(j, arg; arguments) {
			assert(ctx[i].arguments[j] == arg);
		}
	}

	void test(ConfigFile ctx, size_t i, size_t k, bool isInternal, string name, string[] arguments...) {
		assert(ctx.length > i);
		assert(ctx[i].childValues.length > k);

		assert(ctx[i].childValues[k].isInternal == isInternal);
		assert(ctx[i].childValues[k].name == name);
		assert(ctx[i].childValues[k].arguments.length == arguments.length);
		
		foreach(j, arg; arguments) {
			assert(ctx[i].childValues[k].arguments[j] == arg);
		}
	}
}