sys = require("sys")
fs = require("fs")

require("./sexp")

parseContents = (fileName) ->
    content = fs.readFileSync(fileName, "utf8")

    # Keep our parser simple by sanitizing parts of the file, for now (TODO integrate into parser maybe.)

    # Remove comments:
    content = content.replace(/;[^\n]*/g, "")
    # Replace \ with /:
    content = content.replace(/\\/g, '/')
    # Parse a list:
    content = "(" + content + ")"
    print content
    parsed = SExp.parse(content)
    print JSON.stringify(parsed)  
    return parsed

parsed = parseContents("tictactoe.zrf")
