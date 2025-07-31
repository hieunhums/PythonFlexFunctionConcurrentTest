#!/bin/bash

# Test concurrent execution of Azure Function
FUNCTION_URL=$1
NUM_REQUESTS=${2:-5}  # Default to 5 if not specified
DELAY=${3:-3}         # Default to 3 seconds if not specified

if [ -z "$FUNCTION_URL" ]; then
    echo "Usage: ./test_concurrency.sh <function_url> [num_requests] [delay_seconds]"
    echo "Example: ./test_concurrency.sh https://myfunction.azurewebsites.net/api/http_trigger 10 2"
    echo ""
    echo "Arguments:"
    echo "  function_url  - Required: The Azure Function HTTP trigger URL"
    echo "  num_requests  - Optional: Number of parallel requests (default: 5)"
    echo "  delay_seconds - Optional: Delay per request in seconds (default: 3)"
    exit 1
fi

echo "Testing concurrent execution with $NUM_REQUESTS parallel requests..."
echo "Each request will sleep for $DELAY seconds"
EXPECTED_TIME=$((NUM_REQUESTS * DELAY))
echo "If concurrency works, total time should be ~$DELAY seconds, not $EXPECTED_TIME seconds"
echo ""

# Create temp directory for output files
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Start time
START_TIME=$(date +%s)

# Send concurrent requests and save to files
echo "Sending requests..."
for i in $(seq 1 $NUM_REQUESTS); do
    curl -s "$FUNCTION_URL?id=request-$i&delay=$DELAY" > "$TEMP_DIR/response-$i.txt" &
done

# Wait for all background jobs to complete
wait

# End time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "========================================="
echo "RESULTS SUMMARY"
echo "========================================="
echo "Total execution time: ${DURATION} seconds"
echo ""

# Display results in order
echo "REQUEST DETAILS:"
echo ""
printf "%-12s %-8s %-12s %-15s %-15s\n" "Request" "Process" "Thread" "Start" "End"
echo "---------------------------------------------------------------"

for i in $(seq 1 $NUM_REQUESTS); do
    if [ -f "$TEMP_DIR/response-$i.txt" ]; then
        REQUEST_ID=$(grep "Request ID:" "$TEMP_DIR/response-$i.txt" | cut -d: -f2 | xargs)
        PROCESS_ID=$(grep "Process ID:" "$TEMP_DIR/response-$i.txt" | cut -d: -f2 | xargs)
        THREAD_ID=$(grep "Thread ID:" "$TEMP_DIR/response-$i.txt" | cut -d: -f2 | xargs)
        START_TIME_STR=$(grep "Start:" "$TEMP_DIR/response-$i.txt" | cut -d' ' -f2)
        END_TIME_STR=$(grep "End:" "$TEMP_DIR/response-$i.txt" | cut -d' ' -f2)
        
        # Format thread ID to show first 6 digits only
        SHORT_THREAD="${THREAD_ID:0:6}"
        
        printf "%-12s %-8s %-12s %-15s %-15s\n" "$REQUEST_ID" "PID:$PROCESS_ID" "$SHORT_THREAD..." "$START_TIME_STR" "$END_TIME_STR"
    fi
done

# Count unique processes
echo ""
echo "CONCURRENCY STATS:"
echo "-----------------"
UNIQUE_PIDS=$(for i in $(seq 1 $NUM_REQUESTS); do
    if [ -f "$TEMP_DIR/response-$i.txt" ]; then
        grep "Process ID:" "$TEMP_DIR/response-$i.txt" | cut -d: -f2 | xargs
    fi
done | sort -u)

echo "Unique processes: $(echo "$UNIQUE_PIDS" | wc -l) (PIDs: $(echo $UNIQUE_PIDS | tr '\n' ' '))"

# Get system info from first response
if [ -f "$TEMP_DIR/response-1.txt" ]; then
    echo ""
    echo "SYSTEM INFO:"
    echo "-----------------"
    CPU_COUNT=$(grep "CPU Count:" "$TEMP_DIR/response-1.txt" | cut -d: -f2- | xargs)
    CPU_INFO=$(grep "CPU Info:" "$TEMP_DIR/response-1.txt" | cut -d: -f2- | xargs)
    MEMORY=$(grep "Memory:" "$TEMP_DIR/response-1.txt" | cut -d: -f2- | xargs)
    PLATFORM=$(grep "Platform:" "$TEMP_DIR/response-1.txt" | cut -d: -f2- | xargs)
    
    echo "CPU Count: $CPU_COUNT"
    echo "CPU Info: $CPU_INFO"
    echo "Memory: $MEMORY"
    echo "Platform: $PLATFORM"
fi

# Calculate threshold (allow some overhead)
THRESHOLD=$((DELAY * 2))

echo ""
if [ $DURATION -lt $THRESHOLD ]; then
    echo "✅ RESULT: Concurrency is working! $NUM_REQUESTS requests processed in parallel."
else
    echo "❌ RESULT: Requests may be processed sequentially."
    echo "   Expected: ~$DELAY seconds, Actual: $DURATION seconds"
fi
echo "========================================="