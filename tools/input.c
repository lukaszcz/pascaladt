
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <assert.h>
#include "utils.h"
#include "input.h"

#define INITIAL_BUFFER_SIZE 1000

int current_line = 0;
char *current_file = NULL;

typedef struct{
  /* The characters in the buffer. */
  char *str;
  /* The current position within the buffer (i.e. the position at
     which the next char will be read). If the buffer is empty then
     pos > last.  */
  int pos;
  /* The current last position within the buffer (i.e. up to this
     position (included) characters are stored) */
  int last;
  /* The amount of bytes currently allocated for str. */
  unsigned size;
} buffer_t;

/* The buffer for the current file. */
static buffer_t *buffer;

/* The input stream. */
static FILE *input = NULL;

/* The stack of 'old' input streams. */
static FILE *input_stack[MAX_INCLUDE_LEVELS];
static buffer_t *buffer_stack[MAX_INCLUDE_LEVELS];
static int input_line_stack[MAX_INCLUDE_LEVELS];
static char *input_files_stack[MAX_INCLUDE_LEVELS];
static int input_stack_top = -2;

static void grow_buffer()
{
  assert(buffer != NULL);
  assert(buffer->str != NULL);

  buffer->pos += buffer->size;
  buffer->last += buffer->size;
  buffer->str = checked_realloc(buffer->str, buffer->size <<= 1);
  memcpy(buffer->str + (buffer->size >> 1), buffer->str, buffer->size >> 1);

  assert(buffer->pos >= 0);
  assert(buffer->last = buffer->size - 1);
}

static buffer_t *new_buffer()
{
  buffer_t *result = (buffer_t*) checked_malloc(sizeof(buffer_t));
  result->str = (char*) checked_malloc(INITIAL_BUFFER_SIZE);
  result->size = INITIAL_BUFFER_SIZE;
  result->pos = result->size;
  result->last = result->size - 1;
  return result;
}

static void free_buffer(buffer_t *buf)
{
  assert(buf != NULL);
  assert(buf->str != NULL);
  free(buf->str);
  free(buf);
}

int mcp_getc()
{
  int c;
  if (buffer->pos <= buffer->last)
    {
      return buffer->str[buffer->pos++];
    }
  else
    {
      c = getc(input);
      if (c == '\n')
	++current_line;
      return c;
    }
}

void mcp_ungetc(int c)
{
  assert(buffer != NULL);

  if (buffer->pos <= buffer->last)
    {
      if (buffer->pos == 0)
	grow_buffer();
      buffer->str[--buffer->pos] = c;
    }
  else
    {
      buffer->pos = buffer->last = buffer->size - 1;
      buffer->str[buffer->pos] = c;
    }
}

void mcp_ungets(const char *str)
{
  int i;

  if (buffer->pos > buffer->last)
    {
      buffer->pos = buffer->size;
      buffer->last = buffer->size - 1;
    }

  i = strlen(str) - 1;
  while (i >= 0)
    {
      if (buffer->pos == 0)
	grow_buffer();
      buffer->str[--buffer->pos] = str[i--];
    }
}

int mcp_eof()
{
  return feof(input) && buffer->pos > buffer->last;
}

void push_input_stack(const char *filename)
{
  char buf[MAX_NAME_LEN*3];

  assert(strlen(filename) <= MAX_NAME_LEN);

  if (input_stack_top + 1 >= MAX_INCLUDE_LEVELS)
    {
      sprintf(buf, "Cannot include file %s. Maximum nested include level is %d.",
	      filename, MAX_INCLUDE_LEVELS);
      fatal_error(buf, current_file, current_line);
    }

  ++input_stack_top;
  if (input_stack_top >= 0)
    {
      input_stack[input_stack_top] = input;
      buffer_stack[input_stack_top] = buffer;
      input_files_stack[input_stack_top] = current_file;
      input_line_stack[input_stack_top] = current_line;
    }

  if (strcmp(filename, "-") == 0)
    {
      input = stdin;
    }
  else
    {
      input = fopen(filename, "r");
      if (input == NULL)
	{
	  sprintf(buf, "Cannot open file: %s; %s\n", filename, strerror(errno));
	  toplevel_fatal_error(buf);
	}
    }

  current_file = new_string();
  strcpy(current_file, filename);
  current_line = 1;
  buffer = new_buffer();
}

void pop_input_stack()
{
  assert(input_stack_top >= -1);

  if (input != stdin)
    fclose(input);
  if (current_file != NULL)
    free(current_file);
  if (buffer != NULL)
    free_buffer(buffer);
  
  if (input_stack_top >= 0)
    {
      current_line = input_line_stack[input_stack_top];
      current_file = input_files_stack[input_stack_top];
      buffer = buffer_stack[input_stack_top];
      input = input_stack[input_stack_top];
    }
  else
    {
      assert(input_stack_top = -1);
      input = NULL;
      buffer = NULL;
      current_file = NULL;
      current_line = 0;
    }
  --input_stack_top;
}

void skip_whitespace()
{
  int c;
  c = mcp_getc();
  while (isspace(c))
    c = mcp_getc();

  if (c != EOF)
    mcp_ungetc(c);
}

void skip_non_eol_whitespace()
{
  int c;
  c = mcp_getc();
  while (isspace(c) && c != '\n')
    c = mcp_getc();

  if (c != EOF)
    mcp_ungetc(c);
}

void input_cleanup()
{
  if (buffer != NULL)
    free_buffer(buffer);
}

