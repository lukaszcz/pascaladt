
#include "hashtable/hashtable.h"

#define TRUE 1
#define FALSE 0

#define MAX_NAME_LEN 256
#define HASH_TABLE_SIZE 509
#define MAX_FILENAME_LEN 256
#define MAX_INCLUDE_LEVELS 256
/* MAX_LOCAL_LEVELS is the maximum number of macro invocations and
   includes taken together  */
#define MAX_LOCAL_LEVELS 4*MAX_INCLUDE_LEVELS

/* -- Checked alocation -- */

/* Aborts if not enough memory. */
void *checked_malloc(size_t size);
/* Aborts if not enough memory. */
void *checked_realloc(void *ptr, size_t size);

/* -- String management -- */
/* Allocates a new string. */
char *new_string();
/* Checks if str1 == str2, taking ignore_case into account.  */
int strequal(void *str1, void *str2);
/* Ignore case? */
extern int ignore_case;

/* -- Error reporting -- */

/* Gives a fatal error error to stderr and aborts. */
void toplevel_fatal_error(const char *error);
/* Gives a fatal error from file:line */
void fatal_error(const char *msg, const char *file, int line);
/* Gives an ordinary error from file:line */
void error(const char *msg, const char *file, int line);
/* Gives a warning from file:line */
void warning(const char *msg, const char *file, int line);

/* -- Hash tables -- */

typedef struct hashtable hashtable_t;

/* Creates a new hashtable for string keys and arbitrary items. */
hashtable_t *new_hashtable();
