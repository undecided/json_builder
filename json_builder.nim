## This module attempts to solve the problem of easy, incremental
## JSON creation.


## parser. JSON (JavaScript Object Notation) is a lightweight
## data-interchange format that is easy for humans to read and write
## (unlike XML). It is easy for machines to parse and generate.
## JSON is based on a subset of the JavaScript Programming Language,
## Standard ECMA-262 3rd Edition - December 1999.
##
## Usage example:
##
## .. code-block:: nim
##  let
##    small_json = """{"test": 1.3, "key2": true}"""
##    jobj = parseJson(small_json)
##  assert (jobj.kind == JObject)
##  echo($jobj["test"].fnum)
##  echo($jobj["key2"].bval)
##
## Results in:
##
## .. code-block:: nim
##
##   1.3000000000000000e+00
##   true
##
## This module can also be used to comfortably create JSON using the `%*`
## operator:
##
## .. code-block:: nim
##
##   var hisName = "John"
##   let herAge = 31
##   var j = %*
##     [
##       {
##         "name": hisName,
##         "age": 30
##       },
##       {
##         "name": "Susan",
##         "age": herAge
##       }
##     ]
##
##    var j2 = %* {"name": "Isaac", "books": ["Robot Dreams"]}
##    j2["details"] = %* {"age":35, "pi":3.1415}
##    echo j2


import strutils
import sequtils
import json # Only used for escapeJson

### Internal Utility Methods

proc closer_for(opener = "{"): string =
  if opener == "{":
    result = "}"
  elif opener == "[":
    result = "]"
  else:
    result = "" # TODO: unknown error?

proc last[T](s: seq[T]): T =
  ## Why is this not part of sequtils?
  s[s.len-1]

### External JsonBuilder

type JsonBuilder* = tuple[output: string, terminator_stack: seq[string], flags: set[char]]

type InvalidEntryError* = object of Exception

var levels = newSeq[string]()

proc `$`*(builder: JsonBuilder): string =
  builder.output

proc is_compact(builder: var JsonBuilder): bool =
  'c' in builder.flags

proc indent(builder: var JsonBuilder) =
  if builder.is_compact():
    return
  if builder.output != "":
    builder.output &= "\n"
  builder.output &= "  ".repeat(builder.terminator_stack.len)


proc comma(builder: var JsonBuilder) =
  if builder.output.rfind("{") != builder.output.len - 1 and
    builder.output.rfind("[") != builder.output.len - 1:
    builder.output &= ","

proc colon(builder: var JsonBuilder) =
  if builder.is_compact():
    builder.output &= ":"
  else:
    builder.output &= ": "


proc open(builder: var JsonBuilder, key = "", opener = "{") =
  builder.indent()
  if key != "" :
    builder.output &= escapeJson(key)
    builder.colon()
  builder.terminator_stack.add closer_for(opener)
  builder.output &= opener

proc close(builder: var JsonBuilder) =
  if builder.output.rfind(",") == builder.output.len - 1:
    builder.output.removeSuffix(',')
  let x = builder.terminator_stack.pop()
  builder.indent()
  builder.output &= x
  if builder.terminator_stack.len > 0:
    builder.comma()

proc finish*(builder: var JsonBuilder) =
  while builder.terminator_stack.len > 0:
    builder.close()


proc newJsonBuilder*(opener = "{", flags: set[char] = {}):JsonBuilder =
  result = (output: "", terminator_stack: @[], flags: flags)
  result.open("", opener)


proc newJsonObjectBuilder*():JsonBuilder =
  newJsonBuilder("{")

proc newCompactJsonObjectBuilder*():JsonBuilder =
  newJsonBuilder("{", {'c'})

template add_array*(builder: var JsonBuilder, key = "", code: untyped): untyped =
  builder.open(key, "[")
  code
  builder.close()

proc array_entry*(builder: var JsonBuilder, item: string) =
  builder.indent()
  builder.output &= escapeJson(item)
  builder.comma()

template add_object*(builder: var JsonBuilder, key = "", code: untyped): untyped =
  builder.open(key, "{")
  code
  builder.close()

proc object_entry*(builder: var JsonBuilder, key, value: string) =
  builder.indent()
  builder.output &= escapeJson(key)
  builder.colon()
  builder.output &= escapeJson(value)
  builder.comma()

proc is_in_array*(builder: var JsonBuilder): bool =
  builder.terminator_stack.last() == "]"

proc add_entry*(builder: var JsonBuilder, kv: varargs[string]) {.raises: [InvalidEntryError] .} =
  if builder.is_in_array():
    builder.array_entry kv[0]
  else:
    builder.object_entry kv[0], kv[1]

