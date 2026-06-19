import os
import sys
import uvicorn
import webbrowser
from app.main import app

if __name__ == "__main__":
    port = 8765
    url = f"http://localhost:{port}"
    if not os.environ.get("NETVIZOR_NO_BROWSER"):
        import threading
        def open_browser():
            import time
            time.sleep(1.5)
            webbrowser.open(url)
        threading.Thread(target=open_browser, daemon=True).start()
        
    print(f"[+] NetVizör başlatılıyor: {url}")
    uvicorn.run(app, host="0.0.0.0", port=port)
