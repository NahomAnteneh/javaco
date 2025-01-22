# Compiler and flags
CC = gcc
CFLAGS = -Wall -g -I$(BUILD_DIR) -I.
LEX = flex
YACC = bison

# Input files
LEX_FILE = lexer.l
YACC_FILE = parser.y
SYMBOL_TABLE_SRC = symbol_table.c

# Output directories
BUILD_DIR = build
EXEC = $(BUILD_DIR)/javaco

# Default target
all: $(BUILD_DIR) $(EXEC)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile everything directly to executable
$(EXEC): $(YACC_FILE) $(LEX_FILE) $(SYMBOL_TABLE_SRC) | $(BUILD_DIR)
	$(YACC) -d -o $(BUILD_DIR)/y.tab.c $(YACC_FILE)
	$(LEX) -o $(BUILD_DIR)/lex.yy.c $(LEX_FILE)
	$(CC) $(CFLAGS) -o $@ $(BUILD_DIR)/y.tab.c $(BUILD_DIR)/lex.yy.c $(SYMBOL_TABLE_SRC) -ll

# Clean up all generated files
clean:
	rm -rf $(BUILD_DIR)

# Run the program
run: $(EXEC)
	./$(EXEC) input.java