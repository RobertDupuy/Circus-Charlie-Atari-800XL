"""Water route search and replay use the assembled native game."""
from fidelity_routes import route as find_route
def route(rank=0,water=True):
 return find_route(6 if water else 2,rank)
if __name__=="__main__":route()
