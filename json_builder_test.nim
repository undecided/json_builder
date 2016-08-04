import unittest
import json_builder
import json
import strutils

var builder: JsonBuilder

template validate_json_object(builder: JsonBuilder) =
  check(parseJson($(builder)).kind == JObject)

suite "JSON object":
  setup:
    builder = newJsonObjectBuilder()

  test "it produces valid json object":
    builder.finish()
    validate_json_object(builder)

  test "it lets us add object entries":
    builder.object_entry("top", "level")
    builder.add_object("cleverclogs"):
      builder.object_entry("nim", "Andreas Rumpf")
      builder.object_entry("ruby", "Yukihiro Matsumoto")
      builder.object_entry("smalltalk", "Alan Kay")
    builder.finish()
    validate_json_object(builder)

  test "it lets us add an array":
    builder.add_array("cleverclogs"):
      builder.array_entry("Andreas Rumpf")
      builder.array_entry("Yukihiro Matsumoto")
      builder.array_entry("Alan Kay")
    builder.finish()
    validate_json_object(builder)

  test "it is readable":
    builder.object_entry("does", "this")
    builder.add_object("seem"):
      builder.add_array("reasonable"):
        builder.array_entry("to")
        builder.array_entry("you?")
      builder.object_entry("depends", "on")
    builder.object_entry("your", "perspective")
    builder.finish()
    validate_json_object(builder)
    let expected = """
{
  "does": "this",
  "seem": {
    "reasonable": [
      "to",
      "you?"
    ],
    "depends": "on"
  },
  "your": "perspective"
}"""
    let actual = $(builder)
    check(expected == actual)


suite "compact JSON object":
  setup:
    builder = newCompactJsonObjectBuilder()

  test "it adds arrays without spaces":
    builder.object_entry("as", "a")
    builder.object_entry("great", "puppet")
    builder.object_entry("once", "said:")
    builder.add_array("I"):
      builder.array_entry("have")
      builder.array_entry("no")
      builder.array_entry("space")
    builder.add_object("to"):
      builder.object_entry("hold", "me")
      builder.object_entry("down", "see?")
    builder.finish()
    validate_json_object(builder)
    check(builder.`$`.count(Whitespace + NewLines) == 0)
