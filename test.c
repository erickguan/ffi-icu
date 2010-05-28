#include <unicode/unorm.h>
#include <unicode/ustdio.h>
#include <stdio.h>
#include <stdarg.h>
#include <iconv.h>
#include <string.h>
#include <stdlib.h>

void print_uchars(UChar *str) {
  UFILE *out = u_finit(stdout, NULL, NULL);
  u_fprintf(out, "uchars: %S\n", str);
  u_fclose(out);
}

void print_error(UErrorCode status) {
  printf("err: %s (%d)\n", u_errorName(status), status);
}

int main (int argc, char const *argv[])
{

  UTransliterator* trans = NULL;
  UErrorCode status = U_ZERO_ERROR;

  trans = utrans_open("Any-Hex", UTRANS_FORWARD, NULL, 0, NULL, &status);
  if(U_FAILURE(status)) {
    print_error(status);
    exit(1);
  }

  UChar from[256];
  UChar buf[6];

  int32_t text_length, limit;

  u_uastrcpy(from, "abcde");
  u_strcpy(buf, from);

  limit = text_length = u_strlen(buf);
  printf("limit: %d\n", limit);
  printf("text_length: %d\n", limit);

  utrans_transUChars(trans, buf, &text_length, 256, 0, &limit, &status);

  printf("uchar ptr length after: %d\n", u_strlen(buf));
  printf("text_length after: %d\n", text_length);

  if(U_FAILURE(status)) {
    print_error(status);
    exit(1);
  }

  print_uchars(buf);

  return 0;
}
