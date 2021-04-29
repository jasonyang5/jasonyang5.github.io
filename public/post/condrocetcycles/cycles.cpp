#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
IntegerMatrix generate_prefmat(IntegerVector order, int m){
    IntegerMatrix mat(m, m);
    // person prefers order[k] to everything after it
    for (int k = 0; k <= m-2; ++k)
    {
        int best = order[k] - 1;
        for (int k2 = k+1; k2 <= m-1; ++k2)
        {
            int worst = order[k2] - 1;
            mat(best, worst) = 1;
        }
    }
    return mat;
}