In this assignment, you only need to focus on the following type rules:

# (1) Variable declarations: 

### 1.a Every variable and every defined-type name must be declared explicitly. 

Additional error message: 


"ID (name) undeclared."

In Progress:

-typedef declarations need to work, and typedef id checking needs to be impleme
nted.

-scopes

### 1.b A name (a variable, a function or a type) cannot be declared more than once in the same scope (global or local). 

Additional error message: 

"ID (name) redeclared."

In Progress:
-Variable and function redeclarations will produce error
-Need to finish struct

---

# (2) Functions and function calls: 

### 2.a A call to a function must use the correct number of parameters. 

Additional error message: 


"too few arguments to function (name)".

 Complete


"too many arguments to function (name).

 Complete


### 2.b A function must return a value of the correct type. 

Additional error message: 


"Incompatible return type." 

Complete

---

# (3) Array references: 

### 3.a Array references, except for actual parameters in function calls, must match their declared dimensions. 

Additional error message: 


"Incompatible array dimensions."

Complete


### 3.b There is no need to check for array bounds. However, the array index expression must be integer. 

Additional error message: 


"Array subscript is not an integer"

Complete

### 3.c An array name cannot be passed to a scalar formal parameter, and a scalar cannot be passed to an array formal parameter. 

Additional error message: 


"Array (name) passed to scalar parameter (name)."
 or 

Complete

"Scalar (name) passed to array parameter (name)."

Complete

---

# (4) Structure and Union references: 

In addition to the selection operators ".", C-- also allows structure to be assigned, to be passed as parameters to functions, and to be returned from functions. Union types are almost identical to structures. The main difference is that all fields in a union are overlaid in memory. In terms of type checking, unions can be treated as structures (This is why we return the same token ID for both struct and union key words). 

### 4.a A field referenced in a structure must be declared. 
Additional error message: 

" Structure has no member named (name) " 

Not started

### 4.b A field name in a structure cannot be declared more than once. 
Additional error message: 

" Duplicate member (name) " 

Not started

### 4.c Type checking for structures and unions: 

Not started

The following example illustrates some valid and invalid structure type references in C--

struct complex1 { 

float real; 

float imag; 

} 

struct complex1 x1, y1; 


struct complex2 { 

float real; 

float imag; 

} 

struct complex2 x2, y2; 


Example A. 

x1 = y1 /* This is OK */ 

Example B. 

x1 = x1 + y1 /* This is invalid */

Error message: 


"Invalid operands to + "
 


Example C. 

x1 = x2 /* This is invalid */ 

Error message: 


"Incompatible type "
Although struct complex1 and complex2 have identical structures, their type names are different! 

In ANSI C, name equivalence is used instead of structure equivalence. 


### 4.d Structures may not contain instances of themselves. 

not started

For example: 

struct S { 

int a; 

struct S next; /* This is illegal in C-- */ 

} 

Error message: 


field (name) has incomplete type 
