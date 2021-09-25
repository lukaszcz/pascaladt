
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "hashtable/fnv.h"
#include "utils.h"

int ignore_case = FALSE;

static const char *check_for_stdin(const char *file)
{
  if (strcmp(file, "-") == 0)
    return "stdin";
  else
    return file;
}

void *checked_malloc(size_t size)
{
  void* ptr = malloc(size);
  if (ptr == NULL)
    {
      perror("mcp: Cannot allocate memory");
      abort();
    }
  return ptr;
}

void *checked_realloc(void *ptr, size_t size)
{
  ptr = realloc(ptr, size);
  if (ptr == NULL)
    {
      perror("mcp: Cannot reallocate memory");
      abort();
    }
  return ptr;
}

void toplevel_fatal_error(const char *error)
{
  fprintf(stderr, "mcp: Fatal error: %s\n", error);
  abort();
}

void fatal_error(const char *msg, const char *file, int line)
{
  fprintf(stderr, "%s:%d: Fatal error: %s\n", check_for_stdin(file), line, msg);
  abort();
}

void error(const char *msg, const char *file, int line)
{
  fprintf(stderr, "%s:%d: Error: %s\n", check_for_stdin(file), line, msg);
}

void warning(const char *msg, const char *file, int line)
{
  fprintf(stderr, "%s:%d: Warning: %s\n", check_for_stdin(file), line, msg);
}

char *new_string()
{
  return (char*) checked_malloc(MAX_NAME_LEN + 1);
}

int strequal(void *ptr1, void *ptr2)
{
  if (ignore_case)
    {
      const char *str1 = (const char*) ptr1;
      const char *str2 = (const char*) ptr2;
      while (*str1 && tolower(*(str1)) == tolower(*(str2)))
	{
	  ++str1; ++str2;
	}
      return *str1 == '\0' && *str2 == '\0';
    }
  else
    return strcmp((char*) ptr1, (char*) ptr2) == 0;
}

hashtable_t *new_hashtable()
{
  return create_hashtable(HASH_TABLE_SIZE, hash_str, strequal);
}

