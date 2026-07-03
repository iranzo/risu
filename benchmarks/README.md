# Risu Performance Benchmarks

This directory contains performance benchmark baselines for Risu plugin execution.

## Baseline Files

- `baseline-py310.json` - Python 3.10 performance baseline
- `baseline-py313.json` - Python 3.13 performance baseline

## Running Benchmarks

```bash
# Run benchmark
python tools/benchmark_plugins.py --iterations 3

# Compare against baseline
python tools/compare_benchmarks.py benchmarks/baseline-py313.json benchmark.json
```

## Benchmark Format

```json
{
  "timestamp": "2026-07-03T16:00:00Z",
  "python_version": "3.13",
  "plugins_tested": 250,
  "total_time_seconds": 45.3,
  "avg_time_per_plugin": 0.18,
  "median_time": 0.12,
  "slowest_plugins": [
    { "name": "plugin1.sh", "time": 12.5, "category": "core/system" },
    { "name": "plugin2.sh", "time": 8.3, "category": "core/openstack" }
  ]
}
```

## CI Integration

Performance benchmarks run automatically in CI on:

- Pull requests (compared against master baseline)
- Weekly schedule (Monday 2am UTC)
- Manual workflow dispatch

See `.github/workflows/performance-tests.yml` for configuration.
