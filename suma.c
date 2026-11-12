/* suma.c  -- programa bien definido para recorrer las fases de CompCert */
#include <stdio.h>

int suma_cuadrados(int n) {
    int s = 0;
    for (int i = 1; i <= n; i++)
        s += i * i;
    return s;
}

int main(void) {
    printf("suma_cuadrados(10) = %d\n", suma_cuadrados(10));
    return 0;
}
