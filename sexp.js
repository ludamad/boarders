SExp = {
  parse: function(str) {
    var stack = {head: null, tail: null},
        dot = false,
        i, j;

    str: for(i = str.length; i--; ) {
      switch(str.charCodeAt(i)) {
        /* Skip whitespace. */
        case     9: case    10: case    11: case    12: case    13:
        case    32: case   160: case  5760: case  6158: case  8192:
        case  8193: case  8194: case  8195: case  8196: case  8197:
        case  8198: case  8199: case  8200: case  8201: case  8202:
        case  8232: case  8233: case  8239: case  8287: case 12288:
        case 65279:
          break;

        /* Open parenthesis pops the current list from the stack and adds
         * it to the beginning of the next list. */
        case 40:
          if(dot || stack.tail === null)
            break str;

          stack.tail.head = {head: stack.head, tail: stack.tail.head};
          stack = stack.tail;
          dot = false;
          break;

        /* Closed parenthesis push a new list onto the stack. */
        case 41:
          stack = {head: null, tail: stack};
          dot = false;
          break;

        /* Dot moves the head of the current list to it's tail. */
        case 46:
          if(stack.head === null || stack.head.tail !== null)
            break str;

          stack.head = stack.head.head;
          dot = true;
          break;

        /* Atoms get added to the beginning of the current list. */
        default:
          atom: for(j = i; j--; )
            switch(str.charCodeAt(j)) {
              case     9: case    10: case    11: case    12: case    13:
              case    32: case    40: case    41: case    46: case   160:
              case  5760: case  6158: case  8192: case  8193: case  8194:
              case  8195: case  8196: case  8197: case  8198: case  8199:
              case  8200: case  8201: case  8202: case  8232: case  8233:
              case  8239: case  8287: case 12288: case 65279:
                break atom;
            }

          stack.head = {head: str.slice(++j, ++i), tail: stack.head};
          dot = false;
          i = j;
          break;
      }
    }

    if(stack.head === null ||
       stack.tail !== null ||
       stack.head.tail !== null)
        print(str.substring(i-5,i+7));
      throw new SyntaxError("Invalid s-expression.");

    return stack.head.head;
  }
};
