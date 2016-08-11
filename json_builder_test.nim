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
      builder.add_entry("total_languages", 1000)
      builder.add_entry("not_php", 99.999)
    builder.finish()
    validate_json_object(builder)

  test "it lets us add an array":
    builder.add_array("cleverclogs"):
      builder.add_entry("Andreas Rumpf")
      builder.add_entry("Yukihiro Matsumoto")
      builder.add_entry("Alan Kay")
      builder.add_entry(1000)
      builder.add_entry(99.999)
    builder.finish()
    validate_json_object(builder)

  test "it lets us add an array in an array":
    builder.add_array "board":
      builder.add_array:
        builder.add_entry("a0")
        builder.add_entry("b0")
      builder.add_array:
        builder.add_entry("a1")
        builder.add_entry("b1")
    builder.finish()
    validate_json_object(builder)

  test "it lets us add an array in an object in an array":
    builder.add_array "board":
      builder.add_object:
        builder.add_array("a"):
          builder.add_entry(0)
          builder.add_entry(1)
        builder.add_array("b"):
          builder.add_entry(0)
          builder.add_entry(1)
    builder.finish()
    validate_json_object(builder)

  test "it is readable":
    builder.add_entry("does", "this")
    builder.add_object("seem"):
      builder.add_array("reasonable"):
        builder.add_entry("to")
        builder.add_entry(1)
        builder.add_entry(2.2)
      builder.add_entry("depends", 1)
      builder.add_entry("on", 2.2)
    builder.add_entry("your", "perspective")
    builder.finish()
    validate_json_object(builder)
    let expected = """
{
  "does": "this",
  "seem": {
    "reasonable": [
      "to",
      1,
      2.2
    ],
    "depends": 1,
    "on": 2.2
  },
  "your": "perspective"
}"""
    check($builder == expected)


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


  test "it is unreadable":
    builder.add_entry("does", "this")
    builder.add_object("seem"):
      builder.add_array("reasonable"):
        builder.add_entry("to")
        builder.add_entry(1)
        builder.add_entry(2.2)
      builder.add_entry("depends", 1)
      builder.add_entry("on", 2.2)
    builder.add_entry("your", "perspective")
    builder.finish()
    validate_json_object(builder)
    let expected = """{"does":"this","seem":{"reasonable":["to",1,2.2],"depends":1,"on":2.2},"your":"perspective"}"""
    check($builder == expected)



suite "semi-compact JSON object":
  setup:
    builder = newJsonObjectBuilder({','})

  test "it is configurably compact":
    builder.add_entry("one", 1)
    builder.add_entry("two", 2)
    builder.add_entry("three", 3)
    builder.add_array("reasonable"):
      builder.add_entry("four")
      builder.add_entry("five")
      builder.add_object():
        builder.add_entry("six", 6)
        builder.add_entry("seven", 7)

    builder.finish()
    validate_json_object(builder)
    let expected = """
{"one": 1,"two": 2,"three": 3,
  "reasonable": ["four","five",
    {"six": 6,"seven": 7}]}"""
    check($builder == expected)



