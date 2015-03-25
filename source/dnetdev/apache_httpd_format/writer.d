/**
 * Implements a writer for Apache httpd configuration format.
 * 
 * This module has not been tested.
 * 
 * License:
 *     The MIT License (MIT)
 *
 *     Copyright (c) 2015 Richard Andrew Cattermole
 *
 *     Permission is hereby granted, free of charge, to any person obtaining a copy
 *     of this software and associated documentation files (the "Software"), to deal
 *     in the Software without restriction, including without limitation the rights
 *     to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *     copies of the Software, and to permit persons to whom the Software is
 *     furnished to do so, subject to the following conditions:
 *
 *     The above copyright notice and this permission notice shall be included in all
 *     copies or substantial portions of the Software.
 *
 *     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *     SOFTWARE.
 */
module dnetdev.apache_httpd_format.writer;
import dnetdev.apache_httpd_format.defs;

private {
	import std.range : isOutputRange, ElementType;

	static char[1024] indentText = 
[' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',
' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '];
}

struct WriteState(RoR) if (isOutputRange!RoR && is(ElementType!RoR == string)) {
	private {
		ubyte indent;

		RoR range;
	}

	this(RoR range) {
		this.range = range;
	}

	void emitComment(string text) {
		range.put(cast(string)indentText[indent * 4 .. (indent * 4) + 4]);
		range.put("# ");
		range.put(text);
		range.put("\n");
	}

	void emit(bool internal, string name, string[] arguments...) {
		import std.algorithm : canFind;
		assert(indent < 255);

		range.put(cast(string)indentText[indent * 4 .. (indent * 4) + 4]);

		if (internal)
			range.put("<");

		range.put(name);

		foreach(const arg; arguments) {
			range.put(" ");

			if (arg.canFind(" ") || arg.canFind("\\")) {
				range.put("\"");

				foreach(const c; arg) {
					if (c == '\'' || c == '"' || c == '?' || c == '\\') {
						range.put("\\");
						range.put(c);
					} else if (c == '\0') {
						range.put("\\0");
					} else if (gotDash && c == '\a') {
						range.put("\\a");
					} else if (gotDash && c == '\b') {
						range.put("\\b");
					} else if (gotDash && c == '\f') {
						range.put("\\f");
					} else if (gotDash && c == '\n') {
						range.put("\\n");
					} else if (gotDash && c == '\r') {
						range.put("\\r");
					} else if (gotDash && c == '\t') {
						range.put("\\t");
					} else if (gotDash && c == '\v') {
						range.put("\\v");
					} else {
						range.put(cast(string)[c]);
					}
				}

				range.put("\"");
			} else {
				range.put(arg);
			}
		}

		if (internal)
			range.put(">");
		range.put("\n");

		indent++;
	}

	void emitInternalEnd(string name) {
		assert(indent > 0);

		range.put("</");
		range.put(name);
		range.put(">\n");

		indent--;
	}

	void emitFrom(Directive value) {
		emit(value.isInternal, value.name, value.arguments);

		if (value.isInternal) {
			foreach(child; value.childValues) {
				emitFrom(child);
			}

			emitInternalEnd(value.name);
		}
	}

	void emitFrom(ConfigFile values) {
		foreach(value; values) {
			emitFrom(value);
		}
	}
}