import json
import time
import random
import socketserver
from http.server import HTTPServer, BaseHTTPRequestHandler

# Python 3.6 compatible threading server (ThreadingHTTPServer requires 3.7+)
class ThreadingHTTPServer(socketserver.ThreadingMixIn, HTTPServer):
    daemon_threads = True

ENTITLEMENTS = json.dumps([
    {"entitlement_id": f"urn:wso2:entitlement:req-{random.randint(1000,9999)}-{i}",
     "resource": f"urn:trn:finance:reports:q{(i % 4) + 1}:region-{i % 10}",
     "action": "READ_WRITE" if i % 2 == 0 else "EXECUTE",
     "assigned_by": "system_admin_policy_engine",
     "attributes": {"clearance_level": "HIGH" if i % 3 == 0 else "STANDARD",
                     "department_id": f"DEPT-{100 + (i % 5)}"}}
    for i in range(200)
])

print(f"[Info] Entitlement payload size: {len(ENTITLEMENTS.encode()) / 1024:.2f} KB")


class Handler(BaseHTTPRequestHandler):

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        if length:
            self.rfile.read(length)

        if "/dummyCreate" in self.path:
            time.sleep(0.6)
            data = {"status": True, "id": f"usr-ext-{random.randint(100000, 999999)}"}

        elif "/dummyClaims" in self.path:
            time.sleep(0.8)
            data = {
                "status": True,
                "groups": "employee,internal_staff,regional_users",
                "organization": "ORG-GUID-9988776655",
                "entitlements": ENTITLEMENTS,
            }
        else:
            data = {"status": "unknown_route"}

        body = json.dumps(data).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        """Health check endpoint."""
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"status":"healthy"}')

    def log_message(self, fmt, *args):
        print(f"[{time.strftime('%H:%M:%S')}] {args[0]}")


if __name__ == "__main__":
    port = int(__import__("os").environ.get("DUMMY_PORT", "3500"))
    print(f"Dummy latency service on port {port}")
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
