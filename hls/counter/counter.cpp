// ------------------------------------------------------------------
//
// Simple HLS counter
//
// ------------------------------------------------------------------
unsigned 
counter(unsigned &initV, bool reset, bool count_up, unsigned &count) 
// ------------------------------------------------------------------
{
  //"Static variables in a Function: When a variable is declared as static, 
  //space for it gets allocated for the lifetime of the program. Even if 
  //the function is called multiple times, space for the static variable
  // is allocated only once and the value of the variable in the previous
  // call gets carried through the next function call."

  static unsigned internal_count=0;
  internal_count++;

  // same reset behavior as in our vhdl
  if( reset ) { 
    count = initV;
    internal_count = 0;
  }

  if( (internal_count&0x7ffffff) == 0x5F5E100 ) { 
    if (count_up == 1)
      count++;
    else 
      count--;
  }

  // could have used a reference variable for this too, but here showing
  // how return values are handled
  return internal_count;
}
