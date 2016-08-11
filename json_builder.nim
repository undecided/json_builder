## This module attempts to solve the problem of easy, incremental
## JSON creation.
##
## Simple usage example:
##
## .. code-block:: nim
##  let builder = newJsonObjectBuilder()
##  builder.add_entry("key", "value")
##  builder.add_array("key2"):
##    # entries added here are members of a new array
##    builder.add_entry("value")
##    builder.add_entry("value")
##  # now back in the object - so key-value pair land
##  builder.add_entry("key3", "value")
##  builder.add_object("key4"):
##    # entries added here are children of a new JS object
##    builder.add_entry("key", "value")
##  builder.finish() # adds the closing }
##  echo builder # $builder produces the current json string
##
## For more in-depth usage examples, see json_builder_test.nim
##
## Limitations:
## - Cannot handle empty-string keys
## - Cannot handle non-string keys
## - Cannot handle values other than strings and numbers (calls $ on everything else)
## - Very easy to create invalid JSON - very few safeguards here.

import strutils
import sequtils
import json # Only used for escapeJson

# ===== Private Utility Methods =====

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

# ===== JsonBuilder Types =====

type JsonBuilder* = tuple[output: string, terminator_stack: seq[string], flags: set[char]]

type InvalidEntryError* = object of Exception

# ===== Private Methods =====

proc skip_comma_spacing(builder: var JsonBuilder): bool =
  ',' in builder.flags

proc skip_colon_spacing(builder: var JsonBuilder): bool =
  ':' in builder.flags

proc skip_bracket_spacing(builder: var JsonBuilder): bool =
  '{' in builder.flags

proc indent(builder: var JsonBuilder) =
  if builder.output != "":
    builder.output &= "\n"
    builder.output &= "  ".repeat(builder.terminator_stack.len)

proc comma(builder: var JsonBuilder) =
  if builder.output.rfind("{") != builder.output.len - 1 and
    builder.output.rfind("[") != builder.output.len - 1:
    builder.output &= ","

proc colon(builder: var JsonBuilder) =
  if builder.skip_colon_spacing():
    builder.output &= ":"
  else:
    builder.output &= ": "

proc open(builder: var JsonBuilder, key = "", opener = "{") =
  if not builder.skip_bracket_spacing():
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
  if not builder.skip_comma_spacing():
    builder.indent()
  builder.output &= x
  if builder.terminator_stack.len > 0:
    builder.comma()

# ===== Constructors =====

proc newJsonBuilder*(opener = "{", flags: set[char] = {}):JsonBuilder =
  ## Create a new JSON builder. Default to a standard JS object, however for
  ## full forward compatibility, use of newJsonObjectBuilder() is recommended.
  ## Produces a "pretty" JSON output - by default, set flags to {':',',','{'} to avoid
  ## syntactically unnecessary whitespace. Alternatively, for a good mix of
  ## readability and compactness, try just {','}
  result = (output: "", terminator_stack: @[], flags: flags)
  result.open("", opener)


proc newJsonObjectBuilder*(flags: set[char] = {}):JsonBuilder =
  ## Create a new JSON builder, creating a standard JS object {...}
  ## Produces a "pretty" JSON output by default, use newCompactJsonObjectBuilder
  ## to avoid syntactically unnecessary whitespace
  newJsonBuilder("{", flags)

proc newJsonArrayBuilder*(flags: set[char] = {}):JsonBuilder =
  ## Create a new JSON builder, creating a standard JS array [...]
  ## Note that it is not normal to create arrays as the top level container
  ## for a JSON response - some parsers may consider this illegal syntax.
  ## Produces a "pretty" JSON output by default, use newCompactJsonArrayBuilder
  ## to avoid syntactically unnecessary whitespace
  newJsonBuilder("[", flags)

proc newCompactJsonObjectBuilder*():JsonBuilder =
  ## See newJsonObjectBuilder for usage
  newJsonBuilder("{", {':',',','{'})

proc newCompactJsonArrayBuilder*():JsonBuilder =
  ## See newJsonArrayBuilder for usage
  newJsonBuilder("[", {':',',','{'})

# ===== Public methods =====

proc finish*(builder: var JsonBuilder) =
  ## Close any remaining open sections/arrays
  while builder.terminator_stack.len > 0:
    builder.close()

proc is_array_context*(builder: var JsonBuilder): bool =
  ## If I add an item at this moment, would it be an item in an array?
  builder.terminator_stack.last() == "]"

template add_array*(builder: var JsonBuilder, key:string, code: untyped): untyped =
  ## Add an array as an element to the current container.
  builder.open(key, "[")
  code
  builder.close()

template add_array*(builder: var JsonBuilder, code: untyped): untyped =
  ## Anyone know why making key default to empty string on our counterpart
  ## template causes an error?
  builder.add_array("", code)

template add_object*(builder: var JsonBuilder, key:string, code: untyped): untyped =
  ## Add an object as an element to the current container.
  builder.open(key, "{")
  code
  builder.close()

template add_object*(builder: var JsonBuilder, code: untyped): untyped =
  ## Anyone know why making key default to empty string on our counterpart
  ## template causes an error?
  builder.add_object("", code)

proc array_entry*[T](builder: var JsonBuilder, item: T) =
  ## Add an item to the current object, assuming our container is an array
  if not builder.skip_comma_spacing():
    builder.indent()
  builder.output &= optionallyEscapeJson(item)
  builder.comma()

proc object_entry*[T](builder: var JsonBuilder, key: string, value: T) =
  ## Add a key/value to the current object, assuming our container is an object
  if not builder.skip_comma_spacing():
    builder.indent()
  builder.output &= optionallyEscapeJson(key)
  builder.colon()
  builder.output &= optionallyEscapeJson(value)
  builder.comma()


proc add_entry*[T](builder: var JsonBuilder, value: T) {.raises: [InvalidEntryError] .} =
  ## Add a value to the current array, making sure our container is an array first
  if not builder.is_array_context():
    raise newException(InvalidEntryError, "No value given; Both key and value required for an entry to an object")
  builder.array_entry value

proc add_entry*[T](builder: var JsonBuilder, key: string, value: T) {.raises: [InvalidEntryError] .} =
  ## Add a key/value to the current object, making sure our container is an object first
  if builder.is_array_context():
    raise newException(InvalidEntryError, "Provided key and value; only value required when an entry to an array")
  builder.object_entry key, value

proc `$`*(builder: JsonBuilder): string =
  ## standard toString - JSON representation as it currently stands
  builder.output

