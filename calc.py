import sympy as sp 
import matplotlib.pyplot as plt 
x = sp.symbols('x') 
f = sin(x) 
fprime = sp.diff(f, x) 
fint = sp.integrate(f, x) 
sp.plot(f, (x,-5,5), show=True) 
sp.plot(fprime, (x,-5,5), show=True) 
sp.plot(fint, (x,-5,5), show=True) 
