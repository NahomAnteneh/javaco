# Compiler and flags
CC = gcc
CFLAGS = -Wall -g

# Lex and Yacc files
LEX_FILE = lexer.l
YACC_FILE = parser.y

# Output directories
BUILD_DIR = build
LEX_C = $(BUILD_DIR)/lex.yy.c
YACC_C = $(BUILD_DIR)/y.tab.c
YACC_H = $(BUILD_DIR)/y.tab.h
EXEC = $(BUILD_DIR)/javacompiler

# Symbol table implementation
SYMBOL_TABLE_SRC = symbol_table.c
SYMBOL_TABLE_OBJ = $(BUILD_DIR)/symbol_table.o

# All source files
OBJS = $(BUILD_DIR)/y.tab.o $(BUILD_DIR)/lex.yy.o $(SYMBOL_TABLE_OBJ)

# Default target
all: $(BUILD_DIR) $(EXEC)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile and link the project
$(EXEC): $(OBJS)
	$(CC) $(CFLAGS) -o $(EXEC) $(OBJS)

# Build Yacc parser
$(BUILD_DIR)/y.tab.c $(BUILD_DIR)/y.tab.h: $(YACC_FILE) | $(BUILD_DIR)
	yacc -d -o $(BUILD_DIR)/y.tab.c $(YACC_FILE)

# Build Lex scanner
$(BUILD_DIR)/lex.yy.c: $(LEX_FILE) | $(BUILD_DIR)
	lex -o $(BUILD_DIR)/lex.yy.c $(LEX_FILE)

# Compile the symbol table implementation
$(BUILD_DIR)/symbol_table.o: $(SYMBOL_TABLE_SRC) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $(SYMBOL_TABLE_SRC) -o $(BUILD_DIR)/symbol_table.o

# Compile Yacc output
$(BUILD_DIR)/y.tab.o: $(BUILD_DIR)/y.tab.c
	$(CC) $(CFLAGS) -c $(BUILD_DIR)/y.tab.c -o $(BUILD_DIR)/y.tab.o

# Compile Lex output
$(BUILD_DIR)/lex.yy.o: $(BUILD_DIR)/lex.yy.c
	$(CC) $(CFLAGS) -c $(BUILD_DIR)/lex.yy.c -o $(BUILD_DIR)/lex.yy.o

# Clean up build files
clean:
	rm -rf $(BUILD_DIR)

# Run the program
run: $(EXEC)
	./$(EXEC) input.java