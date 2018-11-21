                                       -- Chapter 16 - Program 1
package body charstack is

procedure Push(In_Char : in CHARACTER);  -- In_Char is added to the
                                         -- stack if there is room.

procedure Pop(Out_Char : out CHARACTER); -- Out_Char is removed from
                                         -- stack and returned if a
                                         -- character is on stack.
                                         -- else a blank is returned

function Is_Empty return BOOLEAN;        -- TRUE if stack is empty

function Is_Full return BOOLEAN;         -- TRUE if stack is full

function Current_Stack_Size return INTEGER;

procedure Clear_Stack;                   -- Reset the stack to empty

end charstack;





