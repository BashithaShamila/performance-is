#!/bin/bash -e
# ============================================================
# Run Adaptive Scripting Tests Against Local WSO2 IS Instance
# ============================================================
# Usage:
#   ./run-local-tests.sh                                    # Run default scenario
#   ./run-local-tests.sh scenarios/MyScript.jmx             # Run specific scenario
#   ./run-local-tests.sh --tag default scenarios/X.jmx      # Tag results for A/B comparison
#   ./run-local-tests.sh --setup-only                       # Only run setup (create test user)
#   ./run-local-tests.sh --skip-setup scenarios/X.jmx       # Skip setup, run scenario
#
# A/B Comparison Workflow:
#   1. Start default IS pack
#   2. ./run-local-tests.sh --tag default --skip-setup scenarios/X.jmx
#   3. Start updated IS pack
#   4. ./run-local-tests.sh --tag updated --skip-setup scenarios/X.jmx
#   5. ./compare-results.sh results/default_* results/updated_*

SCRIPT_DIR=$(dirname "$0")
CONFIG_FILE="$SCRIPT_DIR/config.properties"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ---- Argument parsing ----
SETUP_ONLY=false
SKIP_SETUP=false
SCENARIO_JMX=""
TAG=""
JMETER_EXTRA_ARGS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --setup-only)   SETUP_ONLY=true; shift ;;
        --skip-setup)   SKIP_SETUP=true; shift ;;
        --tag)          TAG="$2"; shift 2 ;;
        -J*)            JMETER_EXTRA_ARGS="$JMETER_EXTRA_ARGS $1"; shift ;;
        *.jmx)          SCENARIO_JMX="$1"; shift ;;
        *)              echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# Read tag from config if not passed via CLI
if [ -z "$TAG" ]; then
    TAG=$(grep -E "^tag=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 | tr -d ' ')
fi

# Build results directory name
if [ -n "$TAG" ]; then
    RESULTS_DIR="$SCRIPT_DIR/results/${TAG}_${TIMESTAMP}"
else
    RESULTS_DIR="$SCRIPT_DIR/results/$TIMESTAMP"
fi

# Default scenario if none specified
if [ -z "$SCENARIO_JMX" ] && [ "$SETUP_ONLY" = false ]; then
    SCENARIO_JMX="$SCRIPT_DIR/scenarios/Adaptive_Script_Login_Flow.jmx"
fi

# ---- Validate config ----
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: config.properties not found at $CONFIG_FILE"
    exit 1
fi

# ---- Validate TOTP CSV prerequisite ----
if [ -n "$SCENARIO_JMX" ] && echo "$SCENARIO_JMX" | grep -qi "TOTP"; then
    TOTP_CSV="$SCRIPT_DIR/testdata/totp_users.csv"
    if [ ! -f "$TOTP_CSV" ]; then
        echo "ERROR: TOTP scenario requires testdata/totp_users.csv"
        echo "  Run first: ./setup/setup_totp_users.sh"
        echo "  This creates test users and enrolls them in TOTP."
        exit 1
    fi
fi

# Read isHome from config for SSL truststore
IS_HOME=$(grep -E "^isHome=" "$CONFIG_FILE" | cut -d= -f2- | tr -d ' ')

# ---- Find JMeter ----
if command -v jmeter &>/dev/null; then
    JMETER="jmeter"
    echo "JMeter: $(jmeter --version 2>&1 | grep -E 'JMETER [0-9]|[0-9]+\.[0-9]+\.[0-9]+' | tail -1 | tr -d ' ')"
else
    JMETER_HOME=""
    for pattern in "$HOME"/apache-jmeter-* "$HOME"/tools/apache-jmeter-* \
                   "/usr/local/apache-jmeter" "/opt/apache-jmeter"; do
        [ -d "$pattern" ] && JMETER_HOME="$pattern" && break
    done
    if [ -z "$JMETER_HOME" ]; then
        echo "ERROR: Could not find JMeter installation."
        echo "  Please install Apache JMeter or ensure 'jmeter' is on your PATH."
        exit 1
    fi
    JMETER="$JMETER_HOME/bin/jmeter"
    echo "JMeter: $JMETER_HOME"
fi

# ---- SSL / TLS trust configuration ----
SSL_OPTS=""
WSO2_TRUSTSTORE="$IS_HOME/repository/resources/security/wso2carbon.jks"
if [ -n "$IS_HOME" ] && [ -f "$WSO2_TRUSTSTORE" ]; then
    echo "Using IS truststore: $WSO2_TRUSTSTORE"
    SSL_OPTS="-Djavax.net.ssl.trustStore=$WSO2_TRUSTSTORE"
    SSL_OPTS="$SSL_OPTS -Djavax.net.ssl.trustStorePassword=wso2carbon"
    SSL_OPTS="$SSL_OPTS -Djavax.net.ssl.trustStoreType=JKS"
else
    echo "WARNING: IS truststore not found. SSL cert validation may fail."
    echo "  Set isHome in config.properties to: /path/to/wso2is-X.X.X"
fi

# ---- Create results directory ----
mkdir -p "$RESULTS_DIR"
echo "Results directory: $RESULTS_DIR"
[ -n "$TAG" ] && echo "Tag: $TAG"

# ---- Common JMeter args ----
JMETER_OPTS="$SSL_OPTS"
JMETER_OPTS="$JMETER_OPTS -Dhttps.protocols=TLSv1.2"

run_jmeter() {
    local label="$1"
    local jmx="$2"
    local jtl_file="$RESULTS_DIR/${label}.jtl"
    local log_file="$RESULTS_DIR/${label}.log"

    echo ""
    echo "======================================================================"
    echo "  $label"
    echo "  JMX: $jmx"
    echo "======================================================================"

    $JMETER -n \
        $JMETER_OPTS \
        -t "$jmx" \
        -q "$CONFIG_FILE" \
        $JMETER_EXTRA_ARGS \
        -l "$jtl_file" \
        -j "$log_file"

    echo "  Results: $jtl_file"
}

# ---- Step 1: Setup (create test user) ----
if [ "$SKIP_SETUP" = false ]; then
    run_jmeter "setup_create_test_user" \
        "$SCRIPT_DIR/setup/TestData_Create_Test_User.jmx"
fi

# ---- Step 2: Run scenario ----
if [ "$SETUP_ONLY" = false ]; then
    if [ ! -f "$SCENARIO_JMX" ]; then
        echo "ERROR: Scenario JMX not found: $SCENARIO_JMX"
        exit 1
    fi

    SCENARIO_LABEL=$(basename "$SCENARIO_JMX" .jmx)
    run_jmeter "$SCENARIO_LABEL" "$SCENARIO_JMX"

    # Generate HTML report
    HTML_REPORT="$RESULTS_DIR/html-report"
    echo ""
    echo "Generating HTML report..."
    $JMETER $JMETER_OPTS -g "$RESULTS_DIR/${SCENARIO_LABEL}.jtl" \
        -o "$HTML_REPORT" \
        -j "$RESULTS_DIR/report-gen.log" 2>/dev/null || echo "  (HTML report generation failed — check report-gen.log)"

    echo ""
    echo "======================================================================"
    echo "  Test Complete"
    echo "  HTML report: $HTML_REPORT/index.html"
    echo "  Raw results: $RESULTS_DIR/${SCENARIO_LABEL}.jtl"
    if [ -n "$TAG" ]; then
        echo ""
        echo "  To compare with another run:"
        echo "    ./compare-results.sh $RESULTS_DIR <other-results-dir>"
    fi
    echo "======================================================================"
fi
