import sys, re
import matplotlib.pyplot as plt

data = {'CPU_PI':{}, 'GPU_PI':{}, 'CPU_OPT':{}, 'GPU_OPT':{}}
with open(sys.argv[1]) as f:
    for line in f:
        m = re.match(r'(CPU_PI|GPU_PI|CPU_OPT|GPU_OPT),s*n=(d+).*time=([d.]+)ms', line)
        if m:
            data[m.group(1)][int(m.group(2))] = float(m.group(3))

ns = sorted(data['CPU_PI'].keys())

def times(key): return [data[key][n] for n in ns]
def speedup(cpu, gpu): return [data[cpu][n]/data[gpu][n] for n in ns]

fig, axes = plt.subplots(1, 3, figsize=(14, 4))
labels = [f'10^{len(str(n))-1}' for n in ns]

ax = axes[0]
ax.loglog(ns, times('CPU_PI'), 'o-', label='CPU')
ax.loglog(ns, times('GPU_PI'), 's-', label='GPU (A100)')
ax.set_title('Pi estimation — time'); ax.set_ylabel('ms')
ax.set_xlabel('samples'); ax.legend(); ax.grid(alpha=0.3)

ax = axes[1]
ax.loglog(ns, times('CPU_OPT'), 'o-', label='CPU')
ax.loglog(ns, times('GPU_OPT'), 's-', label='GPU (A100)')
ax.set_title('Option pricing — time')
ax.set_xlabel('samples'); ax.legend(); ax.grid(alpha=0.3)

ax = axes[2]
ax.semilogx(ns, speedup('CPU_PI','GPU_PI'),   'o-', label='Pi')
ax.semilogx(ns, speedup('CPU_OPT','GPU_OPT'), 's-', label='Option')
ax.set_title('GPU speedup (CPU/GPU)')
ax.set_xlabel('samples'); ax.set_ylabel('speedup')
ax.legend(); ax.grid(alpha=0.3)

plt.tight_layout()
plt.savefig('results.png', dpi=150)
print('saved results.png')