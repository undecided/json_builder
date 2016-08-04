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


### External JsonBuilder

type JsonBuilder* = tuple[output: string, terminator_stack: seq[string], flags: set[char]]

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

