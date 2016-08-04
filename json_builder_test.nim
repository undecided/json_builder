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
    builder.add_entry("top", "level")
    builder.add_object("cleverclogs"):
      builder.add_entry("nim", "Andreas Rumpf")
      builder.add_entry("ruby", "Yukihiro Matsumoto")
      builder.add_entry("smalltalk", "Alan Kay")
    builder.finish()
    validate_json_object(builder)

  test "it lets us add an array":
    builder.add_array("cleverclogs"):
      builder.add_entry("Andreas Rumpf")
      builder.add_entry("Yukihiro Matsumoto")
      builder.add_entry("Alan Kay")
    builder.finish()
    validate_json_object(builder)

  test "it is readable":
    builder.add_entry("does", "this")
    builder.add_object("seem"):
      builder.add_array("reasonable"):
        builder.add_entry("to")
        builder.add_entry("you?")
      builder.add_entry("depends", "on")
    builder.add_entry("your", "perspective")
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
    builder.add_entry("as", "a")
    builder.add_entry("great", "puppet")
    builder.add_entry("once", "said:")
    builder.add_array("I"):
      builder.add_entry("have")
      builder.add_entry("no")
      builder.add_entry("space")
    builder.add_object("to"):
      builder.add_entry("hold", "me")
      builder.add_entry("down", "see?")
    builder.finish()
    validate_json_object(builder)
    check(builder.`$`.count(Whitespace + NewLines) == 0)
