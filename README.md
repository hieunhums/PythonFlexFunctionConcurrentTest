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

```
REQUEST DETAILS:

Request      Process  Thread       Start           End            
---------------------------------------------------------------
request-1    PID:55   130210...    14:29:06.169    14:29:11.170   
request-2    PID:54   125552...    14:29:06.052    14:29:11.052   
...

CONCURRENCY STATS:
-----------------
Unique processes: 5 (PIDs: 53 54 55 56 57)

SYSTEM INFO:
-----------------
CPU Count: 4 vCPUs
CPU Info: Intel(R) Xeon(R) Platinum 8370C CPU @ 2.80GHz (4 cores detected)
Memory: 3.87 GB
Platform: Linux 5.15.164.1-1.cm2
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