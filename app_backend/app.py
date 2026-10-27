"""
Alias entry point allowing `uvicorn app:app` to work interchangeably with `uvicorn main:app`.
"""
from main import app

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
