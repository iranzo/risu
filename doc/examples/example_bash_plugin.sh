#!/bin/bash
# Example Risu bash plugin with comprehensive comments
#
# This example demonstrates all major features of Risu bash plugins:
# - Required metadata headers
# - Common function usage
# - Live vs sosreport mode handling
# - Proper error handling
# - Exit code usage

# =============================================================================
# METADATA HEADERS (Required)
# =============================================================================

# long_name: Example Plugin - Check Service Configuration
# description: Demonstrates bash plugin best practices with service check
# priority: 750
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=000000
# kb: https://access.redhat.com/solutions/000000

# =============================================================================
# COMMON FUNCTIONS
# =============================================================================

# Load Risu common functions library
# This provides: is_rpm, is_required_file, is_lineinfile, is_active, etc.
. "${RISU_BASE}/common-functions.sh"

# =============================================================================
# CONFIGURATION
# =============================================================================

SERVICE_NAME="httpd"
CONFIG_FILE="/etc/httpd/conf/httpd.conf"
MIN_VERSION="2.4.6"

# =============================================================================
# ENVIRONMENT DETECTION
# =============================================================================

# RISU_LIVE: 0 = sosreport mode, 1 = live system
# RISU_ROOT: Root of filesystem being analyzed
# RISU_BASE: Risu framework installation directory

if [ "$RISU_LIVE" = 0 ]; then
	# Sosreport mode - prepend RISU_ROOT to all paths
	CONFIG_PATH="${RISU_ROOT}${CONFIG_FILE}"
	MODE="sosreport"
else
	# Live system mode - use absolute paths
	CONFIG_PATH="$CONFIG_FILE"
	MODE="live"
fi

# =============================================================================
# DEPENDENCY CHECKS
# =============================================================================

# Check if required package is installed
# If not installed, skip this check (not applicable)
if ! is_rpm "$SERVICE_NAME"; then
	echo "$SERVICE_NAME package not installed, skipping check" >&2
	exit $RC_SKIPPED
fi

# Check if package meets minimum version requirement
if ! is_rpm_over "$SERVICE_NAME" "$MIN_VERSION"; then
	echo "$SERVICE_NAME version below $MIN_VERSION" >&2
	exit $RC_FAILED
fi

# =============================================================================
# FILE CHECKS
# =============================================================================

# Verify configuration file exists
# is_required_file exits with RC_SKIPPED if file not found
is_required_file "$CONFIG_PATH" || exit $RC_SKIPPED

# =============================================================================
# CONFIGURATION VALIDATION
# =============================================================================

# Check for required configuration directive
if ! is_lineinfile "^ServerTokens Prod" "$CONFIG_PATH"; then
	echo "ServerTokens not set to 'Prod' in $CONFIG_FILE" >&2
	exit $RC_FAILED
fi

# Check for problematic configuration
if is_lineinfile "^ServerSignature On" "$CONFIG_PATH"; then
	echo "ServerSignature should be Off for security" >&2
	exit $RC_FAILED
fi

# =============================================================================
# SERVICE STATE CHECKS (Live mode only)
# =============================================================================

if [ "$RISU_LIVE" = 1 ]; then
	# On live system, check actual service state
	if ! is_active "$SERVICE_NAME"; then
		echo "$SERVICE_NAME service is not running" >&2
		exit $RC_FAILED
	fi

	# Check if service is enabled at boot
	if ! is_enabled "$SERVICE_NAME"; then
		echo "$SERVICE_NAME service is not enabled at boot" >&2
		# This is a warning, not a failure
		echo "WARNING: Service should be enabled" >&2
		exit $RC_INFO
	fi
else
	# In sosreport mode, we can't check live service state
	# Just report configuration is valid
	echo "Configuration validated (service state check requires live mode)" >&2
	exit $RC_INFO
fi

# =============================================================================
# SUCCESS
# =============================================================================

# All checks passed
exit $RC_OKAY

# =============================================================================
# EXIT CODES REFERENCE
# =============================================================================
# RC_OKAY=10     - Check passed, no issues found
# RC_FAILED=20   - Check failed, issue detected
# RC_SKIPPED=30  - Check not applicable (dependencies missing)
# RC_INFO=40     - Informational output only
