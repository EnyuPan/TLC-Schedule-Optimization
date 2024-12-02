import cvxpy

xdim = 20
ydim = 2

x = cvxpy.Variable((xdim, ydim), boolean=True)

obj = cvxpy.Maximize(x[0,0] + 2 * x[1,0] - x[6,0] + x[13,0])

constr = []

# for i in range(xdim):
#     constr.append(x[i] <= 6)

# constr.append(x[0] + x[1] + x[13] <= 2)
constr.append(cvxpy.sum(x[:,:]) <= 2)

# print(constr)

prob = cvxpy.Problem(obj, constr)
prob.solve()
print(prob.status)
print(prob.value)
print(x.value)
