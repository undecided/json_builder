# json_builder
Easy, incremental JSON creation in nim.

## Simple usage example:

```
let builder = newJsonObjectBuilder()
builder.add_entry("key", "value")

builder.add_array("key2"):
  builder.add_entry("value")         # entries added here 
  builder.add_entry("value")         # are members of a new array

builder.add_entry("key3", "value")   # now back in the object - so key-value pair land

builder.add_object("key4"):
  builder.add_entry("key", "value")  # child of a new JS object
  
builder.finish()                     # finish() adds the closing bracket
echo builder                         # $builder returns the latest json string
```

For more in-depth usage examples, see json_builder_test.nim

Limitations:
- Cannot handle empty-string keys
- Cannot handle non-string keys
- Cannot handle values other than strings and numbers (calls $ on everything else)
- Very easy to create invalid JSON - very few safeguards here.

## Pull Requests

Pull requests are very welcome!

## License

Released under the MIT License:

The MIT License (MIT)
Copyright (c) 2016 Matthew Bennett-Lovesey

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

