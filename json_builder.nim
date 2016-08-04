## This module attempts to solve the problem of easy, incremental
## JSON creation.
##
## Simple usage example:
##
## .. code-block:: nim
##  let builder = newJsonObjectBuilder()
##  builder.add_entry("key", "value") # only deals with strings so far
##  builder.add_array("key"):
##
## Limitations:
## - Cannot handle empty-string keys
## - Cannot handle non-string keys
## - Cannot handle values other than strings and numbers (calls $ on everything else)



import strutils
import sequtils
import json # Only used for escapeJson

### Private Utility Methods

proc optionallyEscapeJson[T](value:T): string =
  if (T is SomeNumber):
    result = $value
  else:
    result = escapeJson($value)

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

### JsonBuilder

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
    builder.output &= optionallyEscapeJson(key)
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

proc is_array_context*(builder: var JsonBuilder): bool =
  builder.terminator_stack.last() == "]"

template add_array*(builder: var JsonBuilder, key, code: untyped): untyped =
  builder.open(key, "[")
  code
  builder.close()

template add_array*(builder: var JsonBuilder, code: untyped): untyped =
  ## Fixes an odd bug with empty keys
  builder.add_array("", code)

template add_object*(builder: var JsonBuilder, key = "", code: untyped): untyped =
  builder.open(key, "{")
  code
  builder.close()

proc array_entry*[T](builder: var JsonBuilder, item: T) =
  builder.indent()
  builder.output &= optionallyEscapeJson(item)
  builder.comma()

proc object_entry*[T](builder: var JsonBuilder, key: string, value: T) =
  builder.indent()
  builder.output &= optionallyEscapeJson(key)
  builder.colon()
  builder.output &= optionallyEscapeJson(value)
  builder.comma()


proc add_entry*[T](builder: var JsonBuilder, value: T) {.raises: [InvalidEntryError] .} =
  if not builder.is_array_context():
    raise newException(InvalidEntryError, "No value given; Both key and value required for an entry to an object")
  builder.array_entry value

proc add_entry*[T](builder: var JsonBuilder, key: string, value: T) {.raises: [InvalidEntryError] .} =
  if builder.is_array_context():
    raise newException(InvalidEntryError, "Provided key and value; only value required when an entry to an array")
  builder.object_entry key, value



