
/*
 * Buffered input for the mcp macro processor.
 */

/* The current line in the current file. Read-only. */
extern int current_line;
/* The name of the current file. Read-only. */
extern char *current_file;

/* -- Input functions -- */

int mcp_getc();
/* Accepts any number of consecutive calls */
void mcp_ungetc(int c);
void mcp_ungets(const char *str);
int mcp_eof();
/* Sets the input file used by the input functions of this
   module. Remember to call pop_input_stack() later. If input is
   already non-void then _saves_ the old input stream on a stack and
   pops it when the new stream is closed via
   pop_input_stack(). filename may be "-" to indicate stdin. */
void push_input_stack(const char *filename);
void pop_input_stack();
/* Skips whitespace on input. */
void skip_whitespace();
/* Smae as above, but doesn't consider \n to be whitespace.  */
void skip_non_eol_whitespace();
/* Cleans up in the module.  */
void input_cleanup();
