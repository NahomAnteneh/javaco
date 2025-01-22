#include "symbol_table.h"
#include <stdlib.h>
#include <string.h>

SymbolTable *create_scope(char *name, SymbolTable *parent)
{
    SymbolTable *new_table = (SymbolTable *)malloc(sizeof(SymbolTable));
    new_table->name = strdup(name);
    new_table->entries = NULL;
    new_table->parent = parent;
    new_table->children = NULL;
    new_table->next_sibling = NULL;

    if (parent)
    {
        // Add to parent's children list
        new_table->next_sibling = parent->children;
        parent->children = new_table;
    }

    return new_table;
}

void insert_symbol(SymbolTable *table, char *name, char *type, SymbolCategory category, SymbolTable *scope)
{
    SymbolEntry *entry = (SymbolEntry *)malloc(sizeof(SymbolEntry));
    entry->name = strdup(name);
    entry->type = strdup(type);
    entry->category = category;
    entry->scope = scope;
    entry->next = table->entries;
    table->entries = entry;
}

SymbolEntry *lookup_symbol(SymbolTable *table, char *name)
{
    if (!table)
        return NULL;
    SymbolEntry *entry = table->entries;
    while (entry)
    {
        if (strcmp(entry->name, name) == 0)
            return entry;
        entry = entry->next;
    }
    return lookup_symbol(table->parent, name);
}

void destroy_scope(SymbolTable *table)
{
    if (!table)
        return;

    // Destroy children first
    SymbolTable *child = table->children;
    while (child)
    {
        SymbolTable *next_child = child->next_sibling;
        destroy_scope(child);
        child = next_child;
    }

    // Destroy entries
    SymbolEntry *entry = table->entries;
    while (entry)
    {
        SymbolEntry *temp = entry;
        entry = entry->next;
        free(temp->name);
        free(temp->type);
        free(temp);
    }

    free(table->name);
    free(table);
}

void print_scope_details(SymbolTable *table, int depth)
{
    if (!table)
        return;

    // Print scope name with indentation
    for (int i = 0; i < depth; i++)
        printf("│   ");
    printf("├── Scope: %s\n", table->name);

    // Print symbols in this scope
    SymbolEntry *entry = table->entries;
    while (entry)
    {
        for (int i = 0; i < depth + 1; i++)
            printf("│   ");
        const char *category = "";
        switch (entry->category)
        {
        case SYMBOL_CATEGORY_VARIABLE:
            category = "Variable";
            break;
        case SYMBOL_CATEGORY_METHOD:
            category = "Method";
            break;
        case SYMBOL_CATEGORY_CLASS:
            category = "Class";
            break;
        case SYMBOL_CATEGORY_PARAMETER:
            category = "Parameter";
            break;
        }
        printf("├── %s [%s] (%s)\n", entry->name, entry->type, category);
        entry = entry->next;
    }

    // Recursively print child scopes
    SymbolTable *child = table->children;
    while (child)
    {
        print_scope_details(child, depth + 1);
        child = child->next_sibling;
    }
}

void print_symbol_table(SymbolTable *global_scope)
{
    printf("\nSYMBOL TABLE HIERARCHY:\n");
    printf("┌─────────────────────────────┐\n");
    print_scope_details(global_scope, 0);
    printf("└─────────────────────────────┘\n");
}