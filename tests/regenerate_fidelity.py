from fidelity_routes import route
from mechanics_routes import route as ground
from apparatus_routes import trapeze
for rank in range(4):
 for act in [1,2,3,6]:route(act,rank)
 ground(4,rank)
 trapeze(rank)
