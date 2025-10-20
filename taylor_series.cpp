#include <stdint.h>
typedef struct {
	uint64_t k;
	uint64_t num;       /* x^k (wrapped) */
	unsigned num_hi;    /* high 64 bits of product accum. (approx if no int128) */
	uint64_t den;       /* k! (wrapped) */
	unsigned den_hi;
	int64_t  log2_num;  /* sum floor_log2 contributions */
	int64_t  log2_den;
	uint64_t term;      /* (x^k / k!) integer */
	uint64_t sum;       /* running sum (wrapped) */
} TermTrace;

#include <stdint.h>
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

    return (int64_t)res / fact; // is this real?
}
