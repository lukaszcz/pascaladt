/*
 * This program is a simple macro processor.
 */

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include <errno.h>

#include "utils.h"
#include "input.h"

#define SKIP_TO_ENDIF 0x01
#define SKIP_TO_ELSE 0x02
#define SKIP_TO_ELSEIF 0x04

#define TERMINATE_EOL 0x01
#define TERMINATE_WHITESPACE 0x02
#define TERMINATE_BRACKET 0x04
#define TERMINATE_COMMA 0x08

/* Returns true if the given character may be present in a mcp
   idnetifier.  */
int is_ident(char c);
/* Reads a sequence of non-whitespace characters into name. */
void read_word(char *name, int max_len);
/* Reads all characters up to the end of line into name. Parses macros
   on the way. Flag is a combination of TERMINATE_XXX. It indicates
   what stops reading the text. */
void read_text(char *name, int max_len, int flag);
/* Skips everything in the input until a command specified by flags is
   encoutered. The argument flags is a combination of SKIP_TO_XXX bit
   masks. Returns the SKIP_TO_XXX bit mask corresponding to the
   construct that stopped skipping. */
int skip_if_block(int flags);
/* Parses a "macro expression". Sets text to the resulting text. text
   must be at least MAX_NAME_LEN characters long.  */
void parse_exp(char *text);
/* Saves the current hash tables of local defines and macros on a
   stack. Called before entering a new local level (via &include or by
   calling a macro). */
void push_local_stack();
/* Pops the local stack. */
void pop_local_stack();
/* Adds a user (command line) define. Such defines override both local
   and global defines, and may not be undefined.  */
void add_user_define(char *name, char *text);
/* Adds a local define to the hash table. */
void add_local_define(char *name, char *text);
/* Adds a global define. */
void add_global_define(char *name, char *text);
/* Removes a local or global define entry. If no such entry exists then
   does nothing.  */
void remove_define(const char *name);
/* Searches for an entry in the hash table. Returns NULL if not found,
   or the associated text if found.  */
char* find_define(const char *name);
/* Clears the hash table with local defines. Does not affect global
   defines. */
void clear_defines();
/* Adds a local macro to the hash table. */
void add_local_macro(char *name, char *text);
/* Adds a global macro. */
void add_global_macro(char *name, char *text);
/* Removes a local or global define entry. If no such entry exists then
   does nothing.  */
void remove_macro(const char *name);
/* Searches for a macro. Returns NULL if not found, or the associated
   text if found.  */
char *find_macro(const char *name);
/* Clears the hash table with local macros. Does not affect global
   macros. */
void clear_macros();
/* Returns non-zero if the given symbol is defined (as a normal define
   or a macro), zero otherwise.  */
int is_defined(const char *name);
/* Reads a macro */
char *read_macro();
/* Performs macro and define expansion on name. If b_output is FALSE
   then returns a new string representing the result. If it is TRUE
   then writes to output. If b_warn is TRUE and no substitution is
   found then gives a warning, and additionally the macro character is
   written to output just before the string.  */
char *expand(const char *name, int b_output, int b_warn);
/* Parses a command. Assumes that the most recently read charhas been
   the macro char. If b_output is non-zero then writes output to the
   global output file, otherwise returns it in a dynamically allocated
   string, which must be freed by the caller. The result may be NULL
   even if b_output is zero, which means that htere is simpley no
   output.  */
char *parse_command(int b_output);
/* Processes the current input stream (as a file). Appends output to
   the global file output.  */
void process_stream();
/* Performs the initialization. */
void init();
/* Cleans up. */
void cleanup();
/* Exits with an error. Cleans up before exiting. */
void error_exit();


char macro_char = '&';
/* the current output file */
FILE *output = NULL;

/* Hash tables */
hashtable_t *local_defines;
hashtable_t *global_defines;
hashtable_t *local_macros;
hashtable_t *global_macros;
/* user (command line) defines are never cleared and override all
   other defines and macros  */
hashtable_t *user_defines;

/* Expand non-prefixed words? */
int expand_non_prefixed_words = FALSE;
int global_expand_non_prefixed = FALSE; /* May be set only on command line. */

/* The local stack */
hashtable_t *local_defines_stack[MAX_LOCAL_LEVELS];
hashtable_t *local_macros_stack[MAX_LOCAL_LEVELS];
int local_stack_top = -1;

int is_ident(char c)
{
  return isalnum(c) || c == '_' || c == '-';
}

void read_word(char *name, int max_len)
{
  char buf[MAX_NAME_LEN*3];
  int c, i = 0;
  int alnum;

  skip_non_eol_whitespace();
  c = mcp_getc();
  if (isalnum(c) || c == '_')
    alnum = TRUE;
  else
    alnum = FALSE;
  while (((alnum && (isalnum(c) || c == '_')) || (!alnum && !isspace(c))) &&
         c != '(' && c != ')' && c != macro_char && c != EOF)
    {
      name[i++] = c;
      c = mcp_getc();
      if (i >= max_len)
        {
          sprintf(buf, "Name too long. Maximum length is %d.", max_len);
          fatal_error(buf, current_file, current_line);
        }
    }
  mcp_ungetc(c);
  name[i] = '\0';
}

void read_text(char *text, int max_len, int flag)
{
  char buf[MAX_NAME_LEN*3];
  int i, c;
  char* str;
  int unclosed_brackets = 0;

  if (flag & TERMINATE_EOL)
    skip_non_eol_whitespace();
  else
    skip_whitespace();
  i = 0;
  for (;;)
    {
      c = mcp_getc();
      if ((flag & TERMINATE_EOL) && c == '\n' && unclosed_brackets == 0)
        break;
      if ((flag & TERMINATE_WHITESPACE) && isspace(c) && unclosed_brackets == 0)
        break;
      if ((flag & TERMINATE_COMMA) && (c == ',' || c == ';') &&
          unclosed_brackets == 0)
        {
          break;
        }
      if ((flag & TERMINATE_BRACKET) && c == ')')
        {
          if (unclosed_brackets-- == 0)
            break;
        }

      if (c == macro_char)
        {
          str = parse_command(FALSE);
          text[i] = '\0';
          if (str != NULL)
            {
              if (i + strlen(str) + 1 > max_len)
                {
                  sprintf(buf, "Error. Name too long. Maximum length is %d.",
                          max_len);
                  fatal_error(buf, current_file, current_line);
                }
              strcat(text, str);
              free(str);
              i = strlen(text);
            }
        }
      else
        {
          if (c == '(')
            ++unclosed_brackets;

          if (i + 2 > max_len)
            {
              sprintf(buf, "Error. Name too long. Maximum length is %d.",
                      max_len);
              fatal_error(buf, current_file, current_line);
            }
          text[i++] = c;
        }
    }
  text[i] = '\0';
  if (c != '\n')
    mcp_ungetc(c);
}

int skip_if_block_aux(int flags)
{
  char word[MAX_NAME_LEN + 1];
  int nest_level = 1;
  int c = mcp_getc();
  while (c != EOF)
    {
      if (c == macro_char)
        {
          read_word(word, MAX_NAME_LEN);
          if (strequal(word, "endif"))
            {
              if (--nest_level == 0 && flags & SKIP_TO_ENDIF)
                return SKIP_TO_ENDIF;
            }
          else if (flags & SKIP_TO_ELSE && strequal(word, "else") &&
                   nest_level == 1)
            {
              return SKIP_TO_ELSE;
            }

          else if (flags & SKIP_TO_ELSEIF && strequal(word, "elseif") &&
                   nest_level == 1)
            {
              return SKIP_TO_ELSEIF;
            }
          else if (strequal(word, "ifdef") || strequal(word, "ifndef") ||
                   strequal(word, "if"))
            {
              ++nest_level;
            }
        }
      c = mcp_getc();
    }
  return SKIP_TO_ENDIF;
}

int skip_if_block(int flag)
{
  int result = skip_if_block_aux(flag);
  skip_whitespace();
  return result;
}


/* -- Local stack -- */

void push_local_stack()
{
  if (local_stack_top + 1 >= MAX_LOCAL_LEVELS)
    {
      fatal_error("Too many local levels (includes + invoked macros).",
                  current_file, current_line);
    }
  ++local_stack_top;
  local_defines_stack[local_stack_top] = local_defines;
  local_macros_stack[local_stack_top] = local_macros;
  local_defines = new_hashtable();
  local_macros = new_hashtable();
}

void pop_local_stack()
{
  assert(local_stack_top >= 0);
  assert(local_defines != NULL);
  assert(local_macros != NULL);

  hashtable_destroy(local_defines, TRUE);
  hashtable_destroy(local_macros, TRUE);
  local_defines = local_defines_stack[local_stack_top];
  local_macros = local_macros_stack[local_stack_top--];
}

/* -- end Local stack -- */



/* -- Hash table manipulation -- */

void table_insert(hashtable_t *table, char *name, char *text)
{
  free(hashtable_remove(table, name));
  if (!hashtable_insert(table, name, text))
    {
      fatal_error("Cannot insert into a hashtable.", current_file, current_line);
    }
}

void add_user_define(char *name, char *text)
{
  /* User defines override both local and global defines. */
  table_insert(user_defines, name, text);
}

void add_local_define(char *name, char *text)
{
  /* Notice that global_defines is not checked. This way local defines
     override global ones. See also find_define() and
     add_user_define().  */
  table_insert(local_defines, name, text);
}

void add_global_define(char *name, char *text)
{
  free(hashtable_remove(local_defines, name));
  table_insert(global_defines, name, text);
}

char *find_define(const char *name)
{
  char *result = (char*) hashtable_search(user_defines, (void*) name);
  if (result == NULL)
    {
      result = (char*) hashtable_search(local_defines, (void*) name);
      if (result == NULL)
        result = (char*) hashtable_search(global_defines, (void*) name);
    }
  return result;
}

void remove_define(const char *name)
{
  free(hashtable_remove(local_defines, (void*) name));
  free(hashtable_remove(global_defines, (void*) name));
}

void clear_defines()
{
  hashtable_destroy(local_defines, TRUE);
  local_defines = new_hashtable();
}

void add_local_macro(char *name, char *text)
{
  /* Notice that global_macros is not checked. This way local macros
     override global ones. See also find_macro.  */
  table_insert(local_macros, name, text);
}

void add_global_macro(char *name, char *text)
{
  free(hashtable_remove(local_macros, name));
  table_insert(global_macros, name, text);
}

char *find_macro(const char *name)
{
  char *result = (char*) hashtable_search(local_macros, (void*) name);
  if (result == NULL)
    result = (char*) hashtable_search(global_macros, (void*) name);
  return result;
}

void remove_macro(const char *name)
{
  free(hashtable_remove(local_macros, (void*) name));
  free(hashtable_remove(global_macros, (void*) name));
}

void clear_macros()
{
  hashtable_destroy(local_macros, TRUE);
  local_macros = new_hashtable();
}

int is_defined(const char *name)
{
  return find_define(name) != NULL || find_macro(name) != NULL;
}

/* -- end Hash table manipulation -- */



/* -- Expression parsing -- */

/* parse_level_X() functions are used internally by the parse_exp()
   function  */
void parse_level_2(char *text)
{
  int c;

  skip_whitespace();
  c = mcp_getc();
  if (c == '(')
    {
      parse_exp(text);
      skip_whitespace();
      if ((c = mcp_getc()) != ')')
        {
          mcp_ungetc(c);
          warning("Missing closing bracket: ).", current_file, current_line);
        }
    }
  else
    {
      mcp_ungetc(c);
      read_text(text, MAX_NAME_LEN,
                TERMINATE_EOL | TERMINATE_WHITESPACE | TERMINATE_BRACKET);
    }
}

void parse_level_1(char *text)
{
  int c;
  char text2[MAX_NAME_LEN + 1];

  skip_whitespace();

  if ((c = mcp_getc()) == '!')
    {
      parse_level_1(text);
    }
  else
    {
      mcp_ungetc(c);
      parse_level_2(text);
      skip_whitespace();
      c = mcp_getc();
      if (c == '=')
        {
          if ((c = mcp_getc()) != '=')
            mcp_ungetc(c);
          parse_level_2(text2);
          if (strequal(text, text2))
            strcpy(text, "defined");
          else
            text[0] = '\0';
        }
      else if (c == '!')
        {
          if ((c = mcp_getc()) != '=')
            {
              mcp_ungetc(c);
              warning("Expected =", current_file, current_line);
            }
          parse_level_2(text2);
          if (strcmp(text, text2) != 0)
            strcpy(text, "defined");
          else
            text[0] = '\0';
        }
      else if (c == '<')
        {
          if ((c = mcp_getc()) == '=')
            {
              parse_level_2(text2);
              if (strcmp(text, text2) <= 0)
                strcpy(text, "defined");
              else
                text[0] = '\0';
            }
          else
            {
              mcp_ungetc(c);
              parse_level_2(text2);
              if (strcmp(text, text2) < 0)
                strcpy(text, "defined");
              else
                text[0] = '\0';
            }
        }
      else if (c == '>')
        {
          if ((c = mcp_getc()) == '=')
            {
              parse_level_2(text2);
              if (strcmp(text, text2) >= 0)
                strcpy(text, "defined");
              else
                text[0] = '\0';
            }
          else
            {
              mcp_ungetc(c);
              parse_level_2(text2);
              if (strcmp(text, text2) > 0)
                strcpy(text, "defined");
              else
                text[0] = '\0';
            }
        }
      else
        mcp_ungetc(c);
    }
}

void parse_exp(char *text)
{
  char text2[MAX_NAME_LEN + 1];
  char text3[MAX_NAME_LEN + 1];
  int c;

  text[0] = '\0';
  c = mcp_getc();
  while (c != ')' && c != EOF)
    {
      mcp_ungetc(c);
      parse_level_1(text3);
      for (;;)
        {
          skip_whitespace();
          c = mcp_getc();
          if (c == '|')
            {
              if ((c = mcp_getc()) != '|')
                {
                  mcp_ungetc(c);
                  c = '|';
                  break;
                }
              parse_level_1(text2);
              if (text3[0] == '\0' && text2[0] != '\0')
                strcpy(text3, text2);
            }
          else if (c == '&')
            {
              if ((c = mcp_getc()) != '&')
                {
                  mcp_ungetc(c);
                  c = '&';
                  break;
                }
              parse_level_1(text2);
              if (text3[0] != '\0' && text2[0] == '\0')
                text3[0] = '\0';
            }
          else
            break;
        }

      if (strlen(text) + strlen(text3) >= MAX_NAME_LEN)
        {
          fatal_error("Name too long.", current_file, current_line);
        }
      strcat(text, text3);
    }
  mcp_ungetc(c);
}

/* -- end Expression parsing -- */



/* -- Macro command and substitution parsing -- */

char *read_macro()
{
  const int POP_COMMAND_LEN = 12;
  int was_last_macro_char = FALSE;
  int i = 0;
  char *buffer = checked_malloc(MAX_NAME_LEN);
  int buffer_size = MAX_NAME_LEN;
  int encountered_endm = FALSE;
  int c, c2;
  char endm[5];

  skip_non_eol_whitespace();
  c = mcp_getc();
  if (c == '\n')
    {
      /* a multi-line macro */
      c = mcp_getc();
      while (c != EOF && !encountered_endm)
        {
          if (c == macro_char && !was_last_macro_char)
            {
              endm[0] = mcp_getc();
              endm[1] = mcp_getc();
              endm[2] = mcp_getc();
              endm[3] = mcp_getc();
              endm[4] = '\0';
              c2 = mcp_getc();
              if (strequal(endm, "endm") && isspace(c2))
                {
                  encountered_endm = TRUE;
                  break;
                }
              mcp_ungetc(c2);
              mcp_ungets(endm);
              was_last_macro_char = TRUE;
            }
          else
            was_last_macro_char = FALSE;

          if (buffer_size < i + POP_COMMAND_LEN + 3)
            {
              buffer = checked_realloc(buffer, buffer_size *= 2);
            }
          buffer[i++] = c;

          c = mcp_getc();
        }
    }
  else
    {
      /* a one-line macro */
      while (c != '\n' && c != EOF)
        {
          if (buffer_size < i + POP_COMMAND_LEN + 3)
            {
              buffer = checked_realloc(buffer, buffer_size *= 2);
            }
          buffer[i++] = c;
          c = mcp_getc();
        }
      encountered_endm = TRUE;
    }
  buffer[i] = '\0';
  strcat(buffer, "&pop-stack&");

  if (!encountered_endm)
    {
      warning("Expected endm", current_file, current_line);
    }

  return buffer;
}

/* text is the text of a macro, not a macro name  */
void invoke_macro(char *text)
{
  const int INITIAL_ARG_NUM = 15;
  int c, i;
  char *arg;
  char *name;
  struct argument{
    char *name;
    char *arg;
  } *arguments = NULL;
  int last_arg = -1;
  unsigned max_args_count = 0;

  i = 0;
  if ((c = mcp_getc()) == '(')
    {
      max_args_count = INITIAL_ARG_NUM;
      arguments = (struct argument*) checked_malloc(INITIAL_ARG_NUM *
                                                    sizeof(struct argument));
      skip_whitespace();
      c = mcp_getc();
      while (c != ')' && c != EOF)
        {
          if (c == ',' || c == ';')
            skip_whitespace();
          else
            mcp_ungetc(c);

          arg = new_string();
          read_text(arg, MAX_NAME_LEN, TERMINATE_COMMA | TERMINATE_BRACKET);

          ++i;
          name = new_string();
          sprintf(name, "arg%d", i);

          if (i > max_args_count)
            {
              arguments = (struct argument*)
                checked_realloc(arguments,
                                (max_args_count *= 2)*sizeof(struct argument));
            }
          ++last_arg;
          arguments[last_arg].name = name;
          arguments[last_arg].arg = arg;

          c = mcp_getc();
        }
    }
  else
    mcp_ungetc(c);

  /* We have to push the stack now and not before the loop in order to
     make it possible to pass local defines as arguments to
     macros. */
  push_local_stack();

  /* arg0 = the number of arguments */
  arg = new_string();
  name = new_string();
  strcpy(name, "arg0");
  sprintf(arg, "%d", i);
  add_local_define(name, arg);

  /* Add the defines for the rest of arguments now.  */
  if (arguments != NULL)
    {
      for (i = 0; i <= last_arg; ++i)
        add_local_define(arguments[i].name, arguments[i].arg);
      free(arguments);
    }

  mcp_ungets(text);
  /* text is supposed to be terminated with the &pop-stack&
     command. See read_macro().  */
}

char *expand(const char *name, int b_output, int b_warn)
{
  char buf[MAX_NAME_LEN*3];
  char *text;
  char *str = NULL;
  /* Find the name in the hash table. */
  if ((text = find_define(name)) != NULL)
    {
      if (b_output)
        {
          fputs(text, output);
        }
      else
        {
          str = (char*) checked_malloc(strlen(text) + 1);
          strcpy(str, text);
        }
    }
  else if ((text = find_macro(name)) != NULL)
    {
      invoke_macro(text);
    }
  else
    {
      if (b_warn)
        {
          /* Copy to output, but give a warning. */
          sprintf(buf, "Undefined name: %s. Copying to output.", name);
          warning(buf, current_file, current_line);
        }
      if (b_output)
        {
          if (b_warn)
            putc(macro_char, output);
          fputs(name, output);
        }
      else
        {
          str = (char*) checked_malloc(strlen(name) + 3);
          if (b_warn)
            {
              str[0] = macro_char;
              str[1] = '\0';
            }
          else
            str[0] = '\0';
          strcat(str, name);
        }
    }
  return str;
}

char *parse_command(int b_output)
{
  char buf[MAX_NAME_LEN*3];
  int i, c, str_size;
  char name[MAX_NAME_LEN + 1];
  char filename[MAX_FILENAME_LEN + 1];
  char *defname, *text;
  char *str = NULL;

  c = mcp_getc();
  if (c == '<')
    { /* parse a quoted text */
      if (!b_output)
        {
          i = 0;
          str_size = MAX_NAME_LEN;
          str = (char*) checked_malloc(MAX_NAME_LEN);
        }

      while ((c = mcp_getc()) != '>' && c != EOF)
        {
          if (b_output)
            putc(c, output);
          else
            {
              if (i + 2 >= str_size)
                str = (char*) checked_realloc(str, str_size *= 2);
              str[i++] = c;
            }
        }
      if (c != '>')
        {
          error("Expected >", current_file, current_line);
        }

      if (!b_output)
          str[i] = '\0';

      return str;
    }
  /* else normal parsing */

  i = 0;
  while (!isspace(c) && c != macro_char && c != EOF && c != '(' && c != ')')
    {
      name[i++] = c;
      c = mcp_getc();
      if (i >= MAX_NAME_LEN)
        {
          sprintf(buf, "Name too long. Maximum length is %d.",
                  MAX_NAME_LEN);
          fatal_error(buf, current_file, current_line);
        }
    }
  name[i] = '\0';

  if (i == 0 && c == '\n')
    { /* a quoted newline */
      return NULL;
    }
  else if (i == 0 && c == macro_char)
    { /* a quoted 'macro char' */
      if (b_output)
        {
          putc(macro_char, output);
          return NULL;
        }
      else
        {
          str = (char*) checked_malloc(2);
          str[0] = macro_char;
          str[1] = '\0';
          return str;
        }
    }
  else if (c != macro_char)
    mcp_ungetc(c);

  if (strequal(name, "include"))
    {
      read_text(filename, MAX_FILENAME_LEN, TERMINATE_WHITESPACE | TERMINATE_EOL);
      skip_whitespace();
      push_local_stack();
      push_input_stack(filename);
      process_stream();
      pop_input_stack();
      pop_local_stack();
    }
  else if (strequal(name, "define"))
    {
      defname = new_string();
      text = new_string();
      read_word(defname, MAX_NAME_LEN);
      read_text(text, MAX_NAME_LEN, TERMINATE_EOL);
      add_global_define(defname, text);
      /* skip whitespace in order to skip a redundant \n if it follows
         immediately */
      skip_whitespace();
    }
  else if (strequal(name, "local-define"))
    {
      defname = new_string();
      text = new_string();
      read_word(defname, MAX_NAME_LEN);
      read_text(text, MAX_NAME_LEN, TERMINATE_EOL);
      add_local_define(defname, text);
      /* skip whitespace in order to skip a redundant \n if it follows
         immediately */
      skip_whitespace();
    }
  else if (strequal(name, "macro"))
    {
      defname = new_string();
      read_word(defname, MAX_NAME_LEN);
      text = read_macro();
      add_global_macro(defname, text);
      skip_whitespace();
    }
  else if (strequal(name, "local-macro"))
    {
      defname = new_string();
      read_word(defname, MAX_NAME_LEN);
      text = read_macro();
      add_local_macro(defname, text);
      skip_whitespace();
    }
  else if (strequal(name, "undefine"))
    { /* undefine a define or a macro */
      read_word(name, MAX_NAME_LEN);
      remove_define(name);
      remove_macro(name);
      skip_whitespace();
    }
  else if (strequal(name, "clear-defines"))
    {
      clear_defines();
      skip_whitespace();
    }
  else if (strequal(name, "clear-macros"))
    {
      clear_macros();
      skip_whitespace();
    }
  else if (strequal(name, "pop-stack"))
    {
      pop_local_stack();
      skip_whitespace();
    }
  else if (strequal(name, "expand-non-prefixed-on"))
    {
      expand_non_prefixed_words = TRUE;
      skip_whitespace();
    }
  else if (strequal(name, "expand-non-prefixed-off"))
    {
      expand_non_prefixed_words = FALSE;
      skip_whitespace();
    }
  else if (strequal(name, "ifdef"))
    {
      read_word(name, MAX_NAME_LEN);
      skip_whitespace();
      if (!is_defined(name))
        {
          skip_if_block(SKIP_TO_ELSE | SKIP_TO_ENDIF);
        }
    }
  else if (strequal(name, "ifndef"))
    {
      read_word(name, MAX_NAME_LEN);
      skip_whitespace();
      if (is_defined(name))
        {
          skip_if_block(SKIP_TO_ELSE | SKIP_TO_ENDIF);
        }
    }
  else if (strequal(name, "if"))
    {
      for(;;)
        {
          skip_whitespace();
          if ((c = mcp_getc()) != '(')
            {
              mcp_ungetc(c);
              error("Expected (", current_file, current_line);
            }
          parse_exp(name);
          if ((c = mcp_getc()) != ')')
            {
              mcp_ungetc(c);
              error("Expected )", current_file, current_line);
            }
          skip_whitespace();
          if (name[0] != '\0')
            break;
          if (skip_if_block(SKIP_TO_ELSEIF | SKIP_TO_ELSE | SKIP_TO_ENDIF) !=
              SKIP_TO_ELSEIF)
            {
              break;
            }
        }
    }
  else if (strequal(name, "else") || strequal(name, "elseif"))
    {
      skip_if_block(SKIP_TO_ENDIF);
    }
  else if (strequal(name, "endif"))
    {
      skip_whitespace();
      /* do nothing */
    }
  else if (strequal(name, "set-macro-char"))
    {
      skip_whitespace();
      macro_char = mcp_getc();
      skip_whitespace();
    }
  else if (strequal(name, "#"))
    { /* a comment */
      c = mcp_getc();
      while (c != '\n')
        c = mcp_getc();
    }
  else if (strequal(name, "("))
    {
      str = (char*) checked_malloc(MAX_NAME_LEN + 1);
      parse_exp(str);
      if ((c = mcp_getc()) != ')')
        {
          mcp_ungetc(c);
          error("Missing closing bracket: )", current_file, current_line);
        }
      if (b_output)
        {
          fputs(str, output);
          free(str);
          str = NULL;
        }
      skip_non_eol_whitespace(); /* non-eol to work in &define */
    }
  else if (strequal(name, "NULL"))
    {
      if (!b_output)
        {
          str = (char*) checked_malloc(1);
          str[0] = '\0';
        }
      skip_non_eol_whitespace(); /* non-eol to work in &define */
    }
  else /* text substitution */
    {
      str = expand(name, b_output, TRUE);
    }
  return str;
}

/* -- end Macro command and substitution parsing -- */



void process_stream()
{
  int c;
  char* str;
  char name[MAX_NAME_LEN + 1];

  assert(output != NULL);

  while (!mcp_eof())
    {
      c = mcp_getc();
      if (c == macro_char)
        {
          str = parse_command(TRUE);
          if (str != NULL)
            {
              fputs(str, output);
              free(str);
            }
        }
      else if (expand_non_prefixed_words && (isalpha(c) || c == '_'))
        {
          mcp_ungetc(c);
          read_word(name, MAX_NAME_LEN);
          expand(name, TRUE, FALSE);
        }
      else if (c != EOF)
        putc(c, output);
    }
}

void init()
{
  local_defines = new_hashtable();
  global_defines = new_hashtable();
  local_macros = new_hashtable();
  global_macros = new_hashtable();
  user_defines = new_hashtable();
}

void init_before_toplevel_file()
{
  expand_non_prefixed_words = global_expand_non_prefixed;
  while (local_stack_top >= 0)
    pop_local_stack();

  assert(local_stack_top == -1);

  if (local_defines != NULL)
    {
      assert(local_macros != NULL);
      assert(global_defines != NULL);
      assert(global_macros != NULL);

      hashtable_destroy(local_defines, TRUE);
      hashtable_destroy(local_macros, TRUE);
      hashtable_destroy(global_defines, TRUE);
      hashtable_destroy(global_macros, TRUE);
    }

  local_defines = new_hashtable();
  local_macros = new_hashtable();
  global_defines = new_hashtable();
  global_macros = new_hashtable();
}

void close_output()
{
  if (output != stdout && output != NULL)
    fclose(output);
}

void cleanup()
{
  hashtable_destroy(local_defines, TRUE);
  hashtable_destroy(global_defines, TRUE);
  hashtable_destroy(local_macros, TRUE);
  hashtable_destroy(global_macros, TRUE);
  hashtable_destroy(user_defines, TRUE);

  close_output();
}

void error_exit()
{
  cleanup();
  exit(3);
}

void print_usage()
{
  fprintf(stderr, "Usage: mcp [options] [input_files]\n");
}

int main(int argc, char **argv)
{
  char *str, *defname, *text;
  const char* ps;
  int i, j, k, len;

  init();

  /* process options */
  i = 1;
  while (i != argc && argv[i][0] == '-')
    {
      if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0)
        {
          print_usage();
          fprintf(stderr,
                  "Processes simple macros in input files or from stdin.\n");
          fprintf(stderr,
                  "Writes output from an input file to an output file with\n");
          fprintf(stderr,
                  "the same name, but with .out appended. If reading from\n");
          fprintf(stderr,
                  "stdin then writes to stdout. If an input file has the\n");
          fprintf(stderr,
                  "extension .mcp then the name of the output file is the\n");
          fprintf(stderr,
                  "name of the input file without '.mcp'.\n");
          fprintf(stderr, "\n");
          fprintf(stderr,
                  "For more information see the README file in the\n");
          fprintf(stderr, "distribution package.\n");
          return 0;
        }
      else if (strcmp(argv[i], "--version") == 0)
        {
          fprintf(stderr, "mcp 0.1.0\n\n");
          fprintf(stderr, "Copyright (C) 2005 by Lukasz Czajka\n");
          fprintf(stderr,
                  "This program is Free Software. It comes WITHOUT ANY WARRANTY.\n");
          fprintf(stderr, "See the COPYING file for details.\n");
          return 0;
        }
      else if (strlen(argv[i]) >= 2 && ((argv[i][0] == '-' && argv[i][1] == 'd') ||
                                        strcmp(argv[i], "--define") == 0))
        { /* a global define */
          if (strcmp(argv[i], "-d") == 0 || strcmp(argv[i], "--define") == 0)
            {
              ++i;
              if (i >= argc)
                {
                  fprintf(stderr, "Expected an argument to the -d option.\n");
                  error_exit();
                }
              ps = argv[i];
            }
          else
            ps = argv[i] + 2;

          len = strlen(ps);
          defname = new_string();
          text = new_string();
          k = -1;
          for (j = 0; j < len; ++j)
            {
              if (ps[j] == '=')
                {
                  if (j + 1 >= MAX_NAME_LEN)
                    {
                      toplevel_fatal_error("Name too long.");
                    }
                  strncpy(defname, ps, j);
                  defname[j] = '\0';
                  k = j + 1;
                  break;
                }
            }
          if (k != -1 && k != len)
            {
              if (len - k + 2 >= MAX_NAME_LEN)
                {
                  toplevel_fatal_error("Name too long.");
                }
              strcpy(text, ps + k);
            }
          else
            {
              if (j + 1 >= MAX_NAME_LEN)
                {
                  toplevel_fatal_error("Name too long.");
                }
              strcpy(defname, ps);
              text[0] = '\0';
            }
          add_user_define(defname, text);
        }
      else if (strcmp(argv[i], "-n") == 0 ||
               strcmp(argv[i], "--non-prefixed") == 0)
        {
          global_expand_non_prefixed = TRUE;
        }
      else if (strcmp(argv[i], "--ignore-case") == 0)
        {
          ignore_case = TRUE;
        }
      else if (strcmp(argv[i], "--") == 0)
        { /* end of options */
          ++i;
          break;
        }
      else if (strcmp(argv[i], "-") == 0)
        { /* a file name - stdin */
          break;
        }
      else
        {
          print_usage();
          error_exit();
        }
      ++i;
    }

  if (i == argc)
    {
      output = stdout;
      init_before_toplevel_file();
      push_input_stack("-");
      process_stream();
      pop_input_stack();
    }
  else
    {
      /* process file names */
      for (; i != argc; ++i)
        {
          if (strcmp(argv[i], "-") == 0)
            {
              output = stdout;
            }
          else
            {
              len = strlen(argv[i]);

              str = (char*) checked_malloc(len + 5);
              if (str == NULL)
                {
                  perror("Out of memory.");
                  abort();
                }
              if (strcmp(argv[i] + len - 4, ".mcp") == 0)
                {
                  strncpy(str, argv[i], len - 4);
                  str[len - 4] = '\0';
                }
              else
                sprintf(str, "%s.out", argv[i]);

              close_output();
              output = fopen(str, "w");
              if (output == NULL)
                {
                  fprintf(stderr, "Cannot open file %s; %s\n", str,
                          strerror(errno));
                  free(str);
                  error_exit();
                }
              free(str);
            }
          init_before_toplevel_file();
          push_input_stack(argv[i]);
          process_stream();
          pop_input_stack();
        }
    }

  cleanup();
  return 0;
}
