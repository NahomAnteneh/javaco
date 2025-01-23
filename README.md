# Java Compiler with Symbol Table and Semantic Analysis

A Java-like compiler implementation using Flex (lexer) and Bison (parser), featuring symbol table management, scope handling, and semantic error checking.

## Features

- **Lexical Analysis**: Tokenizes Java-like syntax
- **Syntax Parsing**: Implements grammar rules for classes, methods, variables, and control structures
- **Semantic Checks**:
  - Variable redeclaration detection
  - Type mismatch validation
  - Undeclared identifier checking
  - Method/constructor existence verification
  - Scope management (global, class, method, block)
- **Symbol Table**:
  - Hierarchical scope tracking
  - Variable/method/parameter storage
  - Parent-child scope relationships

## Dependencies

- Flex (≥ 2.6)
- Bison (≥ 3.7)
- GCC or Clang
- Make (optional)

## Installation & Usage

### 1. Install Requirements

```bash
# Ubuntu/Debian
sudo apt install flex bison build-essential make
```

### 2. Run using make

```bash
make
```

### 3. Parse the test file using the executable

```bash
./build/javaco <test file>
```

## Expected output

```
Java Compiler - Parsing Started
Error at line 3: Variable redeclared: 'a'
Error at line 4: Variable redeclared: 'a'
Parsing Failed
SYMBOL TABLE HIERARCHY:
┌─────────────────────────────┐
├── Scope: global
│   ├── Scope: ValidProgram
│   │   ├── Scope: main
│   │   │   ├── Variable [String[]] (Parameter)
└─────────────────────────────┘
```

## Members

- Nahom Anteneh
- Nigst W/Micael
- Bezawit Marew
- Abraham Getahun
- Eyob alebachew
