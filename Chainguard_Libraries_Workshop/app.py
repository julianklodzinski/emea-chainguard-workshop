import aiohttp
from aiohttp import web


def create_app():
    app = web.Application()
    
    app.router.add_routes([
        web.static("/static", "static/", follow_symlinks=True)
    ])
    
    return app


if __name__ == "__main__":
    print(f"aiohttp version: {aiohttp.__version__}")
    app = create_app()
    web.run_app(app, host="0.0.0.0", port=8080)
