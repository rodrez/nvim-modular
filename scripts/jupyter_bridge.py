#!/usr/bin/env python3
"""
Jupyter Bridge Script for Neovim Inline Output
Connects to a Jupyter kernel and executes code, returning formatted output.
"""

import sys
import json
import argparse
import tempfile
import base64
import os
import time
from pathlib import Path
from typing import Dict, Any, List, Optional

try:
    from jupyter_client import KernelManager, find_connection_file
    from jupyter_client.manager import start_new_kernel
    import zmq
except ImportError:
    print("ERROR: jupyter_client not installed. Run: pip install jupyter_client", file=sys.stderr)
    sys.exit(1)


class JupyterBridge:
    def __init__(self, connection_file: Optional[str] = None):
        self.km = None
        self.kc = None
        self.connection_file = connection_file
        
    def connect_to_kernel(self) -> bool:
        """Connect to existing kernel or start a new one."""
        try:
            if self.connection_file and os.path.exists(self.connection_file):
                # Connect to existing kernel
                self.km = KernelManager(connection_file=self.connection_file)
                self.kc = self.km.client()
            else:
                # Start new kernel
                self.km, self.kc = start_new_kernel(kernel_name='python3')
            
            # Wait for kernel to be ready
            self.kc.wait_for_ready(timeout=10)
            return True
            
        except Exception as e:
            print(f"ERROR: Failed to connect to kernel: {e}", file=sys.stderr)
            return False
    
    def execute_code_streaming(self, code: str, timeout: int = 30):
        """Execute code with real-time streaming output."""
        if not self.kc:
            print("ERROR: No kernel connection", file=sys.stderr)
            return
        
        try:
            # Execute the code
            msg_id = self.kc.execute(code, silent=False, store_history=True)
            
            # Stream output in real-time
            start_time = time.time()
            while True:
                if time.time() - start_time > timeout:
                    print("ERROR: Execution timeout", file=sys.stderr)
                    return
                
                try:
                    msg = self.kc.get_iopub_msg(timeout=1)
                    
                    # Check if message is valid and belongs to our execution
                    if not msg or 'parent_header' not in msg or 'msg_type' not in msg:
                        continue
                        
                    if msg['parent_header'].get('msg_id') == msg_id:
                        msg_type = msg['msg_type']
                        content = msg['content']
                        
                        if msg_type == 'stream':
                            # stdout/stderr output - stream immediately
                            stream_name = content.get('name', 'stdout')
                            text = content.get('text', '')
                            if stream_name == 'stderr':
                                print(f"ERROR: {text.strip()}", file=sys.stderr, flush=True)
                            else:
                                # Print each line immediately
                                for line in text.strip().split('\n'):
                                    if line:
                                        print(line, flush=True)
                                
                        elif msg_type == 'execute_result':
                            # Return value
                            data = content.get('data', {})
                            if 'text/plain' in data:
                                result_text = data['text/plain'].strip()
                                if result_text and result_text != 'None':
                                    print(result_text, flush=True)
                            
                            # Check for plots
                            if 'image/png' in data:
                                plot_path = self._save_plot(data['image/png'])
                                if plot_path:
                                    print(f"OUTPUT-PLOT: {plot_path}", flush=True)
                                    
                        elif msg_type == 'display_data':
                            # Display output (like plots)
                            data = content.get('data', {})
                            if 'image/png' in data:
                                plot_path = self._save_plot(data['image/png'])
                                if plot_path:
                                    print(f"OUTPUT-PLOT: {plot_path}", flush=True)
                            elif 'text/plain' in data:
                                display_text = data['text/plain'].strip()
                                if display_text:
                                    print(display_text, flush=True)
                                
                        elif msg_type == 'error':
                            # Execution error
                            error_msg = '\n'.join(content.get('traceback', []))
                            print(f"ERROR: {error_msg}", file=sys.stderr, flush=True)
                            
                        elif msg_type == 'status' and content.get('execution_state') == 'idle':
                            # Execution finished
                            break
                            
                except zmq.Again:
                    # No message available, continue waiting
                    continue
                except Exception as e:
                    # Log the error but don't stop execution
                    print(f"WARNING: Message handling error: {e}", file=sys.stderr, flush=True)
                    continue
            
        except Exception as e:
            print(f"ERROR: Execution error: {e}", file=sys.stderr, flush=True)

    def execute_code(self, code: str, timeout: int = 30) -> Dict[str, Any]:
        """Execute code and return formatted output (legacy method)."""
        if not self.kc:
            return {"error": "No kernel connection"}
        
        try:
            # Execute the code
            msg_id = self.kc.execute(code, silent=False, store_history=True)
            
            # Collect all output messages
            outputs = []
            plots = []
            errors = []
            
            # Wait for execution to complete
            start_time = time.time()
            while True:
                if time.time() - start_time > timeout:
                    return {"error": "Execution timeout"}
                
                try:
                    msg = self.kc.get_iopub_msg(timeout=1)
                    
                    if msg['parent_header'].get('msg_id') == msg_id:
                        msg_type = msg['msg_type']
                        content = msg['content']
                        
                        if msg_type == 'stream':
                            # stdout/stderr output
                            stream_name = content.get('name', 'stdout')
                            text = content.get('text', '')
                            if stream_name == 'stderr':
                                errors.append(text)
                            else:
                                outputs.append(text)
                                
                        elif msg_type == 'execute_result':
                            # Return value
                            data = content.get('data', {})
                            if 'text/plain' in data:
                                outputs.append(data['text/plain'])
                            
                            # Check for plots
                            if 'image/png' in data:
                                plot_path = self._save_plot(data['image/png'])
                                if plot_path:
                                    plots.append(plot_path)
                                    
                        elif msg_type == 'display_data':
                            # Display output (like plots)
                            data = content.get('data', {})
                            if 'image/png' in data:
                                plot_path = self._save_plot(data['image/png'])
                                if plot_path:
                                    plots.append(plot_path)
                            elif 'text/plain' in data:
                                outputs.append(data['text/plain'])
                                
                        elif msg_type == 'error':
                            # Execution error
                            error_msg = '\n'.join(content.get('traceback', []))
                            errors.append(error_msg)
                            
                        elif msg_type == 'status' and content.get('execution_state') == 'idle':
                            # Execution finished
                            break
                            
                except zmq.Again:
                    # No message available, continue waiting
                    continue
                except Exception as e:
                    return {"error": f"Message handling error: {e}"}
            
            return {
                "outputs": outputs,
                "plots": plots,
                "errors": errors
            }
            
        except Exception as e:
            return {"error": f"Execution error: {e}"}
    
    def _save_plot(self, base64_data: str) -> Optional[str]:
        """Save base64 plot data to temporary file."""
        try:
            # Decode base64 data
            plot_data = base64.b64decode(base64_data)
            
            # Create temporary file
            temp_dir = Path(tempfile.gettempdir()) / "nvim_jupyter_plots"
            temp_dir.mkdir(exist_ok=True)
            
            # Generate unique filename
            timestamp = int(time.time() * 1000)
            plot_path = temp_dir / f"plot_{timestamp}.png"
            
            # Save plot
            with open(plot_path, 'wb') as f:
                f.write(plot_data)
            
            return str(plot_path)
            
        except Exception as e:
            print(f"ERROR: Failed to save plot: {e}", file=sys.stderr)
            return None
    
    def close(self):
        """Clean up connections."""
        if self.kc:
            self.kc.stop_channels()
        if self.km:
            self.km.shutdown_kernel()


def format_output(result: Dict[str, Any]) -> str:
    """Format execution result for Neovim consumption."""
    lines = []
    
    # Add errors first
    if result.get("errors"):
        for error in result["errors"]:
            for line in error.strip().split('\n'):
                if line.strip():
                    lines.append(f"# ERROR: {line}")
    
    # Add regular output
    if result.get("outputs"):
        for output in result["outputs"]:
            for line in str(output).strip().split('\n'):
                if line.strip():
                    lines.append(f"# {line}")
    
    # Add plot references
    if result.get("plots"):
        for plot_path in result["plots"]:
            lines.append(f"# OUTPUT-PLOT: {plot_path}")
    
    # Handle execution errors
    if result.get("error"):
        lines.append(f"# ERROR: {result['error']}")
    
    return '\n'.join(lines) if lines else "# (no output)"


def main():
    parser = argparse.ArgumentParser(description="Jupyter Bridge for Neovim")
    parser.add_argument("--connection-file", "-f", help="Jupyter kernel connection file")
    parser.add_argument("--timeout", "-t", type=int, default=30, help="Execution timeout in seconds")
    parser.add_argument("--stream", "-s", action="store_true", help="Enable real-time streaming output")
    parser.add_argument("code", help="Python code to execute")
    
    args = parser.parse_args()
    
    # Create bridge and connect
    bridge = JupyterBridge(args.connection_file)
    
    if not bridge.connect_to_kernel():
        sys.exit(1)
    
    try:
        if args.stream:
            # Use streaming execution
            bridge.execute_code_streaming(args.code, args.timeout)
        else:
            # Execute code with buffered output
            result = bridge.execute_code(args.code, args.timeout)
            
            # Format and print output
            formatted_output = format_output(result)
            print(formatted_output)
        
    finally:
        bridge.close()


if __name__ == "__main__":
    main()