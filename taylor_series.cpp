#include <stdint.h>
// loop for N-series until your computer dies or your mom throws you out of her basement.
int64_t what_the_fuck(uint64_t x, uint64_t k) { 
    /*
      enjoy ur overflow: 
      could probably store/read overflowed data in a sort of "pseduo" sum.
     */

    // x ^ k
    uint64_t res = 1, base = x, exp = k;

    while (exp) {
        if (exp & 1) { res *= base; }

        base *= base;
        exp >>= 1; // next
    }

    // k!
    uint64_t fact = 1;

    if (k < 0) {
        fact = -1;
    } else if (k == 0) {
        fact = 1;    
    } else {
        for (int i = 1; i <= k; i++) {
            fact *= i;
        }
    }

    return (int64_t)res / fact; // is this even real?
}



