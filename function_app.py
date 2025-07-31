import azure.functions as func
import logging
import time
import threading
import os
from datetime import datetime
import multiprocessing
import platform

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="http_trigger")
def http_trigger(req: func.HttpRequest) -> func.HttpResponse:
    start_time = datetime.now()
    thread_id = threading.current_thread().ident
    process_id = os.getpid()
    
    logging.info(f'Request started - Thread: {thread_id}, Process: {process_id}, Time: {start_time}')

    # Get delay parameter to simulate work
    delay = req.params.get('delay')
    if not delay:
        try:
            req_body = req.get_json()
            delay = req_body.get('delay') if req_body else None
        except:
            pass
    
    delay = float(delay) if delay else 2.0
    
    # Get request identifier
    request_id = req.params.get('id') or 'anonymous'
    
    logging.info(f'Request {request_id} sleeping for {delay} seconds...')
    time.sleep(delay)
    
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    
    response_data = {
        "request_id": request_id,
        "thread_id": thread_id,
        "process_id": process_id,
        "start_time": start_time.isoformat(),
        "end_time": end_time.isoformat(),
        "duration_seconds": duration,
        "delay_requested": delay
    }
    
    logging.info(f'Request {request_id} completed - Duration: {duration}s')
    
    # Get CPU information
    cpu_count = multiprocessing.cpu_count()
    
    # Try to get actual CPU info from /proc/cpuinfo on Linux
    cpu_info = ""
    try:
        if os.path.exists("/proc/cpuinfo"):
            with open("/proc/cpuinfo", "r") as f:
                cpuinfo = f.read()
                # Count physical cores
                physical_cores = len([line for line in cpuinfo.split('\n') if line.startswith('processor')])
                # Get CPU model
                for line in cpuinfo.split('\n'):
                    if 'model name' in line:
                        cpu_info = line.split(':')[1].strip()
                        break
                cpu_info = f"{cpu_info} ({physical_cores} cores detected)"
        else:
            cpu_info = f"{platform.processor()} ({cpu_count} cores)"
    except:
        cpu_info = f"{platform.processor()} ({cpu_count} cores)"
    
    # Get memory info
    memory_info = ""
    try:
        if os.path.exists("/proc/meminfo"):
            with open("/proc/meminfo", "r") as f:
                meminfo = f.read()
                for line in meminfo.split('\n'):
                    if line.startswith('MemTotal:'):
                        mem_kb = int(line.split()[1])
                        memory_info = f"{mem_kb / 1024 / 1024:.2f} GB"
                        break
    except:
        memory_info = "Unknown"
    
    return func.HttpResponse(
        f"Concurrency Test Result:\n{'-'*40}\n" +
        f"Request ID: {request_id}\n" +
        f"Thread ID: {thread_id}\n" +
        f"Process ID: {process_id}\n" +
        f"CPU Count: {cpu_count} vCPUs\n" +
        f"CPU Info: {cpu_info}\n" +
        f"Memory: {memory_info}\n" +
        f"Platform: {platform.system()} {platform.release()}\n" +
        f"Start: {start_time.strftime('%H:%M:%S.%f')[:-3]}\n" +
        f"End: {end_time.strftime('%H:%M:%S.%f')[:-3]}\n" +
        f"Duration: {duration:.3f}s\n" +
        f"Requested Delay: {delay}s\n",
        status_code=200
    )