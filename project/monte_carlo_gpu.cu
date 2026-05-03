#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <curand_kernel.h>

#define THREADS 256
#define BLOCKS  1024

__global__ void pi_kernel(long n_per_thread, unsigned long long *d_out) {
    __shared__ unsigned long long smem[THREADS];
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int lid = threadIdx.x;

    curandState rng;
    curand_init(42ULL, tid, 0, &rng);

    unsigned long long count = 0;
    for (long i = 0; i < n_per_thread; i++) {
        float x = curand_uniform(&rng);
        float y = curand_uniform(&rng);
        count += (x*x + y*y <= 1.0f);
    }

    smem[lid] = count;
    __syncthreads();
    for (int s = blockDim.x/2; s > 0; s >>= 1) {
        if (lid < s) smem[lid] += smem[lid + s];
        __syncthreads();
    }
    if (lid == 0) d_out[blockIdx.x] = smem[0];
}

__global__ void option_kernel(long n_per_thread,
                               double S, double K, double r,
                               double sigma, double T,
                               double *d_payoffs) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    curandState rng;
    curand_init(99ULL, tid, 0, &rng);

    double sum = 0.0, drift = (r-0.5*sigma*sigma)*T, vol = sigma*sqrt(T);
    for (long i = 0; i < n_per_thread; i++) {
        float u1 = curand_uniform(&rng);
        float u2 = curand_uniform(&rng);
        double z  = sqrt(-2.0*log(u1)) * cos(2.0*M_PI*u2);
        double ST = S * exp(drift + vol*z);
        double p  = ST - K;
        sum += (p > 0.0) ? p : 0.0;
    }
    d_payoffs[tid] = sum;
}

int main(int argc, char *argv[]) {
    long n = (argc > 1) ? atol(argv[1]) : 100000000L;
    long total_threads = BLOCKS * THREADS;
    long n_per_thread  = (n + total_threads - 1) / total_threads;

    unsigned long long *d_pi;
    cudaMalloc(&d_pi, BLOCKS * sizeof(unsigned long long));

    cudaEvent_t t0, t1; float ms;
    cudaEventCreate(&t0); cudaEventCreate(&t1);

    cudaEventRecord(t0);
    pi_kernel<<<BLOCKS,THREADS>>>(n_per_thread, d_pi);
    cudaEventRecord(t1); cudaEventSynchronize(t1);
    cudaEventElapsedTime(&ms, t0, t1);

    unsigned long long h_pi[BLOCKS];
    cudaMemcpy(h_pi, d_pi, BLOCKS*sizeof(unsigned long long), cudaMemcpyDeviceToHost);
    unsigned long long hits = 0;
    for (int i=0;i<BLOCKS;i++) hits+=h_pi[i];
    double pi = 4.0 * hits / ((double)n_per_thread * total_threads);
    printf("GPU_PI,  n=%ld, pi=%.6f,  time=%.1fms",n,pi,ms);

    double *d_pay;
    cudaMalloc(&d_pay, total_threads*sizeof(double));

    cudaEventRecord(t0);
    option_kernel<<<BLOCKS,THREADS>>>(n_per_thread,100,100,0.05,0.2,1.0,d_pay);
    cudaEventRecord(t1); cudaEventSynchronize(t1);
    cudaEventElapsedTime(&ms, t0, t1);

    double *h_pay = (double*)malloc(total_threads*sizeof(double));
    cudaMemcpy(h_pay, d_pay, total_threads*sizeof(double), cudaMemcpyDeviceToHost);
    double psum = 0.0;
    for (long i=0;i<total_threads;i++) psum+=h_pay[i];
    double price = exp(-0.05) * psum / ((double)n_per_thread*total_threads);
    printf("GPU_OPT, n=%ld, call=%.4f, time=%.1fms (exact=10.4506)",n,price,ms);

    cudaFree(d_pi); cudaFree(d_pay); free(h_pay);
    return 0;
}