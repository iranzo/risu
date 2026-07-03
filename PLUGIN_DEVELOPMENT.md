# Plugin Development Guide

Complete guide to developing Risu plugins for system configuration validation.

## Table of Contents

- [Quick Start](#quick-start)
- [Plugin Anatomy](#plugin-anatomy)
- [Plugin Types](#plugin-types)
- [Priority System](#priority-system)
- [Common Functions](#common-functions)
- [Best Practices](#best-practices)
- [Testing](#testing)
- [Examples](#examples)

---

## Quick Start

### 3-Minute Tutorial: Your First Plugin

```bash
# 1. Create plugin using the scaffolding tool
./tools/risu-plugin-create \
  --name check-selinux-enforcing \
  --priority 850 \
  --category core/security \
  --type bash

# 2. Edit the generated plugin
# (Tool opens it in your $EDITOR automatically)

# 3. Validate the plugin
./tools/validate_plugin.py \
  risuclient/plugins/core/security/check-selinux-enforcing.sh -v

# 4. Test locally
./risu.py -l --include check-selinux-enforcing

# 5. Test against sosreport
./risu.py /path/to/sosreport --include check-selinux-enforcing
```

That's it! You've created, validated, and tested your first plugin.

---

## Plugin Anatomy

Every Risu plugin must include these metadata headers:

```bash
#!/bin/bash
# long_name: Check SELinux is in enforcing mode
# description: Verifies SELinux is set to enforcing for security
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=XXXXX
# priority: 850
# kb: https://access.redhat.com/solutions/XXXXX

# Load common functions
. "${RISU_BASE}/common-functions.sh"

# Check if running on live system or sosreport
if [ "$RISU_LIVE" = 0 ]; then
    FILE="${RISU_ROOT}/etc/selinux/config"
else
    FILE="/etc/selinux/config"
fi

# Verify file exists
is_required_file "$FILE" || exit $RC_SKIPPED

# Perform check
if grep -q "^SELINUX=enforcing" "$FILE"; then
    exit $RC_OKAY
else
    echo "SELinux is not in enforcing mode" >&2
    exit $RC_FAILED
fi
```

### Required Headers

- **long_name**: Descriptive name shown in web UI (60 chars max)
- **description**: What this plugin checks (150 chars max)
- **priority**: Criticality level (1-999, see Priority System below)

### Optional Headers

- **bugzilla**: Related Bugzilla URL
- **kb**: Knowledge Base article URL
- **tags**: Comma-separated tags for filtering

---

## Plugin Types

Risu supports multiple plugin types through its extension system:

### 1. Bash Scripts (Most Common)

**Location**: `risuclient/plugins/core/`
**Extension**: `.sh`
**Use case**: File checks, command output analysis, system state validation

```bash
#!/bin/bash
# Bash plugin example
. "${RISU_BASE}/common-functions.sh"

is_rpm httpd || exit $RC_SKIPPED

if systemctl is-active httpd &>/dev/null; then
    exit $RC_OKAY
else
    echo "Apache is not running" >&2
    exit $RC_FAILED
fi
```

### 2. Python Scripts (Faraday)

**Location**: `risuclient/plugins/faraday/`
**Extension**: `.py`
**Use case**: Complex logic, JSON parsing, API interactions

```python
#!/usr/bin/env python
"""
# long_name: Check Python package versions
# description: Validates critical Python packages
# priority: 600
"""

import sys


def main():
    try:
        import requests

        if requests.__version__ < "2.20":
            print("requests version too old", file=sys.stderr)
            return 20  # RC_FAILED
        return 10  # RC_OKAY
    except ImportError:
        return 30  # RC_SKIPPED


if __name__ == "__main__":
    sys.exit(main())
```

### 3. Ansible Playbooks

**Location**: `risuclient/plugins/ansible/`
**Extension**: `.yml`
**Use case**: Configuration management checks, multi-step validation

```yaml
---
# long_name: Check NTP configuration
# description: Validates NTP is configured correctly
# priority: 800

- hosts: localhost
  gather_facts: true
  tasks:
    - name: Check chronyd service
      service:
        name: chronyd
        state: started
      register: result
      failed_when: false

    - name: Report status
      debug:
        msg: "NTP service {{ 'running' if result.state == 'started' else 'not running' }}"
```

### 4. Go Plugins

**Location**: `risuclient/plugins/golang/`
**Extension**: Compiled binary
**Use case**: High-performance checks, binary analysis

---

## Priority System

Priorities determine execution order and criticality (1-999 scale):

| Range   | Category   | Description                    | Examples                           |
| ------- | ---------- | ------------------------------ | ---------------------------------- |
| 900-999 | Critical   | System can break at any moment | Filesystem corruption, etcd health |
| 800-899 | High       | Core system services at risk   | Network, systemd, node health      |
| 600-799 | Medium     | Applications & services        | OpenStack, OpenShift, databases    |
| 400-599 | Medium-Low | Middleware & support services  | Message queues, caching            |
| 200-399 | Low        | Monitoring & logging systems   | Metrics, log aggregation           |
| 100-199 | Very Low   | Informational checks           | Version detection, inventory       |
| 1-99    | Metadata   | Metadata collection            | System facts, discovery            |

### How to Choose Priority

1. **Does failure cause immediate system breakage?** → 900-999
2. **Does it affect core OS functionality?** → 800-899
3. **Is it a critical service/application?** → 600-799
4. **Is it middleware or supporting infrastructure?** → 400-599
5. **Is it monitoring/logging?** → 200-399
6. **Is it purely informational?** → 100-199
7. **Is it metadata/discovery?** → 1-99

---

## Common Functions

Bash plugins can use helper functions from `common-functions.sh`:

### File Checks

```bash
is_required_file /etc/my.cnf          # Skip if file missing
is_mandatory_file /etc/passwd         # Fail if file missing
is_lineinfile "^Port 22" /etc/ssh/sshd_config
```

### Package Checks

```bash
is_rpm httpd                          # Check RPM installed
is_rpm_over httpd 2.4.6               # Check version >= 2.4.6
is_dpkg apache2                       # Check Debian package
```

### Service Checks

```bash
is_active httpd                       # Check systemd service active
is_enabled sshd                       # Check systemd service enabled
is_process mysqld                     # Check process running
```

### Container Checks

```bash
is_containerized                      # Running in container?
docker_runit containerid              # Run command in container
```

### Version Detection

```bash
discover_osp_version                  # Detect OpenStack version
discover_rhrelease                    # Detect RHEL version
```

### Content Parsing

```bash
iniparser /etc/my.cnf mysqld port     # Parse INI files
```

See `risuclient/common-functions.sh` for complete list.

---

## Best Practices

### 1. Always Check File Existence

```bash
# ❌ DON'T
grep "pattern" /etc/config

# ✅ DO
is_required_file /etc/config || exit $RC_SKIPPED
grep "pattern" /etc/config
```

### 2. Write Errors to stderr

```bash
# ❌ DON'T
echo "Error: Service not running"
exit $RC_FAILED

# ✅ DO
echo "Error: Service not running" >&2
exit $RC_FAILED
```

### 3. Support Both Live and Sosreport Modes

```bash
# ✅ DO
if [ "$RISU_LIVE" = 0 ]; then
    FILE="${RISU_ROOT}/etc/config"
else
    FILE="/etc/config"
fi
```

### 4. Handle Missing Dependencies Gracefully

```bash
# ✅ DO
is_rpm postgresql || exit $RC_SKIPPED

# Now safe to run postgres-specific checks
```

### 5. Avoid Expensive Operations in Loops

```bash
# ❌ DON'T
for file in /var/log/*.log; do
    cat "$file" | grep pattern  # Spawns cat for each file
done

# ✅ DO
grep pattern /var/log/*.log  # Single grep process
```

### 6. Use RC_ Constants

```bash
# ❌ DON'T
exit 0    # Ambiguous
exit 1    # Not the Risu convention

# ✅ DO
exit $RC_OKAY     # 10 - Check passed
exit $RC_FAILED   # 20 - Check failed
exit $RC_SKIPPED  # 30 - Not applicable
exit $RC_INFO     # 40 - Informational
```

---

## Testing

### Local Testing

```bash
# Test on live system
./risu.py -l --include myplugin

# Test specific category
./risu.py -l --include core/security

# Test with debug output
RISU_DEBUG=1 ./risu.py -l --include myplugin
```

### Sosreport Testing

```bash
# Test against sosreport
./risu.py /path/to/sosreport --include myplugin

# Test with JSON output
./risu.py /path/to/sosreport --include myplugin --output results.json
```

### Validation

```bash
# Validate plugin metadata
./tools/validate_plugin.py risuclient/plugins/core/myarea/myplugin.sh

# Run shellcheck (if available)
shellcheck -x risuclient/plugins/core/myarea/myplugin.sh
```

### Unit Testing

Create tests in `tests/plugins-unit-tests/`:

```python
import unittest
from risuclient import shell


class TestMyPlugin(unittest.TestCase):
    def test_plugin_returns_expected_rc(self):
        result = shell.run_plugin("core/myarea/myplugin.sh")
        self.assertIn(result["result"], [10, 20, 30, 40])
```

### Debugging

Use the debug environment:

```bash
# Source debug environment
source ./env-for-debug.sh

# Now you can test common functions
is_rpm qemu-kvm-rhev && echo "Package installed"

# Run plugin with bash debug
sh -x risuclient/plugins/core/myarea/myplugin.sh
```

---

## Examples

### Example 1: Check Configuration File

```bash
#!/bin/bash
# long_name: Check sshd permits root login
# description: Verifies SSH doesn't allow direct root login
# priority: 850

. "${RISU_BASE}/common-functions.sh"

FILE="${RISU_ROOT}/etc/ssh/sshd_config"
is_required_file "$FILE" || exit $RC_SKIPPED

if is_lineinfile "^PermitRootLogin no" "$FILE"; then
    exit $RC_OKAY
else
    echo "SSH permits root login (security risk)" >&2
    exit $RC_FAILED
fi
```

### Example 2: Check Package Version

```bash
#!/bin/bash
# long_name: Check kernel version is recent
# description: Verifies kernel is not EOL
# priority: 800

. "${RISU_BASE}/common-functions.sh"

MIN_VERSION="3.10.0-1127"
is_rpm kernel || exit $RC_SKIPPED

if is_rpm_over kernel "$MIN_VERSION"; then
    exit $RC_OKAY
else
    echo "Kernel version below minimum ($MIN_VERSION)" >&2
    exit $RC_FAILED
fi
```

### Example 3: Check Service State

```bash
#!/bin/bash
# long_name: Check firewalld is running
# description: Verifies firewall is active
# priority: 850

. "${RISU_BASE}/common-functions.sh"

if [ "$RISU_LIVE" = 0 ]; then
    # In sosreport, check service file
    is_required_file "${RISU_ROOT}/etc/systemd/system/firewalld.service" || exit $RC_SKIPPED
    exit $RC_INFO
else
    # On live system, check actual state
    if is_active firewalld; then
        exit $RC_OKAY
    else
        echo "Firewalld is not running" >&2
        exit $RC_FAILED
    fi
fi
```

More examples in `doc/examples/`.

---

## Troubleshooting

### Common Errors

**"permission denied"**

```bash
# Fix: Make plugin executable
chmod +x risuclient/plugins/core/myarea/myplugin.sh
```

**"command not found: is_rpm"**

```bash
# Fix: Load common functions
. "${RISU_BASE}/common-functions.sh"
```

**"Plugin returns exit code 0"**

```bash
# Fix: Use RC_ constants, not raw numbers
exit $RC_OKAY  # Not exit 0
```

### Debugging Tips

1. **Check RISU_BASE is set**: `echo $RISU_BASE`
2. **Verify file paths**: Use `RISU_ROOT` prefix for sosreport files
3. **Test manually**: Source `env-for-debug.sh` and run functions
4. **Check logs**: Run with `--debug` flag for verbose output
5. **Validate metadata**: Run `validate_plugin.py` before committing

---

## Extension Development

Want to create a new plugin type? See:

- `doc/development/extension-development.md` - Extension API guide
- `risuclient/extensions/base.py` - Base extension class
- Existing extensions in `risuclient/extensions/` for examples

---

## Further Reading

- **Templates**: `doc/templates/README.md` - Template usage guide
- **Architecture**: `ARCHITECTURE.md` - Framework architecture
- **Contributing**: `CONTRIBUTING.md` - Contribution guidelines
- **API**: `risuclient/extensions/` - Extension system API

---

**Need help?** Open an issue at https://github.com/risuorg/risu/issues
