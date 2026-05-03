#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

double pi_estimate(long n_samples) {
    long inside = 0;
    for (long i = 0; i < n_samples; i++) {
        double x = (double)rand() / RAND_MAX;
        double y = (double)rand() / RAND_MAX;
        if (x*x + y*y <= 1.0) inside++;
    }
    return 4.0 * inside / n_samples;
}

double box_muller() {
    double u1 = (double)rand() / RAND_MAX + 1e-10;
    double u2 = (double)rand() / RAND_MAX;
    return sqrt(-2.0 * log(u1)) * cos(2.0 * M_PI * u2);
}

double option_price(long n, double S, double K,
                    double r, double sigma, double T) {
    double payoff_sum = 0.0;
    double drift = (r - 0.5*sigma*sigma)*T;
    double vol   = sigma * sqrt(T);
    for (long i = 0; i < n; i++) {
        double z  = box_muller();
        double ST = S * exp(drift + vol*z);
        double p  = ST - K;
        payoff_sum += (p > 0.0) ? p : 0.0;
    }
    return exp(-r*T) * payoff_sum / n;
}



int main(int argc, char *argv[]) {
    long n = (argc > 1) ? atol(argv[1]) : 100000000L;
    srand(42);

    struct timespec t0, t1;

    clock_gettime(CLOCK_MONOTONIC, &t0);
    double pi = pi_estimate(n);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    double pi_ms = (t1.tv_sec-t0.tv_sec)*1000.0+(t1.tv_nsec-t0.tv_nsec)/1e6;

    clock_gettime(CLOCK_MONOTONIC, &t0);
    double price = option_price(n,100,100,0.05,0.2,1.0);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    double opt_ms = (t1.tv_sec-t0.tv_sec)*1000.0+(t1.tv_nsec-t0.tv_nsec)/1e6;

    printf("CPU_PI,  n=%ld, pi=%.6f,  time=%.1fms", n, pi, pi_ms);
    printf("CPU_OPT, n=%ld, call=%.4f, time=%.1fms (exact=10.4506)", n, price, opt_ms);
    return 0;
}