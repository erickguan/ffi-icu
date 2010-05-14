#include <unicode/unorm.h>
#include <unicode/ustdio.h>
#include <stdio.h>
#include <stdarg.h>
#include <iconv.h>
#include <string.h>
#include <stdlib.h>

void print_uchars(UChar *str) {
  UFILE *out = u_finit(stdout, NULL, NULL);
  u_fprintf(out, "uchars: %S", str);
  u_fclose(out);
}

void print_error(UErrorCode status) {
  printf("err: %s (%d)\n", u_errorName(status), status);
}

int main (int argc, char const *argv[])
{

  UTransliterator* trans = NULL;
  UErrorCode status = U_ZERO_ERROR;
  
  trans = utrans_open("Lower", UTRANS_FORWARD, NULL, 0, NULL, &status);
  
  UChar from[256];
  UChar to[256];
  UChar buf[256];
  
  u_uastrcpy(from, "ABC");
  u_uastrcpy(to, "abc");

  u_strcpy(buf, from);
  int32_t limit = u_strlen(buf);
  
  utrans_transUChars(trans, buf, NULL, 256, 0, &limit, &status);
  
  if(U_FAILURE(status)) {
    print_error(status);
    exit(1);
  }
  
  print_uchars(buf);
  
  return 0;
}