from fastapi import FastAPI

app = FastAPI(title="FastAPI on ECS Fargate (HTTPS)")

@app.get("/")
def read_root():
    return {"message": "Hello over HTTPS via ALB!"}

@app.get("/healthz")
def health():
    return {"status": "ok"}
