import sys
import matplotlib.pyplot as plt

cpu_times = []
gpu_times = []
ns = []

with open(sys.argv[1], encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

i = 0
while i < len(lines):
    line = lines[i].strip()
    if line.startswith('=== N='):
        n = int(line.replace('=== N=','').replace(' ===',''))
        cpu_line = lines[i+1].strip() if i+1 < len(lines) else ''
        gpu_line = lines[i+2].strip() if i+2 < len(lines) else ''

        # parse CPU time (in seconds)
        if 'time:' in cpu_line:
            t = cpu_line.split('time:')[-1].strip().replace('s','')
            cpu_times.append(float(t) * 1000)  # convert to ms
            ns.append(n)

        # parse GPU time (in ms)
        if 'time:' in gpu_line:
            t = gpu_line.split('time:')[-1].strip().replace('ms','')
            gpu_times.append(float(t))
    i += 1

print("ns:", ns)
print("cpu_times:", cpu_times)
print("gpu_times:", gpu_times)

speedups = [c/g for c,g in zip(cpu_times, gpu_times)]

fig, axes = plt.subplots(1, 2, figsize=(12, 4))

ax = axes[0]
ax.loglog(ns, cpu_times, 'o-', label='CPU')
ax.loglog(ns, gpu_times, 's-', label='GPU (A100)')
ax.set_title('Pi estimation — time'); ax.set_ylabel('ms')
ax.set_xlabel('samples'); ax.legend(); ax.grid(alpha=0.3)

ax = axes[1]
ax.semilogx(ns, speedups, 'D-', color='#185FA5')
ax.set_title('GPU speedup (CPU/GPU)')
ax.set_xlabel('samples'); ax.set_ylabel('speedup')
ax.grid(alpha=0.3)

plt.tight_layout()
plt.savefig('results.png', dpi=150)
print('saved results.png')