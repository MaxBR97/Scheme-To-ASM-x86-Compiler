# Scheme-To-ASM-x86-Compiler
This project is a compiler for Scheme language which is part of the Lisp languages.

## The compilation process works according to the following pipeline: 

### Scanner -> Parser -> Semantic Analyser -> Code Generator

Scanner : Receives source code (text) and outputs tokens

Parser : Receives ordered tokens and outputs an AST (abstract syntax tree) which is the logical structure of the code

Semantic Analyser : Receives an AST and outputs an optimized and type checked AST, and prepares for code generation. 

Code Generator : Receives an AST and generates the respective code in the destination language (Assembly x86 in this case).

Notes:

*This project includes tail-calls optimization which is necessary for recursions.

*Rigorously tested.

*Runs on Linux only.

