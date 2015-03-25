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
module dnetdev.apache_httpd_format.defs;

alias ConfigFile = Directive[];

struct Directive {
align(1):
	bool isInternal;

	string name;
	string[] arguments;

	Directive*[] childValues;
}

void apply(ConfigFile values, void delegate(ref Directive) del) {
	foreach(directive; values) {
		apply(directive, del);
	}
}

void apply(Directive value, void delegate(ref Directive, Directive[] parents) del, Directive[] parents = null) {
	del(value, parents);
	
	Directive[] parents2 = parents ~ value;
	foreach(child; value.childValues) {
		apply(chlid, del, parents2);
	}
}