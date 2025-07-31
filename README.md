# Azure Functions Flex Consumption - Python Concurrency Demo

This project demonstrates how to configure and test concurrent HTTP request handling in Azure Functions Flex Consumption plan with Python.

## Key Findings

- **Default concurrency is 1** - A conservative default, not a Python limitation
- **Python supports multiple concurrent requests** - Successfully tested with 20+ concurrent requests
- **Instance specs** - Each instance has 4 vCPUs and 3.87GB RAM
- **Concurrency is achieved through multiple processes and threads**

## Project Structure

```
.
├── function_app.py          # Main function with concurrency demonstration
├── host.json               # Concurrency configuration (maxConcurrentRequests: 10)
├── requirements.txt        # Python dependencies
├── local.settings.json     # Local development settings
├── deploy.sh              # Deployment script for Azure
└── test_concurrency.sh    # Concurrency testing script
```

## Configuration

The concurrency settings are configured in `host.json`:

```json
{
  "extensions": {
    "http": {
      "routePrefix": "api",
      "maxConcurrentRequests": 10
    }
  },
  "concurrency": {
    "dynamicConcurrencyEnabled": true,
    "snapshotPersistenceEnabled": true
  }
}
```

## Deployment

1. Ensure you have Azure CLI and Azure Functions Core Tools installed
2. Login to Azure: `az login`
3. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

This will:
- Create a resource group in East Asia
- Create a storage account
- Create a Function App with Flex Consumption plan
- Deploy the function code

## Testing Concurrency

Use the provided test script to verify concurrent execution:

```bash
# Test with default settings (5 requests, 3 seconds each)
./test_concurrency.sh https://your-function.azurewebsites.net/api/http_trigger

# Test with 20 requests, 5 seconds delay each
./test_concurrency.sh https://your-function.azurewebsites.net/api/http_trigger 20 5
```

## Function Features

The HTTP trigger function (`http_trigger`) demonstrates concurrency by:
- Showing thread ID and process ID for each request
- Displaying CPU and memory information
- Supporting configurable delays to simulate work
- Returning detailed timing information

## Example Output

```bash
Testing concurrent execution with 20 parallel requests...
Each request will sleep for 5 seconds
If concurrency works, total time should be ~5 seconds, not 100 seconds

Sending requests...

=========================================
RESULTS SUMMARY
=========================================
Total execution time: 7 seconds

REQUEST DETAILS:

Request      Process  Thread       Start           End            
---------------------------------------------------------------
request-1    PID:55   139569...    14:34:53.542    14:34:58.542   
request-2    PID:54   133272...    14:34:52.689    14:34:57.689   
request-3    PID:55   132858...    14:34:53.344    14:34:58.344   
request-4    PID:55   131676...    14:34:53.570    14:34:58.570   
request-5    PID:54   126416...    14:34:53.664    14:34:58.664   
request-6    PID:54   132325...    14:34:53.533    14:34:58.533   
request-7    PID:56   129097...    14:34:53.527    14:34:58.528   
request-8    PID:54   128888...    14:34:53.555    14:34:58.555   
request-9    PID:55   129700...    14:34:53.422    14:34:58.422   
request-10   PID:56   125095...    14:34:53.566    14:34:58.566   
request-11   PID:54   132213...    14:34:53.697    14:34:58.698   
request-12   PID:55   137108...    14:34:53.609    14:34:58.609   
request-13   PID:57   130618...    14:34:53.538    14:34:58.538   
request-14   PID:54   134919...    14:34:53.688    14:34:58.688   
request-15   PID:55   134302...    14:34:53.472    14:34:58.472   
request-16   PID:54   125025...    14:34:53.462    14:34:58.463   
request-17   PID:54   125258...    14:34:53.640    14:34:58.640   
request-18   PID:54   132076...    14:34:53.499    14:34:58.499   
request-19   PID:55   124002...    14:34:53.465    14:34:58.466   
request-20   PID:55   127864...    14:34:53.672    14:34:58.672   

CONCURRENCY STATS:
-----------------
Unique processes:        4 (PIDs: 54 55 56 57 )

SYSTEM INFO:
-----------------
CPU Count: 4 vCPUs
CPU Info: Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz (4 cores detected)
Memory: 3.87 GB
Platform: Linux 5.15.164.1-1.cm2

✅ RESULT: Concurrency is working! 20 requests processed in parallel.
```

## Performance Recommendations

1. Start with `maxConcurrentRequests: 5-10` for most workloads
2. Monitor performance with Application Insights
3. Adjust based on:
   - Function complexity
   - Memory usage patterns
   - Downstream service limits
   - Response time requirements

## Notes

- Python's GIL is not a limiting factor - Azure Functions uses multiple processes
- Cold starts affect initial requests to new instances
- Flex Consumption plan automatically scales beyond configured limits when needed