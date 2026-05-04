#!/usr/bin/env python3
"""
SDOP-2025 Enhanced OWASP ZAP Scanner
Performs active DAST scanning with proper context and fail conditions

Usage:
  python3 zap-active-scan.py -t http://target:8080 -r zap-report.json
"""

import sys
import json
import time
import argparse
from datetime import datetime

def run_zap_scan(target_url, report_file, context_file=None, timeout=600):
    """
    Execute active ZAP scan with proper configuration
    
    Args:
        target_url: URL to scan (e.g., http://localhost:8080)
        report_file: Output report file (JSON format)
        context_file: ZAP context XML file (optional)
        timeout: Maximum scan time in seconds
    """
    
    import subprocess
    import os
    
    print("[*] SDOP-2025 OWASP ZAP Active Scan")
    print(f"[*] Target: {target_url}")
    print(f"[*] Report: {report_file}")
    print(f"[*] Timeout: {timeout}s")
    
    # Build ZAP command with active scanning parameters
    zap_cmd = [
        "zaproxy",
        "-cmd",
        "-silent",
        "-config", "api.disablekey=true",
        "-config", "scanner.delayInMs=0",
        "-config", "scanner.threadPerScan=2",
        "-config", "connection.timeoutInSecs=60",
        "-config", "connection.sslConnectTimeout=60",
    ]
    
    # Add context if provided
    if context_file and os.path.exists(context_file):
        zap_cmd.extend(["-configfile", context_file])
        print(f"[+] Using context: {context_file}")
    
    # Execute baseline scan first (for safety)
    baseline_args = [
        "-t", target_url,
        "-f", "json",
        "-r", report_file,
    ]
    
    print("\n[*] Phase 1: Running Baseline Scan...")
    baseline_cmd = ["zap-baseline.py"] + baseline_args
    
    try:
        result = subprocess.run(
            baseline_cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        
        if result.returncode not in [0, 1, 2]:  # ZAP returns 1 for warnings, 2 for errors
            print(f"[!] Baseline scan warning/error: {result.returncode}")
            print(f"[!] STDERR: {result.stderr}")
        else:
            print("[+] Baseline scan completed")
    
    except subprocess.TimeoutExpired:
        print(f"[!] Baseline scan timeout after {timeout}s")
        return False
    except Exception as e:
        print(f"[!] Baseline scan error: {e}")
        return False
    
    # Parse report and apply fail conditions (FR-11)
    print("\n[*] Phase 2: Analyzing Results (FR-11: HIGH/CRITICAL must fail)...")
    
    try:
        with open(report_file, 'r') as f:
            report = json.load(f)
    except Exception as e:
        print(f"[!] Failed to parse report: {e}")
        return False
    
    # Check findings
    critical_count = 0
    high_count = 0
    medium_count = 0
    low_count = 0
    
    if 'site' in report:
        for site in report['site']:
            if 'alerts' in site:
                for alert in site['alerts']:
                    risk = alert.get('riskcode', '')
                    
                    if risk == '3':  # CRITICAL
                        critical_count += 1
                    elif risk == '2':  # HIGH
                        high_count += 1
                    elif risk == '1':  # MEDIUM
                        medium_count += 1
                    elif risk == '0':  # LOW
                        low_count += 1
    
    # Print summary
    print(f"\n[+] Scan Summary:")
    print(f"    🔴 CRITICAL: {critical_count}")
    print(f"    🟠 HIGH:     {high_count}")
    print(f"    🟡 MEDIUM:   {medium_count}")
    print(f"    🟢 LOW:      {low_count}")
    
    total_high_or_above = critical_count + high_count
    
    # Apply FR-11: Block on HIGH or CRITICAL
    if total_high_or_above > 0:
        print(f"\n[!] FAIL: Found {total_high_or_above} HIGH/CRITICAL findings (FR-11)")
        print("[!] Pipeline will block due to security findings")
        return False
    else:
        print(f"\n[✓] PASS: No HIGH/CRITICAL findings detected")
        return True

def main():
    parser = argparse.ArgumentParser(
        description='SDOP-2025 OWASP ZAP Active Scanner'
    )
    parser.add_argument(
        '-t', '--target',
        required=True,
        help='Target URL to scan (e.g., http://localhost:8080)'
    )
    parser.add_argument(
        '-r', '--report',
        required=True,
        help='Output report file (JSON)'
    )
    parser.add_argument(
        '-c', '--context',
        help='ZAP context XML file'
    )
    parser.add_argument(
        '--timeout',
        type=int,
        default=600,
        help='Scan timeout in seconds (default: 600)'
    )
    
    args = parser.parse_args()
    
    success = run_zap_scan(
        target_url=args.target,
        report_file=args.report,
        context_file=args.context,
        timeout=args.timeout
    )
    
    # Exit code determines pipeline success/failure
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
